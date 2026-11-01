import '../../../core/utils/either.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/permissions.dart';
import '../../../domain/entities/tournament/tournament.dart';
import '../../../domain/repositories/tournament_repository.dart';
import '../club_config/widgets/admin_data_table.dart';
import 'tabs/category_settings_tab.dart';
import 'tabs/ranking_tab.dart';
import '../../../core/utils/responsive_builder.dart';
import 'widgets/tournament_ui.dart';
import '../../../core/services/data_changes.dart';
import '../../../core/presentation/components/onboarding/tour_anchor.dart';

/// Torneos del club: el listado, el ranking (club y ciudad) y qué deportes
/// categoriza el club. Cada pestaña aparece según el rol.
class TournamentsPage extends StatelessWidget {
  const TournamentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = <(String, String, Widget)>[
      ('Torneos', 'tournaments.tab.list', const _TournamentsTab()),
      ('Ranking', 'tournaments.tab.ranking', const RankingTab()),
      if (Permissions.can(Permissions.TORNEOS_EDITAR)) ('Categorías', 'tournaments.tab.categories', const CategorySettingsTab()),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        appBar: AppBar(
          title: const Text('Torneos'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (final (i, (label, anchor, _)) in tabs.indexed) TourAnchor(id: anchor, onActivate: TourAnchor.selectTab(i), child: Tab(text: label)),
            ],
          ),
        ),
        body: TabBarView(children: [for (final (_, _, tab) in tabs) tab]),
      ),
    );
  }
}

class _TournamentsTab extends StatefulWidget {
  const _TournamentsTab();

  @override
  State<_TournamentsTab> createState() => _TournamentsTabState();
}

class _TournamentsTabState extends State<_TournamentsTab> with ReloadOnDataChange {
  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.tournaments};

  @override
  void onDataChanged(DataChange change) => _load();

  final _repository = sl<TournamentRepository>();

  List<Tournament>? _tournaments;
  String? _error;
  TournamentStatus? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final result = await _repository.getTournaments();
    if (!mounted) return;
    result.when(
      left: (failure) => setState(() => _error = failure.message),
      right: (list) => setState(() => _tournaments = list),
    );
  }

  Future<void> _open(Tournament t) async {
    await context.pushNamed(AppRoutes.TOURNAMENT_DETAIL_ROUTE.name, pathParameters: {'tournamentId': '${t.id}'});
    _load();
  }

  Future<void> _create() async {
    await context.pushNamed(AppRoutes.TOURNAMENT_NEW_ROUTE.name);
    _load();
  }

  static const _columns = ['Torneo', 'Modalidad', 'Categoría', 'Formato', 'Equipos', 'Entrada', 'Estado'];
  static const _widths = {
    0: FlexColumnWidth(2.2),
    1: FlexColumnWidth(1.3),
    2: FlexColumnWidth(1.3),
    3: FlexColumnWidth(1.4),
    4: FlexColumnWidth(),
    5: FlexColumnWidth(1.2),
    6: FlexColumnWidth(1.3),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (_error != null) return LoadError(message: _error!, onRetry: _load, center: true);
    // Primera carga: el encabezado real y la tabla como esqueleto.
    final loading = _tournaments == null;
    final all = _tournaments ?? const [];

    final shown = _filter == null ? all : all.where((t) => t.status == _filter).toList();
    final counts = {for (final s in TournamentStatus.values) s: all.where((t) => t.status == s).length};

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(ResponsiveBuilder.isMobile(context) ? 16 : 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Armá torneos, seguí las inscripciones y cargá los resultados.',
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              if (Permissions.can(Permissions.TORNEOS_EDITAR))
                TourAnchor(
                  id: 'tournaments.new',
                  child: FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Nuevo torneo')),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!loading) TourAnchor(id: 'tournaments.filters', child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text('Todos · ${all.length}'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final s in [
                TournamentStatus.draft,
                TournamentStatus.open,
                TournamentStatus.closed,
                TournamentStatus.inProgress,
                TournamentStatus.finished,
              ])
                if (counts[s]! > 0)
                  FilterChip(
                    label: Text('${s.label} · ${counts[s]}'),
                    selected: _filter == s,
                    onSelected: (_) => setState(() => _filter = _filter == s ? null : s),
                  ),
            ],
          )),
          const SizedBox(height: 16),
          if (loading)
            const AdminTableSkeleton(columns: _columns, columnWidths: _widths)
          else if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.emoji_events_outlined, size: 48, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(all.isEmpty ? 'Todavía no armaste ningún torneo.' : 'No hay torneos con ese estado.', style: text.bodyLarge),
                ],
              ),
            )
          else
            TourAnchor(id: 'tournaments.table', child: AdminDataTable(
              columns: _columns,
              columnWidths: _widths,
              rows: [
                for (final t in shown)
                  [
                    // Las guías abren el primer torneo, o uno en juego.
                    TourAnchor(
                      id: 'tournaments.row',
                      onActivate: (_) => _open(t),
                      child: TourAnchor(
                        id: t.status == TournamentStatus.inProgress ? 'tournaments.row.playing' : 'tournaments.row.other',
                        onActivate: (_) => _open(t),
                        child: InkWell(
                          onTap: () => _open(t),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.name, style: TextStyle(fontWeight: FontWeight.w500, color: scheme.primary)),
                              Text(datesRange(t.startsAt, t.endsAt), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Text(t.modalityLabel),
                    Text(t.categoryLabel),
                    Text(t.format.label),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${t.teamsCount} / ${t.maxTeams}'),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: LinearProgressIndicator(
                            value: t.maxTeams == 0 ? 0 : (t.teamsCount / t.maxTeams).clamp(0, 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    Text(feeLabel(t)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusBadge(label: t.status.label, tone: StatusTone.ofTournament(scheme, t.status)),
                    ),
                  ],
              ],
            )),
        ],
      ),
    );
  }
}
