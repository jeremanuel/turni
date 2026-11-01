import '../../../../core/utils/either.dart';
import 'package:flutter/material.dart';

import '../../../../core/presentation/components/loading/app_skeleton.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../domain/entities/tournament/tournament.dart';
import '../../../../domain/repositories/tournament_repository.dart';
import '../../club_config/widgets/admin_data_table.dart';
import '../../tournaments/widgets/tournament_ui.dart';

/// Categorías del cliente por deporte: la de este club (si lo categoriza, la
/// asigna el admin y lo puede marcar "en observación"), la personal y las de
/// otros clubes, con el historial, los votos de sus rivales y su ranking.
class CategoriesContainer extends StatefulWidget {
  const CategoriesContainer({super.key, required this.clientId});

  final int clientId;

  @override
  State<CategoriesContainer> createState() => _CategoriesContainerState();
}

class _CategoriesContainerState extends State<CategoriesContainer> {
  final _repository = sl<TournamentRepository>();

  List<ClientSportCategories>? _sports;
  String? _error;
  int _selected = 0;
  bool _saving = false;

  bool get _canEdit => Permissions.can(Permissions.CLIENTES_CATEGORIAS);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repository.getClientCategories(widget.clientId);
    if (!mounted) return;
    result.when(
      left: (failure) => setState(() => _error = failure.message),
      right: (sports) => setState(() {
        _sports = sports;
        // Primero el deporte que el club categoriza o donde tiene algo.
        final i = sports.indexWhere((s) => s.categorizes || s.personal != null || s.otherClubs.isNotEmpty);
        _selected = i < 0 ? 0 : i;
      }),
    );
  }

  Future<void> _save(ClientSportCategories sport, {int? categoryId, CategoryObservation? observation}) async {
    setState(() => _saving = true);
    final result = await _repository.setClientCategory(widget.clientId, clubTypeId: sport.clubTypeId, categoryId: categoryId, observation: observation);
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      left: (failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (sports) {
        setState(() => _sports = sports);
        SnackbarsFunctions.showSuccessSnackbar(context, 'Categoría actualizada');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final sports = _sports;

    Widget body;
    if (_error != null) {
      body = Text(_error!, style: TextStyle(color: scheme.error));
    } else if (sports == null) {
      body = const SkeletonRows(count: 2);
    } else if (sports.isEmpty) {
      body = Text('El club no tiene deportes con categorías.', style: TextStyle(color: scheme.onSurfaceVariant));
    } else {
      final sport = sports[_selected.clamp(0, sports.length - 1)];
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, s) in sports.indexed)
                ChoiceChip(label: Text(s.sportName), selected: i == _selected, onSelected: (_) => setState(() => _selected = i)),
            ],
          ),
          const SizedBox(height: 16),
          _sportView(sport),
        ],
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('Categorías', style: text.titleMedium)),
                if (_saving) const InlineSpinner(),
              ],
            ),
            const SizedBox(height: 4),
            Text('Son públicas: el jugador y cualquier club las ven en su perfil.', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            body,
          ],
        ),
      ),
    );
  }

  Widget _sportView(ClientSportCategories s) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final thisClub = s.thisClub;

    final thisClubBox = Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: s.categorizes ? scheme.secondaryContainer.withValues(alpha: 0.35) : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.categorizes ? scheme.primary : scheme.outlineVariant, width: s.categorizes ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ESTE CLUB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: scheme.primary)),
          const SizedBox(height: 8),
          if (!s.categorizes)
            Text('No categoriza ${s.sportName}. Activalo en Torneos › Categorías.', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant))
          else if (_canEdit)
            DropdownButtonFormField<int>(
              key: ValueKey('club-cat-${s.clubTypeId}-${thisClub?.name}'),
              initialValue: s.scale.where((c) => c.name == thisClub?.name).firstOrNull?.id,
              decoration: const InputDecoration(labelText: 'Categoría del club', isDense: true),
              items: [for (final c in s.scale) DropdownMenuItem(value: c.id, child: Text(c.name))],
              onChanged: _saving ? null : (v) => v == null ? null : _save(s, categoryId: v),
            )
          else
            Text(thisClub?.name ?? 'Sin asignar', style: text.headlineSmall),
          if (thisClub?.updatedAt != null) ...[
            const SizedBox(height: 6),
            Text('Desde ${numericDate(thisClub!.updatedAt!)}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
        ],
      ),
    );

    Widget smallBox(String label, AssignedCategory? c, {String? caption}) => Container(
          width: 200,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: scheme.outlineVariant)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              Text(c?.name ?? '—', style: text.headlineSmall),
              if (caption != null) Text(caption, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            thisClubBox,
            smallBox('Personal', s.personal, caption: s.personal == null ? 'No la definió' : 'La definió el jugador'),
            for (final o in s.otherClubs) smallBox(o.clubName ?? 'Otro club', o, caption: o.observation == CategoryObservation.none ? null : 'En observación'),
          ],
        ),
        if (s.categorizes && thisClub != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 20, color: StatusTone.warning(scheme).foreground),
              const SizedBox(width: 8),
              Text('En observación', style: text.titleSmall),
              const SizedBox(width: 16),
              Flexible(
                child: SegmentedButton<CategoryObservation>(
                  segments: const [
                    ButtonSegment(value: CategoryObservation.none, label: Text('No')),
                    ButtonSegment(value: CategoryObservation.up, label: Text('Posible ascenso'), icon: Icon(Icons.arrow_upward)),
                    ButtonSegment(value: CategoryObservation.down, label: Text('Posible descenso'), icon: Icon(Icons.arrow_downward)),
                  ],
                  selected: {thisClub.observation},
                  onSelectionChanged: !_canEdit || _saving ? null : (v) => _save(s, observation: v.first),
                ),
              ),
            ],
          ),
        ],
        if (s.suggestion != null) ...[
          const SizedBox(height: 16),
          InfoBanner(
            icon: s.suggestion!.isUp ? Icons.trending_up : Icons.trending_down,
            text: 'Sugerencia: ${s.suggestion!.isUp ? 'subir' : 'bajar'} a ${s.suggestion!.to.name}. ${s.suggestion!.reasons.join('. ')}.',
            action: _canEdit
                ? FilledButton.tonal(
                    onPressed: _saving ? null : () => _save(s, categoryId: s.suggestion!.to.id),
                    child: Text('${s.suggestion!.isUp ? 'Subir' : 'Bajar'} a ${s.suggestion!.to.name}'),
                  )
                : null,
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 32,
          runSpacing: 12,
          children: [
            _votes(s.votes),
            if (s.clubRank != null || s.cityRank != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ranking${thisClub != null ? ' ${thisClub.name}' : ''}', style: text.titleSmall),
                  const SizedBox(height: 8),
                  if (s.clubRank != null) Text('Este club: #${s.clubRank!.position} · ${s.clubRank!.points} pts'),
                  if (s.cityRank != null) Text('${s.cityName ?? 'Ciudad'}: #${s.cityRank!.position} · ${s.cityRank!.points} pts'),
                ],
              ),
          ],
        ),
        if (s.history.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Historial', style: text.titleSmall),
          const SizedBox(height: 8),
          AdminDataTable(
            columns: const ['Fecha', 'Alcance', 'Cambio', 'Motivo', 'Por'],
            columnWidths: const {0: FixedColumnWidth(110), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(), 3: FlexColumnWidth(2), 4: FlexColumnWidth(1.2)},
            rows: [
              for (final h in s.history)
                [
                  Text(numericDate(h.createdAt)),
                  Text(h.scope == 'PERSONAL' ? 'Personal' : (h.clubName ?? 'Club')),
                  Text(h.reason == 'OBSERVATION' ? '—' : '${h.from ?? '—'} → ${h.to ?? '—'}'),
                  Text(h.reasonLabel),
                  Text(h.by ?? (h.scope == 'PERSONAL' ? 'El jugador' : '—')),
                ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _votes(VoteSummary v) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (v.total == 0) {
      return Text('Todavía no tiene votos de rivales.', style: TextStyle(color: scheme.onSurfaceVariant));
    }
    Widget bar(String label, int value) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13))),
              SizedBox(
                width: 140,
                child: LinearProgressIndicator(value: v.opinions == 0 ? 0 : value / v.opinions, borderRadius: BorderRadius.circular(4), minHeight: 8),
              ),
              const SizedBox(width: 8),
              Text('$value', style: const TextStyle(fontSize: 13)),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Votos de rivales · últimos 6 meses', style: text.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.thumb_up_outlined, size: 18, color: StatusTone.success(scheme).foreground),
            const SizedBox(width: 4),
            Text('${v.thumbsUp}'),
            const SizedBox(width: 16),
            Icon(Icons.thumb_down_outlined, size: 18, color: scheme.error),
            const SizedBox(width: 4),
            Text('${v.thumbsDown}'),
          ],
        ),
        const SizedBox(height: 8),
        bar('Más arriba', v.up),
        bar('Está bien', v.ok),
        bar('Más abajo', v.down),
      ],
    );
  }
}
