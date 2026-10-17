import '../../../core/utils/either.dart';
import '../../../core/utils/responsive_builder.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../core/utils/thousands_format.dart';
import '../../../domain/entities/tournament/tournament.dart';
import '../../../domain/repositories/tournament_repository.dart';
import '../club_config/widgets/duration_minutes_field.dart';
import '../club_config/widgets/price_field.dart';
import '../club_config/widgets/time_field.dart';
import 'widgets/tournament_ui.dart';

/// Alta y edición de un torneo. Con [tournamentId] edita.
///
/// Es una página y no un diálogo (excepción a la regla de CLAUDE.md, ya
/// confirmada en el diseño): son muchas decisiones y el resumen de la derecha
/// se recalcula con cada una.
class TournamentFormPage extends StatefulWidget {
  const TournamentFormPage({super.key, this.tournamentId});

  final int? tournamentId;

  @override
  State<TournamentFormPage> createState() => _TournamentFormPageState();
}

class _TournamentFormPageState extends State<TournamentFormPage> {
  final _repository = sl<TournamentRepository>();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _prizes = TextEditingController();
  final _minTeams = TextEditingController(text: '8');
  final _maxTeams = TextEditingController(text: '16');
  final _sumMin = TextEditingController(text: '13');
  final _fee = TextEditingController();
  final _duration = TextEditingController(text: '90');
  final _closesTime = TextEditingController(text: '23:59');

  List<CatalogSport>? _catalog;
  Tournament? _editing;
  String? _error;
  bool _saving = false;
  bool _charge = false;
  TournamentDraft _draft = TournamentDraft();

  bool get _isEdit => widget.tournamentId != null;

  /// Con equipos anotados el backend no deja cambiar deporte, modalidad, categoría ni entrada.
  bool get _lockedByEntries => _editing != null && (_editing!.teamsCount + _editing!.waitlistCount) > 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _prizes, _minTeams, _maxTeams, _sumMin, _fee, _duration, _closesTime]) {
      c.dispose();
    }
    super.dispose();
  }

  CatalogSport? get _sport => _catalog?.where((s) => s.clubTypeId == _draft.clubTypeId).firstOrNull;
  TeamFormat? get _format => _sport?.formats.where((f) => f.id == _draft.teamFormatId).firstOrNull;

  Future<void> _load() async {
    setState(() => _error = null);
    final catalog = await _repository.getCatalog();
    if (!mounted) return;
    await catalog.when(
      left: (failure) async => setState(() => _error = failure.message),
      right: (sports) async {
        _catalog = sports;
        if (_isEdit) {
          final result = await _repository.getTournament(widget.tournamentId!);
          if (!mounted) return;
          result.when(
            left: (failure) => setState(() => _error = failure.message),
            right: (t) => setState(() => _fill(t)),
          );
        } else {
          setState(() => _pickSport(sports.firstOrNull));
        }
      },
    );
  }

  void _fill(Tournament t) {
    _editing = t;
    _draft = TournamentDraft.from(t);
    _name.text = t.name;
    _description.text = t.description ?? '';
    _prizes.text = t.prizes ?? '';
    _minTeams.text = '${t.minTeams}';
    _maxTeams.text = '${t.maxTeams}';
    _sumMin.text = '${t.sumMin ?? 13}';
    _charge = t.hasFee;
    _fee.text = t.hasFee ? ThousandsFormat.formatPrice(t.entryFee!) : '';
    _duration.text = '${t.matchDurationMinutes}';
    final closes = t.registrationClosesAt;
    _closesTime.text = closes == null ? '23:59' : hhmm(closes);
  }

  void _pickSport(CatalogSport? sport) {
    if (sport == null) return;
    _draft
      ..clubTypeId = sport.clubTypeId
      ..teamFormatId = sport.formats.firstOrNull?.id
      ..categoryId = sport.categories.length > 5 ? sport.categories[5].id : sport.categories.firstOrNull?.id
      ..scoreMode = sport.defaultScoreMode
      ..courtIds = sport.courts.map((c) => c.id).toSet();
    if (sport.categories.isEmpty) _draft.admission = TournamentAdmission.open;
  }

  // -------------------------------------------------------------------------

  Future<void> _save({bool publish = false}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _draft
      ..name = _name.text.trim()
      ..description = _description.text.trim().isEmpty ? null : _description.text.trim()
      ..prizes = _prizes.text.trim().isEmpty ? null : _prizes.text.trim()
      ..minTeams = int.parse(_minTeams.text)
      ..maxTeams = int.parse(_maxTeams.text)
      ..sumMin = int.tryParse(_sumMin.text) ?? 13
      ..entryFee = _charge ? ThousandsFormat.parsePrice(_fee.text) : null
      ..matchDurationMinutes = int.tryParse(_duration.text) ?? 90;
    final closes = _draft.registrationClosesAt;
    if (closes != null) {
      final parts = _closesTime.text.split(':');
      _draft.registrationClosesAt = DateTime(closes.year, closes.month, closes.day, int.tryParse(parts.first) ?? 23, int.tryParse(parts.last) ?? 59);
    }

    setState(() => _saving = true);
    final result = _isEdit
        ? await _repository.updateTournament(widget.tournamentId!, _draft)
        : await _repository.createTournament(_draft);
    if (!mounted) return;
    await result.when(
      left: (failure) async {
        setState(() => _saving = false);
        SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
      },
      right: (t) async {
        if (publish) {
          final published = await _repository.changeStatus(t.id, TournamentStatus.open);
          if (!mounted) return;
          published.when(left: (failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message), right: (_) {});
        }
        if (!mounted) return;
        if (_isEdit) {
          context.pop();
        } else {
          context.pushReplacementNamed(AppRoutes.TOURNAMENT_DETAIL_ROUTE.name, pathParameters: {'tournamentId': '${t.id}'});
        }
      },
    );
  }

  Future<void> _pickDate(DateTime? current, ValueChanged<DateTime?> onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final catalog = _catalog;

    Widget body;
    if (_error != null) {
      body = LoadError(message: _error!, onRetry: _load);
    } else if (catalog == null || (_isEdit && _editing == null)) {
      body = const Center(child: CircularProgressIndicator());
    } else if (catalog.isEmpty) {
      body = const Center(child: Text('El club no tiene canchas activas para armar un torneo.'));
    } else {
      body = Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 1100;
            final form = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _generalSection(catalog),
                const SizedBox(height: 16),
                _categorySection(),
                const SizedBox(height: 16),
                _formatSection(),
                const SizedBox(height: 16),
                _matchesSection(),
                const SizedBox(height: 16),
                _registrationSection(),
                const SizedBox(height: 16),
                _resultsSection(),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Premios',
                  subtitle: 'Texto libre: se muestra tal cual en la app.',
                  child: TextFormField(
                    controller: _prizes,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Ej.: 1° Paletas + trofeo · 2° Voucher de 4 turnos'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: form),
                        const SizedBox(width: 24),
                        SizedBox(width: 320, child: _summary()),
                      ],
                    )
                  : Column(children: [_summary(), const SizedBox(height: 16), form]),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      appBar: ResponsiveBuilder.isMobile(context) ? _mobileAppBar() : AppBar(
        title: Text(_isEdit ? 'Editar torneo' : 'Nuevo torneo'),
        actions: [
          TextButton(onPressed: _saving ? null : () => context.pop(), child: const Text('Cancelar')),
          const SizedBox(width: 8),
          if (!_isEdit) ...[
            OutlinedButton(onPressed: _saving ? null : () => _save(), child: const Text('Guardar borrador')),
            const SizedBox(width: 8),
            FilledButton(onPressed: _saving ? null : () => _save(publish: true), child: const Text('Publicar y abrir inscripción')),
          ] else
            FilledButton(onPressed: _saving ? null : () => _save(), child: const Text('Guardar cambios')),
          const SizedBox(width: 16),
        ],
      ),
      body: body,
    );
  }

  /// Celular (formulario de nivel 3): ✕ para cerrar, la acción principal a
  /// la derecha y "Guardar borrador" en el menú.
  AppBar _mobileAppBar() => AppBar(
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close),
          onPressed: _saving ? null : () => context.pop(),
        ),
        titleSpacing: 0,
        title: Text(_isEdit ? 'Editar torneo' : 'Nuevo torneo'),
        actions: [
          if (!_isEdit) ...[
            FilledButton(onPressed: _saving ? null : () => _save(publish: true), child: const Text('Publicar')),
            PopupMenuButton<String>(
              tooltip: 'Más opciones',
              enabled: !_saving,
              onSelected: (_) => _save(),
              itemBuilder: (_) => const [PopupMenuItem(value: 'draft', child: Text('Guardar borrador'))],
            ),
          ] else ...[
            FilledButton(onPressed: _saving ? null : () => _save(), child: const Text('Guardar')),
            const SizedBox(width: 12),
          ],
        ],
      );

  // -- Secciones ---------------------------------------------------------------

  Widget _generalSection(List<CatalogSport> catalog) {
    final sport = _sport;
    return SectionCard(
      title: 'Datos generales',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre del torneo'),
            onChanged: (_) => setState(() {}),
            validator: (v) => (v ?? '').trim().length < 3 ? 'Poné un nombre de al menos 3 letras' : null,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<int>(
                  initialValue: _draft.clubTypeId,
                  decoration: const InputDecoration(labelText: 'Deporte'),
                  items: [for (final s in catalog) DropdownMenuItem(value: s.clubTypeId, child: Text(s.name))],
                  onChanged: _lockedByEntries ? null : (v) => setState(() => _pickSport(catalog.firstWhere((s) => s.clubTypeId == v))),
                ),
              ),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<int>(
                  key: ValueKey('format-${_draft.clubTypeId}'),
                  initialValue: _draft.teamFormatId,
                  decoration: InputDecoration(labelText: 'Modalidad', helperText: _format?.description),
                  items: [for (final f in sport?.formats ?? const <TeamFormat>[]) DropdownMenuItem(value: f.id, child: Text(f.name))],
                  validator: (v) => v == null ? 'Elegí la modalidad' : null,
                  onChanged: _lockedByEntries ? null : (v) => setState(() => _draft.teamFormatId = v),
                ),
              ),
              _dateButton('Empieza', _draft.startsAt, (d) => _draft.startsAt = d),
              _dateButton('Termina', _draft.endsAt, (d) => _draft.endsAt = d),
            ],
          ),
          const SizedBox(height: 12),
          if (sport != null && sport.formats.isEmpty)
            const InfoBanner(text: 'Este deporte no tiene modalidades cargadas en el catálogo.', error: true),
          if (_format != null)
            InfoBanner(
              text: 'Los jugadores por equipo vienen de la modalidad (catálogo global del deporte): '
                  'el capitán inscribe ${_format!.playersPerTeam} jugadores${_format!.maxSubstitutes > 0 ? ' y hasta ${_format!.maxSubstitutes} suplentes' : ''}.',
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
          ),
        ],
      ),
    );
  }

  Widget _dateButton(String label, DateTime? value, void Function(DateTime?) set) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: () => _pickDate(value, set),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: value == null ? const Icon(Icons.event_outlined) : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => set(null))),
          ),
          child: Text(value == null ? 'Sin fecha' : numericDate(value)),
        ),
      ),
    );
  }

  Widget _categorySection() {
    final sport = _sport;
    final categories = sport?.categories ?? const <SportCategory>[];
    final players = _format?.playersPerTeam ?? 2;
    final current = categories.where((c) => c.id == _draft.categoryId).firstOrNull;
    final maxLower = categories.isEmpty || current == null ? 0 : categories.last.level - current.level;

    String hint() {
      switch (_draft.admission) {
        case TournamentAdmission.single:
          if (current == null) return 'Elegí la categoría.';
          final lower = _draft.lowerCategoriesAllowed;
          final admitted = categories.where((c) => c.level >= current.level && (lower == null || c.level <= current.level + lower)).map((c) => c.name).toList();
          final higher = categories.where((c) => c.level < current.level).map((c) => c.name).lastOrNull;
          return 'Entran ${admitted.join(', ')}${higher != null ? '; un $higher no entra' : ''}. '
              '${sport!.categorizes ? 'Cuenta la categoría que les dio el club; si no tienen, la personal.' : 'Cuenta la categoría personal de cada jugador.'}';
        case TournamentAdmission.sum:
          return 'La suma de los niveles de la pareja tiene que llegar al mínimo. Ej.: 6ta + 7ma = 13.';
        case TournamentAdmission.open:
          return 'Cualquier jugador. Los puntos van al ranking "Libre".';
      }
    }

    return SectionCard(
      title: 'Categoría',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChoiceRow<TournamentAdmission>(
            value: _draft.admission,
            enabled: !_lockedByEntries,
            options: [
              if (categories.isNotEmpty) (TournamentAdmission.single, 'Categoría única', 'Esa categoría y las más bajas que elijas.'),
              if (categories.isNotEmpty && players >= 2) (TournamentAdmission.sum, 'Suma', 'La suma de la pareja tiene que llegar a un mínimo.'),
              (TournamentAdmission.open, 'Libre', 'Sin restricción de categoría.'),
            ],
            onChanged: (v) => setState(() => _draft.admission = v),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_draft.admission == TournamentAdmission.single) ...[
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('cat-${_draft.clubTypeId}'),
                    initialValue: _draft.categoryId,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
                    validator: (v) => v == null ? 'Elegí la categoría' : null,
                    onChanged: _lockedByEntries ? null : (v) => setState(() => _draft.categoryId = v),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey('lower-${_draft.categoryId}'),
                    initialValue: _draft.lowerCategoriesAllowed == null ? null : math.min(_draft.lowerCategoriesAllowed!, maxLower),
                    decoration: const InputDecoration(labelText: 'Categorías más bajas que se admiten'),
                    items: [
                      const DropdownMenuItem(value: 0, child: Text('Ninguna (solo esa)')),
                      for (var i = 1; i <= math.min(maxLower, 4); i++)
                        DropdownMenuItem(value: i, child: Text(i == 1 ? '1 más baja' : 'Hasta $i más bajas')),
                      const DropdownMenuItem(child: Text('Todas las más bajas')),
                    ],
                    onChanged: _lockedByEntries ? null : (v) => setState(() => _draft.lowerCategoriesAllowed = v),
                  ),
                ),
              ],
              if (_draft.admission == TournamentAdmission.sum)
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: _sumMin,
                    enabled: !_lockedByEntries,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Suma mínima'),
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) < 2 ? 'Poné la suma mínima' : null,
                  ),
                ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<TournamentBranch>(
                  initialValue: _draft.branch,
                  decoration: const InputDecoration(labelText: 'Rama'),
                  items: [for (final b in TournamentBranch.values) DropdownMenuItem(value: b, child: Text(b.label))],
                  onChanged: _lockedByEntries ? null : (v) => setState(() => _draft.branch = v!),
                ),
              ),
              SizedBox(
                width: 240,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Suma puntos al ranking'),
                  value: _draft.countsForRanking,
                  onChanged: (v) => setState(() => _draft.countsForRanking = v ?? true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(hint(), style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _formatSection() {
    final locked = _editing != null && _editing!.status != TournamentStatus.draft && _editing!.status != TournamentStatus.open;
    return SectionCard(
      title: 'Formato',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChoiceRow<TournamentFormat>(
            value: _draft.format,
            enabled: !locked,
            options: const [
              (TournamentFormat.singleElimination, 'Eliminación directa', 'Pierde y queda afuera.'),
              (TournamentFormat.groupsKnockout, 'Grupos + eliminación', 'Zonas todos contra todos, después llave.'),
              (TournamentFormat.league, 'Liga', 'Todos contra todos, tabla de puntos.'),
            ],
            onChanged: (v) => setState(() => _draft.format = v),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              if (_draft.format == TournamentFormat.groupsKnockout) ...[
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<int>(
                    initialValue: _draft.groupSize,
                    decoration: const InputDecoration(labelText: 'Equipos por zona'),
                    items: [for (final n in [3, 4, 5, 6]) DropdownMenuItem(value: n, child: Text('$n'))],
                    onChanged: locked ? null : (v) => setState(() {
                      _draft.groupSize = v!;
                      _draft.qualifiersPerGroup = math.min(_draft.qualifiersPerGroup, v - 1);
                    }),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('q-${_draft.groupSize}'),
                    initialValue: _draft.qualifiersPerGroup,
                    decoration: const InputDecoration(labelText: 'Clasifican por zona'),
                    items: [for (var n = 1; n < _draft.groupSize; n++) DropdownMenuItem(value: n, child: Text(n == 1 ? '1 primero' : '$n primeros'))],
                    onChanged: locked ? null : (v) => setState(() => _draft.qualifiersPerGroup = v!),
                  ),
                ),
              ],
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<Seeding>(
                  initialValue: _draft.seeding,
                  decoration: const InputDecoration(labelText: 'Sorteo'),
                  items: const [
                    DropdownMenuItem(value: Seeding.ranking, child: Text('Cabezas de serie por ranking')),
                    DropdownMenuItem(value: Seeding.random, child: Text('Aleatorio')),
                  ],
                  onChanged: locked ? null : (v) => setState(() => _draft.seeding = v!),
                ),
              ),
            ],
          ),
          if (_draft.format == TournamentFormat.groupsKnockout) ...[
            const SizedBox(height: 8),
            Text(
              'Desempate en las zonas: partidos ganados, diferencia de sets (o goles), de games y resultado entre ellos.',
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _matchesSection() {
    final sport = _sport;
    return SectionCard(
      title: 'Partidos y canchas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 300,
                child: DropdownButtonFormField<ScoreMode>(
                  key: ValueKey('score-${_draft.clubTypeId}'),
                  initialValue: _draft.scoreMode ?? sport?.defaultScoreMode,
                  decoration: const InputDecoration(labelText: 'Puntaje'),
                  items: const [
                    DropdownMenuItem(value: ScoreMode.sets, child: Text('Por sets (mejor de 3 o 1 set)')),
                    DropdownMenuItem(value: ScoreMode.points, child: Text('Puntos o goles')),
                  ],
                  onChanged: (v) => setState(() => _draft.scoreMode = v),
                ),
              ),
              SizedBox(
                width: 260,
                child: DurationMinutesField(
                  controller: _duration,
                  decoration: const InputDecoration(labelText: 'Duración de cada partido (min)'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return n == null || n < 15 || n > 300 ? 'Entre 15 y 300 minutos' : null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Canchas del torneo', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in sport?.courts ?? const <TournamentCourt>[])
                FilterChip(
                  label: Text(c.name),
                  selected: _draft.courtIds.contains(c.id),
                  onSelected: (on) => setState(() => on ? _draft.courtIds.add(c.id) : _draft.courtIds.remove(c.id)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            text: 'Cada partido que programes ocupa su cancha y horario: no es un turno (no se cobra ni aparece para reservar), '
                'pero bloquea la cancha en la agenda y en la búsqueda de turnos.',
          ),
        ],
      ),
    );
  }

  Widget _registrationSection() {
    final scheme = Theme.of(context).colorScheme;
    final format = _format;
    final fee = ThousandsFormat.parsePrice(_fee.text);
    final players = format?.playersPerTeam ?? 2;
    final feeHint = fee == null
        ? null
        : _draft.feeMode == FeeMode.perTeam
            ? 'Por equipo ${money(fee)}: cada jugador paga ${money(fee / players)} o el capitán paga todo.'
            : 'Cada jugador ${money(fee)} (equipo ${money(fee * players)}).';

    return SectionCard(
      title: 'Inscripción y pagos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: _minTeams,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Equipos mínimos'),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) < 2 ? 'Mínimo 2' : null,
                ),
              ),
              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: _maxTeams,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Equipos máximos'),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final max = int.tryParse(v ?? '') ?? 0;
                    final min = int.tryParse(_minTeams.text) ?? 2;
                    if (max < min) return 'No puede ser menor al mínimo';
                    return max > 128 ? 'Máximo 128' : null;
                  },
                ),
              ),
              _dateButton('Cierra inscripción', _draft.registrationClosesAt, (d) => _draft.registrationClosesAt = d),
              if (_draft.registrationClosesAt != null)
                SizedBox(width: 120, child: TimeField(controller: _closesTime, decoration: const InputDecoration(labelText: 'Hora'))),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Cobrar entrada'),
            subtitle: const Text('Con la cuenta de Mercado Pago del club, o registrando el pago en el club.'),
            value: _charge,
            onChanged: _lockedByEntries ? null : (v) => setState(() {
              _charge = v;
              if (v && _draft.minPaidPlayers < 1) _draft.minPaidPlayers = 1;
            }),
          ),
          if (_charge) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: PriceField(
                    controller: _fee,
                    decoration: InputDecoration(labelText: 'Valor', prefixText: '\$ ', enabled: !_lockedByEntries),
                    validator: (v) => (ThousandsFormat.parsePrice(v ?? '') ?? 0) <= 0 ? 'Poné el valor' : null,
                  ),
                ),
                SegmentedButton<FeeMode>(
                  segments: const [
                    ButtonSegment(value: FeeMode.perTeam, label: Text('Por equipo')),
                    ButtonSegment(value: FeeMode.perPlayer, label: Text('Por jugador')),
                  ],
                  selected: {_draft.feeMode},
                  onSelectionChanged: _lockedByEntries ? null : (v) => setState(() => _draft.feeMode = v.first),
                ),
              ],
            ),
            if (feeHint != null) ...[
              const SizedBox(height: 8),
              Text(feeHint, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Al cerrar la inscripción', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text('Se puede cambiar hasta que se sortee el cuadro.', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 280,
                        child: DropdownButtonFormField<int>(
                          key: ValueKey('minpaid-$players'),
                          initialValue: _draft.minPaidPlayers.clamp(1, players),
                          decoration: const InputDecoration(labelText: 'Mínimo de pagos para entrar al cuadro'),
                          items: [
                            for (var i = 1; i <= players; i++)
                              DropdownMenuItem(value: i, child: Text(i == players ? '$i de $players (todo pago)' : '$i de $players jugadores')),
                          ],
                          onChanged: (v) => setState(() => _draft.minPaidPlayers = v!),
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: DropdownButtonFormField<int>(
                          initialValue: _draft.finalReminderHours,
                          decoration: const InputDecoration(labelText: 'Aviso final de pagos pendientes'),
                          items: [
                            for (final h in {12, 24, 48, 72, _draft.finalReminderHours})
                              DropdownMenuItem(value: h, child: Text(h % 24 == 0 ? '${h ~/ 24} día${h > 24 ? 's' : ''} antes de su primer partido' : '$h h antes de su primer partido')),
                          ],
                          onChanged: (v) => setState(() => _draft.finalReminderHours = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Los equipos con menos pagos que el mínimo quedan fuera al cerrar. Los que entraron con pagos pendientes reciben el aviso final; '
                    'si no completan antes del partido, quedan fuera y su rival pasa.',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultsSection() {
    return SectionCard(
      title: 'Resultados',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChoiceRow<ResultMode>(
            value: _draft.resultMode,
            enabled: true,
            options: const [
              (ResultMode.consensus, 'Consenso entre equipos', 'Cargan los dos capitanes. Si coincide, se confirma y el ganador avanza solo.'),
              (ResultMode.admin, 'Solo el club', 'Los jugadores ven el cuadro. El club carga y confirma cada resultado.'),
            ],
            onChanged: (v) => setState(() => _draft.resultMode = v),
          ),
          if (_draft.resultMode == ResultMode.consensus)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Si solo un equipo cargó, confirmar a las 24 h sin objeción'),
              value: _draft.autoConfirmHours != null,
              onChanged: (v) => setState(() => _draft.autoConfirmHours = (v ?? false) ? 24 : null),
            ),
        ],
      ),
    );
  }

  // -- Resumen -----------------------------------------------------------------

  Widget _summary() {
    final scheme = Theme.of(context).colorScheme;
    final maxTeams = int.tryParse(_maxTeams.text) ?? 0;
    final players = _format?.playersPerTeam ?? 2;
    final duration = int.tryParse(_duration.text) ?? 90;

    int matches;
    int minPerTeam;
    switch (_draft.format) {
      case TournamentFormat.singleElimination:
        matches = math.max(0, maxTeams - 1);
        minPerTeam = 1;
      case TournamentFormat.league:
        matches = maxTeams * (maxTeams - 1) ~/ 2;
        minPerTeam = math.max(0, maxTeams - 1);
      case TournamentFormat.groupsKnockout:
        final groups = maxTeams == 0 ? 0 : (maxTeams / _draft.groupSize).ceil();
        final perGroup = groups == 0 ? 0 : (maxTeams / groups).floor();
        final qualified = groups * _draft.qualifiersPerGroup;
        matches = groups * (perGroup * (perGroup - 1) ~/ 2) + math.max(0, qualified - 1);
        minPerTeam = math.max(0, perGroup - 1);
    }
    final fee = _charge ? ThousandsFormat.parsePrice(_fee.text) : null;
    final revenue = fee == null ? null : (_draft.feeMode == FeeMode.perTeam ? fee * maxTeams : fee * maxTeams * players);
    final hours = matches * duration / 60;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RESUMEN', style: TextStyle(fontSize: 12, letterSpacing: 0.5, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(_name.text.trim().isEmpty ? 'Torneo sin nombre' : _name.text.trim(), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                SizedBox(width: 120, child: LabeledValue(label: 'Formato', value: _draft.format.label)),
                SizedBox(width: 120, child: LabeledValue(label: 'Partidos con $maxTeams', value: '$matches')),
                SizedBox(width: 120, child: LabeledValue(label: 'Mín. por equipo', value: '$minPerTeam partido${minPerTeam == 1 ? '' : 's'}')),
                SizedBox(width: 120, child: LabeledValue(label: 'Cancha ocupada', value: '${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)} h')),
                SizedBox(width: 120, child: LabeledValue(label: 'Recaudación máx.', value: revenue == null ? 'Sin cargo' : money(revenue))),
                SizedBox(width: 120, child: LabeledValue(label: 'Canchas', value: '${_draft.courtIds.length}')),
              ],
            ),
            if (_draft.courtIds.isNotEmpty && hours > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Con ${_draft.courtIds.length} cancha${_draft.courtIds.length == 1 ? '' : 's'} son unas ${(hours / _draft.courtIds.length).ceil()} h de juego.',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opciones excluyentes como tarjetas con radio (formato, regla de categoría, resultados).
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({required this.value, required this.options, required this.onChanged, required this.enabled});

  final T value;
  final List<(T, String, String)> options;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700 ? options.length : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (option, title, subtitle) in options)
              SizedBox(
                width: width,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: enabled ? () => onChanged(option) : null,
                  child: Container(
                    padding: EdgeInsets.all(option == value ? 15 : 16),
                    decoration: BoxDecoration(
                      color: option == value ? scheme.secondaryContainer.withValues(alpha: 0.35) : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: option == value ? scheme.primary : scheme.outlineVariant, width: option == value ? 2 : 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(option == value ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 20, color: option == value ? scheme.primary : scheme.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: TextStyle(fontSize: 15, color: enabled ? scheme.onSurface : scheme.onSurfaceVariant)),
                              const SizedBox(height: 4),
                              Text(subtitle, style: TextStyle(fontSize: 13, height: 1.35, color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
