import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/tournament/tournament.dart';
import '../../../domain/entities/tournament/tournament_schedule.dart';
import '../../../domain/repositories/tournament_repository.dart';
import '../club_config/widgets/time_field.dart';
import 'widgets/match_dialogs.dart';
import 'widgets/tournament_ui.dart';

/// Programación de un torneo sorteado: el club carga los días y horarios de
/// cada fase, turni reparte los partidos en las canchas (en paralelo cuando hay
/// más de una libre), y el club revisa, mueve lo que quiera y confirma. Lo que
/// no entra lo decide el club: sumar un horario, ubicarlo a mano o dejarlo sin
/// horario. Nada se publica hasta confirmar.
class TournamentSchedulePage extends StatefulWidget {
  const TournamentSchedulePage({super.key, required this.tournamentId});

  final int tournamentId;

  @override
  State<TournamentSchedulePage> createState() => _TournamentSchedulePageState();
}

/// Un día de juego mientras se edita. En eliminación solo hay "a partir de".
class _WindowDraft {
  _WindowDraft(this.phase, this.day, String from, [String? to])
      : from = TextEditingController(text: from),
        to = phase == SchedulePhase.group ? TextEditingController(text: to ?? '23:00') : null;

  final SchedulePhase phase;
  DateTime day;
  final TextEditingController from;
  final TextEditingController? to;

  /// Avisa cuando cambia una hora (no cuando solo se mueve el cursor).
  void onTimeChanged(VoidCallback callback) {
    for (final c in [from, if (to != null) to!]) {
      var last = c.text;
      c.addListener(() {
        if (c.text == last) return;
        last = c.text;
        callback();
      });
    }
  }

  void dispose() {
    from.dispose();
    to?.dispose();
  }
}

const _restOptions = [0, 30, 60, 90, 120];
const _maxPerDayOptions = <int?>[1, 2, 3, null];
const _cellHeight = 76.0;

String _slotKey(int courtId, DateTime start) => '$courtId@${start.millisecondsSinceEpoch}';

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

class _TournamentSchedulePageState extends State<TournamentSchedulePage> {
  final _repository = sl<TournamentRepository>();

  Tournament? _t;
  TournamentSchedule? _schedule;
  String? _error;
  bool _busy = false;

  final List<_WindowDraft> _windows = [];
  int _rest = 90;
  int? _maxPerDay = 2;
  /// Se cambiaron los días o las reglas después de generar.
  bool _configDirty = false;

  /// La programación que se está editando (el servidor solo la valida).
  List<SchedulePlacement> _placements = [];
  /// Motivo de cada partido sin lugar (del reparto automático).
  final Map<String, String?> _reasons = {};
  /// Partidos que el club decidió dejar sin horario.
  final Set<String> _deferred = {};
  /// Hubo movimientos a mano desde el último reparto.
  bool _manualChanges = false;

  String? _selected;
  Map<String, ScheduleOption> _options = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final w in _windows) {
      w.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([_repository.getTournament(widget.tournamentId), _repository.getSchedule(widget.tournamentId)]);
    if (!mounted) return;
    final tResult = results[0] as RepositoryResponse<Tournament>;
    final sResult = results[1] as RepositoryResponse<TournamentSchedule>;
    String? error;
    tResult.when(left: (f) => error = f.message, right: (t) => _t = t);
    sResult.when(left: (f) => error ??= f.message, right: (s) => _applyLoaded(s));
    setState(() => _error = error);
  }

  void _applyLoaded(TournamentSchedule s) {
    _schedule = s;
    _rest = s.config.restMinutes;
    _maxPerDay = s.config.maxMatchesPerDay;
    for (final w in _windows) {
      w.dispose();
    }
    _windows.clear();
    if (s.config.windows.isNotEmpty) {
      for (final w in s.config.windows) {
        _windows.add(_WindowDraft(w.phase, _dayOf(w.start), hhmm(w.start), w.phase == SchedulePhase.group ? hhmm(w.end) : null));
      }
    } else {
      // Primera vez: arranca con las fechas del torneo.
      final starts = _t?.startsAt ?? DateTime.now().add(const Duration(days: 7));
      final ends = _t?.endsAt ?? starts;
      _windows.add(_WindowDraft(SchedulePhase.group, _dayOf(starts), hhmm(starts), '23:00'));
      _windows.add(_WindowDraft(SchedulePhase.knockout, _dayOf(ends), '10:00'));
    }
    for (final w in _windows) {
      w.onTimeChanged(_markDirty);
    }
    _placements = [...s.placements];
    _reasons
      ..clear()
      ..addAll(s.unplaced);
    _deferred.clear();
    _configDirty = false;
    _manualChanges = false;
  }

  // -- Pedidos -------------------------------------------------------------------

  List<ScheduleWindow>? _buildWindows() {
    DateTime? at(DateTime day, String text) {
      final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(text.trim());
      if (m == null) return null;
      return DateTime(day.year, day.month, day.day, int.parse(m.group(1)!), int.parse(m.group(2)!));
    }

    final out = <ScheduleWindow>[];
    for (final w in _windows) {
      final start = at(w.day, w.from.text);
      final end = w.to == null ? DateTime(w.day.year, w.day.month, w.day.day, 23, 59) : at(w.day, w.to!.text);
      if (start == null || end == null) {
        SnackbarsFunctions.showErrorsSnackbar(context, 'Completá los horarios de cada día (HH:MM).');
        return null;
      }
      if (!end.isAfter(start)) {
        SnackbarsFunctions.showErrorsSnackbar(context, 'El ${shortDate(w.day)}: la hora de fin tiene que ser después de la de inicio.');
        return null;
      }
      out.add(ScheduleWindow(phase: w.phase, start: start, end: end));
    }
    if (!out.any((w) => w.phase == SchedulePhase.group) && _hasPhase(SchedulePhase.group)) {
      SnackbarsFunctions.showErrorsSnackbar(context, 'Agregá al menos un día para la fase de grupos.');
      return null;
    }
    if (!out.any((w) => w.phase == SchedulePhase.knockout) && _hasPhase(SchedulePhase.knockout)) {
      SnackbarsFunctions.showErrorsSnackbar(context, 'Agregá al menos un día para la eliminación.');
      return null;
    }
    return out;
  }

  bool _hasPhase(SchedulePhase phase) => _schedule?.matches.any((m) => m.phase == phase) ?? false;

  Future<TournamentSchedule?> _call(Future<RepositoryResponse<TournamentSchedule>> Function() action) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return null;
    setState(() => _busy = false);
    return result.when(
      left: (failure) {
        SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
        return null;
      },
      right: (s) => s,
    );
  }

  ScheduleRequest _request(List<ScheduleWindow> windows, {List<SchedulePlacement>? placements, String? focusKey, bool accept = false}) =>
      ScheduleRequest(windows: windows, restMinutes: _rest, maxMatchesPerDay: _maxPerDay, placements: placements, focusKey: focusKey, acceptWarnings: accept);

  /// Reparte de cero con los días y reglas cargados.
  Future<void> _generate({bool ask = true}) async {
    final windows = _buildWindows();
    if (windows == null) return;
    if (ask && _manualChanges && !await confirmAction(
      context,
      title: 'Volver a generar',
      message: 'Se reparten todos los partidos de nuevo y se pierde lo que moviste a mano.',
      confirm: 'Generar',
    )) {
      return;
    }
    final s = await _call(() => _repository.previewSchedule(widget.tournamentId, _request(windows)));
    if (s == null) return;
    setState(() {
      _schedule = s;
      _placements = [...s.placements];
      _reasons
        ..clear()
        ..addAll(s.unplaced);
      _deferred.clear();
      _selected = null;
      _options = {};
      _configDirty = false;
      _manualChanges = false;
    });
  }

  /// Revalida lo editado (advertencias, sin lugar, resumen).
  Future<void> _revalidate() async {
    final windows = _buildWindows();
    if (windows == null) return;
    final s = await _call(() => _repository.previewSchedule(widget.tournamentId, _request(windows, placements: _placements)));
    if (s == null) return;
    setState(() {
      _schedule = s;
      for (final key in s.unplaced.keys) {
        _reasons.putIfAbsent(key, () => s.unplaced[key]);
      }
    });
  }

  Future<void> _select(String key) async {
    if (_configDirty) {
      SnackbarsFunctions.showErrorsSnackbar(context, 'Cambiaste los días o las reglas: generá la vista previa de nuevo antes de mover partidos.');
      return;
    }
    if (_selected == key) {
      setState(() {
        _selected = null;
        _options = {};
      });
      return;
    }
    final windows = _buildWindows();
    if (windows == null) return;
    setState(() => _selected = key);
    final s = await _call(() => _repository.previewSchedule(widget.tournamentId, _request(windows, placements: _placements, focusKey: key)));
    if (s == null || _selected != key) return;
    setState(() => _options = {for (final o in s.options ?? const <ScheduleOption>[]) _slotKey(o.courtId, o.start): o});
  }

  Future<void> _moveTo(ScheduleOption option) async {
    final key = _selected;
    if (key == null) return;
    setState(() {
      _placements = [
        for (final p in _placements)
          if (p.key != key) p,
        SchedulePlacement(key: key, courtId: option.courtId, start: option.start),
      ];
      _deferred.remove(key);
      _reasons.remove(key);
      _selected = null;
      _options = {};
      _manualChanges = true;
    });
    await _revalidate();
  }

  Future<void> _unplace() async {
    final key = _selected;
    if (key == null) return;
    setState(() {
      _placements = [
        for (final p in _placements)
          if (p.key != key) p,
      ];
      _reasons[key] = null;
      _selected = null;
      _options = {};
      _manualChanges = true;
    });
    await _revalidate();
  }

  void _defer(String key) => setState(() {
        _deferred.add(key);
        if (_selected == key) {
          _selected = null;
          _options = {};
        }
      });

  /// Suma un horario al final del último día de esa fase (y corre la
  /// eliminación si arrancaba justo después), y vuelve a repartir.
  Future<void> _addSlot(SchedulePhase phase) async {
    final duration = _schedule?.config.matchDurationMinutes ?? 90;
    final drafts = _windows.where((w) => w.phase == phase).toList();
    if (drafts.isEmpty) return;
    final last = drafts.reduce((a, b) => a.day.isAfter(b.day) ? a : b);
    final ctrl = last.to ?? last.from;
    final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(ctrl.text.trim());
    if (m == null) return;
    final minutes = int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
    if (phase == SchedulePhase.group) {
      final newEnd = minutes + duration;
      if (newEnd >= 24 * 60) {
        SnackbarsFunctions.showErrorsSnackbar(context, 'No entra otro partido ese día: agregá otro día de grupos.');
        return;
      }
      ctrl.text = '${two(newEnd ~/ 60)}:${two(newEnd % 60)}';
      for (final ko in _windows.where((w) => w.phase == SchedulePhase.knockout && _dayOf(w.day) == _dayOf(last.day))) {
        final km = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(ko.from.text.trim());
        if (km == null) continue;
        final koStart = int.parse(km.group(1)!) * 60 + int.parse(km.group(2)!);
        if (koStart < newEnd) {
          final shifted = koStart + duration;
          ko.from.text = '${two(shifted ~/ 60)}:${two(shifted % 60)}';
        }
      }
    } else {
      SnackbarsFunctions.showErrorsSnackbar(context, 'Agregá otro día de eliminación o adelantá su horario.');
      return;
    }
    await _generate(ask: _manualChanges);
  }

  Future<void> _publish() async {
    final windows = _buildWindows();
    if (windows == null) return;
    var accept = false;
    while (true) {
      setState(() => _busy = true);
      final result = await _repository.confirmSchedule(widget.tournamentId, _request(windows, placements: _placements, accept: accept));
      if (!mounted) return;
      setState(() => _busy = false);
      final retry = await result.when(
        left: (failure) async {
          final code = failure.details is Map ? (failure.details as Map)['code'] : null;
          if (code == 'SCHEDULE_WARNINGS' && !accept) {
            return confirmAction(context, title: 'Publicar igual', message: failure.message, confirm: 'Publicar igual');
          }
          SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
          return false;
        },
        right: (s) async {
          SnackbarsFunctions.showSuccessSnackbar(context, 'Programación publicada. Se avisó a los equipos.');
          // Volver al detalle (que recarga al volver) o abrirlo si se entró directo.
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(AppRoutes.TOURNAMENT_DETAIL_ROUTE.name, pathParameters: {'tournamentId': '${widget.tournamentId}'});
          }
          return false;
        },
      );
      if (!retry) return;
      accept = true;
    }
  }

  void _markDirty() {
    if (!_configDirty) setState(() => _configDirty = true);
  }

  // -- Cálculos para la vista ------------------------------------------------------

  Map<String, ScheduleMatch> get _matchByKey => {for (final m in _schedule?.matches ?? const <ScheduleMatch>[]) m.key: m};

  List<String> get _unplacedKeys {
    final placed = {for (final p in _placements) p.key};
    return [for (final m in _schedule?.matches ?? const <ScheduleMatch>[]) if (!placed.contains(m.key)) m.key];
  }

  /// Sin lugar y sin decisión. Antes de la primera vista previa no hay nada que decidir.
  List<String> get _pending => (_schedule?.slots.isEmpty ?? true) ? const [] : [for (final k in _unplacedKeys) if (!_deferred.contains(k)) k];

  // -- UI -----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = _t;
    final s = _schedule;
    if (t == null || s == null) {
      return Scaffold(
        backgroundColor: scheme.surfaceContainer,
        appBar: AppBar(),
        body: _error != null ? LoadError(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator()),
      );
    }

    final pending = _pending;
    final blockedIssues = s.blocked.isNotEmpty;
    final canPublish = !_busy && !_configDirty && pending.isEmpty && !blockedIssues && s.slots.isNotEmpty;
    final deferred = _deferred.where(_unplacedKeys.contains).length;
    final publishLabel = _configDirty || s.slots.isEmpty
        ? 'Generá la vista previa para publicar'
        : pending.isNotEmpty
            ? 'Resolvé ${pending.length} sin lugar para publicar'
            : deferred > 0
                ? 'Confirmar y publicar · $deferred sin horario'
                : 'Confirmar y publicar';

    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      appBar: AppBar(
        title: Text('Programación · ${t.name}'),
        actions: [
          if (_busy) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          FilledButton.icon(
            onPressed: canPublish ? _publish : null,
            icon: Icon(canPublish ? Icons.event_available : Icons.block, size: 18),
            label: Text(publishLabel),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Align(alignment: Alignment.centerLeft, child: _steps(s))),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1100;
          final config = _configPanel(t, s);
          final preview = _previewPanel(s);
          if (!wide) {
            return ListView(padding: const EdgeInsets.all(16), children: [config, const SizedBox(height: 16), preview]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 400, child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 24, 12, 24), child: config)),
              Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 24, 24, 24), child: preview)),
            ],
          );
        },
      ),
    );
  }

  Widget _steps(TournamentSchedule s) {
    final scheme = Theme.of(context).colorScheme;
    Widget step(String label, {required bool done, bool current = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(done ? Icons.check_circle : (current ? Icons.radio_button_checked : Icons.radio_button_unchecked), size: 18, color: done || current ? scheme.primary : scheme.outlineVariant),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: current ? FontWeight.w700 : FontWeight.w400, color: done || current ? scheme.onSurface : scheme.onSurfaceVariant)),
          ],
        );
    Widget line() => Container(width: 32, height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: scheme.outlineVariant);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        step('Inscripción cerrada', done: true),
        line(),
        step('Sorteo', done: true),
        line(),
        step('Días, canchas y revisión', done: false, current: true),
        line(),
        step(s.confirmedAt != null ? 'Publicada' : 'Publicar', done: s.confirmedAt != null),
      ]),
    );
  }

  // -- Panel izquierdo: configuración y decisiones ---------------------------------

  Widget _configPanel(Tournament t, TournamentSchedule s) {
    final scheme = Theme.of(context).colorScheme;
    final groupCount = s.matches.where((m) => m.phase == SchedulePhase.group).length;
    final koCount = s.matches.where((m) => m.phase == SchedulePhase.knockout).length;
    final unplaced = _unplacedKeys;
    final pending = _pending;
    final matches = _matchByKey;
    final warnings = {for (final w in s.warnings) ...w.reasons}.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Cuándo se juega',
          subtitle: 'Turni reparte los partidos en estos horarios.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (groupCount > 0) ...[
                _phaseHeader(Icons.grid_view, t.format == TournamentFormat.league ? 'LIGA · $groupCount PARTIDOS' : 'FASE DE GRUPOS · $groupCount PARTIDOS'),
                for (final w in _windows.where((w) => w.phase == SchedulePhase.group)) _windowRow(w),
                _addDayButton(SchedulePhase.group, t.format == TournamentFormat.league ? 'Agregar día' : 'Agregar día de grupos'),
              ],
              if (groupCount > 0 && koCount > 0) Divider(height: 24, color: scheme.outlineVariant),
              if (koCount > 0) ...[
                _phaseHeader(Icons.account_tree_outlined, 'ELIMINACIÓN · $koCount PARTIDOS'),
                for (final w in _windows.where((w) => w.phase == SchedulePhase.knockout)) _windowRow(w),
                if (groupCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(
                      'Puede ser el mismo día que la última fecha de grupos: la eliminación arranca después del último partido de zona.',
                      style: TextStyle(fontSize: 12, height: 1.4, color: scheme.onSurfaceVariant),
                    ),
                  ),
                _addDayButton(SchedulePhase.knockout, 'Agregar día de eliminación'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Reglas para repartir',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _restOptions.contains(_rest) ? _rest : 90,
                    decoration: const InputDecoration(labelText: 'Descanso mínimo', helperText: 'Por equipo', isDense: true),
                    items: [for (final r in _restOptions) DropdownMenuItem(value: r, child: Text(r == 0 ? 'Sin descanso' : '$r min'))],
                    onChanged: (v) => setState(() {
                      _rest = v ?? 90;
                      _configDirty = true;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _maxPerDay,
                    decoration: const InputDecoration(labelText: 'Partidos por día', helperText: 'Máximo, por equipo', isDense: true),
                    items: [for (final m in _maxPerDayOptions) DropdownMenuItem(value: m, child: Text(m == null ? 'Sin límite' : '$m'))],
                    onChanged: (v) => setState(() {
                      _maxPerDay = v;
                      _configDirty = true;
                    }),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Text('Canchas del torneo · se usan en paralelo', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final c in s.config.courts) Chip(avatar: const Icon(Icons.check, size: 16), label: Text(c.name))]),
              const SizedBox(height: 8),
              Text('Para cambiar las canchas, editá el torneo. Los turnos ya reservados se respetan: nunca se pisan.', style: TextStyle(fontSize: 12, height: 1.4, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              Row(children: [
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _generate(),
                  icon: const Icon(Icons.autorenew, size: 18),
                  label: Text(s.slots.isEmpty && _placements.isEmpty ? 'Generar vista previa' : 'Volver a generar'),
                ),
                const SizedBox(width: 12),
                if (_manualChanges) Expanded(child: Text('Reemplaza lo que moviste a mano.', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
              ]),
              if (_configDirty) ...[
                const SizedBox(height: 12),
                const InfoBanner(icon: Icons.edit_calendar_outlined, text: 'Cambiaste los días o las reglas. Generá la vista previa para ver cómo queda.'),
              ],
            ],
          ),
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 16),
          _pendingCard(pending, matches),
        ],
        if (unplaced.any(_deferred.contains)) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Sin horario, por decisión tuya',
            subtitle: 'Se publican igual. Los programás después desde el torneo.',
            child: Column(children: [
              for (final key in unplaced.where(_deferred.contains))
                _matchLine(matches[key]!, trailing: TextButton(onPressed: () => _select(key), child: const Text('Ubicar'))),
            ]),
          ),
        ],
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Reglas que aceptaste romper',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final w in warnings)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.rule, size: 18, color: StatusTone.warning(scheme).foreground),
                      const SizedBox(width: 8),
                      Expanded(child: Text(w, style: TextStyle(fontSize: 13, height: 1.4, color: scheme.onSurfaceVariant))),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _phaseHeader(IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4, color: scheme.primary)),
      ]),
    );
  }

  Widget _windowRow(_WindowDraft w) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44), alignment: Alignment.centerLeft),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: w.day,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => w.day = picked);
                  _markDirty();
                }
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(shortDate(w.day)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TimeField(
              controller: w.from,
              isDense: true,
              decoration: InputDecoration(labelText: w.to == null ? 'A partir de' : 'Desde'),
            ),
          ),
          if (w.to != null) ...[
            const SizedBox(width: 8),
            Expanded(flex: 3, child: TimeField(controller: w.to!, isDense: true, decoration: const InputDecoration(labelText: 'Hasta'))),
          ],
          IconButton(
            tooltip: 'Quitar día',
            onPressed: _windows.where((x) => x.phase == w.phase).length <= 1
                ? null
                : () {
                    setState(() {
                      _windows.remove(w);
                      w.dispose();
                    });
                    _markDirty();
                  },
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _addDayButton(SchedulePhase phase, String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          final same = _windows.where((w) => w.phase == phase).toList();
          final last = same.isEmpty ? DateTime.now() : same.map((w) => w.day).reduce((a, b) => a.isAfter(b) ? a : b);
          final draft = same.isEmpty
              ? _WindowDraft(phase, _dayOf(last), phase == SchedulePhase.group ? '18:00' : '10:00')
              : _WindowDraft(phase, _dayOf(last.add(const Duration(days: 1))), same.last.from.text, same.last.to?.text);
          draft.onTimeChanged(_markDirty);
          setState(() => _windows.add(draft));
          _markDirty();
        },
        icon: const Icon(Icons.add, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _pendingCard(List<String> pending, Map<String, ScheduleMatch> matches) {
    final scheme = Theme.of(context).colorScheme;
    final warn = StatusTone.warning(scheme);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: warn.foreground.withValues(alpha: 0.6))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.warning_amber_rounded, color: warn.foreground),
              const SizedBox(width: 8),
              Text(pending.length == 1 ? '1 partido sin lugar' : '${pending.length} partidos sin lugar', style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 4),
            Text('Decidí qué hacer con cada uno. No se publica hasta resolverlos.', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            for (final key in pending) ...[
              const SizedBox(height: 16),
              Text(matches[key]!.title, style: TextStyle(fontSize: 12, color: warn.foreground)),
              Text('${matches[key]!.teamA} vs ${matches[key]!.teamB}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(_reasons[key] ?? 'Lo sacaste del cronograma.', style: TextStyle(fontSize: 13, height: 1.4, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              _decision(
                'Sumar un horario a ${matches[key]!.phase == SchedulePhase.group ? 'la fase de grupos' : 'la eliminación'}',
                matches[key]!.phase == SchedulePhase.group ? 'Alarga el último día de grupos un partido (y corre la eliminación si arrancaba justo después) y vuelve a repartir.' : 'Agregá un día o adelantá el horario de la eliminación.',
                () => _addSlot(matches[key]!.phase),
                highlighted: true,
              ),
              _decision('Ubicarlo a mano', 'Elegí un hueco libre. Podés mover otro partido para hacer lugar.', () => _select(key)),
              _decision('Dejarlo sin horario', 'Se publica igual y lo programás después desde el torneo.', () => _defer(key)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _decision(String title, String subtitle, VoidCallback onTap, {bool highlighted = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton(
        onPressed: _busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          alignment: Alignment.centerLeft,
          backgroundColor: highlighted ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
          side: BorderSide(color: highlighted ? scheme.primary : scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 12, height: 1.3, color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _matchLine(ScheduleMatch m, {Widget? trailing}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.title, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            Text('${m.teamA} vs ${m.teamB}', style: const TextStyle(fontSize: 14)),
          ]),
        ),
        if (trailing != null) trailing,
      ]),
    );
  }

  // -- Panel derecho: vista previa ---------------------------------------------------

  Widget _previewPanel(TournamentSchedule s) {
    final scheme = Theme.of(context).colorScheme;
    if (s.slots.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(children: [
            Icon(Icons.calendar_month_outlined, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('Cargá los días de juego y generá la vista previa.', textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Nada se publica hasta que confirmes.', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _busy ? null : () => _generate(), icon: const Icon(Icons.auto_awesome, size: 18), label: const Text('Generar vista previa')),
          ]),
        ),
      );
    }

    final unplaced = _unplacedKeys.length;
    final pending = _pending.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(spacing: 12, runSpacing: 12, children: [
          _stat('Programados', '${_placements.length}', 'de ${s.matches.length} partidos'),
          _stat('Sin horario', '$unplaced', pending > 0 ? 'esperan tu decisión' : (unplaced > 0 ? 'decidiste dejarlos así' : 'todo ubicado'),
              color: pending > 0 ? StatusTone.warning(scheme).foreground : null),
          _stat('En simultáneo', 'hasta ${s.maxParallel}', 'una cancha por partido'),
          _stat('Termina', s.endsAt == null ? '–' : shortDateTime(s.endsAt!), _lastMatchLabel(s)),
        ]),
        const SizedBox(height: 16),
        _selectionBar(),
        const SizedBox(height: 16),
        for (final day in _days(s)) ...[_dayCard(s, day), const SizedBox(height: 16)],
      ],
    );
  }

  String _lastMatchLabel(TournamentSchedule s) {
    if (_placements.isEmpty) return '';
    final last = _placements.reduce((a, b) => a.start.isAfter(b.start) ? a : b);
    final court = s.config.courts.where((c) => c.id == last.courtId).firstOrNull?.name ?? '';
    return '${_matchByKey[last.key]?.title.toLowerCase() ?? ''} · $court';
  }

  Widget _stat(String label, String value, String caption, {Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 200,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 24, color: color ?? scheme.onSurface)),
            Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }

  Widget _selectionBar() {
    final scheme = Theme.of(context).colorScheme;
    final key = _selected;
    final m = key == null ? null : _matchByKey[key];
    if (m == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.touch_app_outlined, size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('Tocá un partido para moverlo a otro hueco libre.', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
            ]),
            _legend(scheme.surfaceContainerHighest, scheme.outlineVariant, 'Grupos'),
            _legend(scheme.secondaryContainer, scheme.secondary, 'Eliminación'),
            _legend(Colors.transparent, scheme.outlineVariant, 'Libre'),
            _legend(scheme.surfaceContainerLowest, scheme.surfaceContainerLowest, 'Turno reservado'),
          ],
        ),
      );
    }
    final placed = _placements.where((p) => p.key == key).firstOrNull;
    final court = placed == null ? null : _schedule!.config.courts.where((c) => c.id == placed.courtId).firstOrNull?.name;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: scheme.primary)),
      child: Row(children: [
        Icon(Icons.open_with, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Moviendo · ${m.title} · ${m.teamA} vs ${m.teamB}', style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '${placed == null ? 'Sin horario' : 'Ahora: $court, ${shortDateTime(placed.start)}'} · Verde cumple todo; ámbar rompe una regla y te dice cuál.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ]),
        ),
        if (placed != null) OutlinedButton(onPressed: _busy ? null : _unplace, child: const Text('Sacar del cronograma')),
        const SizedBox(width: 8),
        TextButton(onPressed: () => setState(() {
              _selected = null;
              _options = {};
            }), child: const Text('Cancelar')),
      ]),
    );
  }

  Widget _legend(Color fill, Color border, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: fill, border: Border.all(color: border), borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
    ]);
  }

  List<DateTime> _days(TournamentSchedule s) => ({for (final slot in s.slots) _dayOf(slot.start)}.toList()..sort());

  Widget _dayCard(TournamentSchedule s, DateTime day) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final courts = s.config.courts;
    final slots = s.slots.where((x) => _dayOf(x.start) == day).toList();
    final times = {for (final x in slots) x.start}.toList()..sort();
    final slotAt = {for (final x in slots) _slotKey(x.courtId, x.start): x};
    final placedAt = {for (final p in _placements) _slotKey(p.courtId, p.start): p.key};
    final dayMatches = _placements.where((p) => _dayOf(p.start) == day).length;
    final phasesOfDay = {for (final x in slots) ...x.phases};

    final rows = <Widget>[];
    String? lastPhase;
    for (final time in times) {
      final phases = {for (final c in courts) ...?slotAt[_slotKey(c.id, time)]?.phases};
      final phase = phases.contains(SchedulePhase.group) && phases.contains(SchedulePhase.knockout)
          ? 'GRUPOS Y ELIMINACIÓN'
          : phases.contains(SchedulePhase.knockout)
              ? 'ELIMINACIÓN'
              : (_t?.format == TournamentFormat.league ? 'LIGA' : 'FASE DE GRUPOS');
      if (phase != lastPhase) {
        lastPhase = phase;
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Row(children: [
            Icon(phases.contains(SchedulePhase.knockout) ? Icons.account_tree_outlined : Icons.grid_view, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            Text('$phase · DESDE ${hhmm(time)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4, color: scheme.primary)),
            const SizedBox(width: 10),
            Expanded(child: Divider(color: scheme.primary.withValues(alpha: 0.4))),
          ]),
        ));
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 56, child: Padding(padding: const EdgeInsets.only(top: 10), child: Text(hhmm(time), style: TextStyle(fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant)))),
            for (final (i, c) in courts.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _cell(slotAt[_slotKey(c.id, time)], placedAt[_slotKey(c.id, time)], c.id, time)),
            ],
          ],
        ),
      ));
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: Text(_longDay(day), style: text.titleMedium)),
              Text(
                '${phasesOfDay.length == 2 ? 'Grupos y eliminación' : phasesOfDay.contains(SchedulePhase.knockout) ? 'Eliminación' : 'Grupos'} · $dayMatches partido${dayMatches == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const SizedBox(width: 56),
              for (final (i, c) in courts.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: Text(c.name.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant))),
              ],
            ]),
            ...rows,
          ],
        ),
      ),
    );
  }

  String _longDay(DateTime d) {
    const names = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${names[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  Widget _cell(ScheduleSlot? slot, String? placedKey, int courtId, DateTime time) {
    final scheme = Theme.of(context).colorScheme;
    BoxDecoration box({required Color fill, required Color border, double width = 1}) =>
        BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8), border: Border.all(color: border, width: width));

    if (slot == null) {
      return SizedBox(height: _cellHeight, child: DecoratedBox(decoration: box(fill: Colors.transparent, border: Colors.transparent)));
    }

    if (placedKey != null) {
      final m = _matchByKey[placedKey]!;
      final selected = _selected == placedKey;
      final knockout = m.phase == SchedulePhase.knockout;
      return Semantics(
        button: true,
        selected: selected,
        label: '${m.title}: ${m.teamA} contra ${m.teamB}',
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _busy ? null : () => _select(placedKey),
          child: Container(
            height: _cellHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: box(
              fill: selected ? scheme.primaryContainer : (knockout ? scheme.secondaryContainer : scheme.surfaceContainerHighest),
              border: selected ? scheme.primary : (knockout ? scheme.secondary : scheme.outlineVariant),
              width: selected ? 2 : 1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: knockout ? scheme.onSecondaryContainer : scheme.onSurfaceVariant)),
                Text(m.teamA, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface)),
                Text('vs ${m.teamB}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      );
    }

    if (slot.busy != null) {
      return Container(
        height: _cellHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: box(fill: scheme.surfaceContainerLowest, border: scheme.surfaceContainerLowest),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(children: [
            Icon(Icons.lock_outline, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('Ocupada', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant)),
          ]),
          Text(slot.busy!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ]),
      );
    }

    final option = _selected == null ? null : _options[_slotKey(courtId, time)];
    if (option == null || option.level == OptionLevel.blocked) {
      return Container(
        height: _cellHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: box(fill: Colors.transparent, border: scheme.outlineVariant.withValues(alpha: option == null ? 1 : 0.5)),
        child: Center(
          child: Text(
            option == null ? 'Libre' : option.reasons.firstOrNull ?? 'No disponible',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, height: 1.25, color: scheme.onSurfaceVariant.withValues(alpha: option == null ? 1 : 0.7)),
          ),
        ),
      );
    }

    final ok = option.level == OptionLevel.ok;
    final tone = ok ? StatusTone.success(scheme) : StatusTone.warning(scheme);
    return Semantics(
      button: true,
      label: ok ? 'Mover acá' : 'Mover igual: ${option.reasons.join(' ')}',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _busy ? null : () => _moveTo(option),
        child: Container(
          height: _cellHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: box(fill: tone.background, border: tone.foreground, width: 2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(ok ? 'Mover acá' : 'Mover igual', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tone.foreground)),
            Text(ok ? 'Cumple todas las reglas' : option.reasons.first, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, height: 1.25, color: tone.foreground)),
          ]),
        ),
      ),
    );
  }
}
