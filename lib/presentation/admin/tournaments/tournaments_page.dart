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
import 'widgets/tournament_ui.dart';

/// Torneos del club: el listado, el ranking (club y ciudad) y qué deportes
/// categoriza el club. Cada pestaña aparece según el rol.
class TournamentsPage extends StatelessWidget {
  const TournamentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = <(String, Widget)>[
      ('Torneos', const _TournamentsTab()),
      ('Ranking', const RankingTab()),
      if (Permissions.can(Permissions.TORNEOS_EDITAR)) ('Categorías', const CategorySettingsTab()),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        appBar: AppBar(
          title: const Text('Torneos'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final (label, _) in tabs) Tab(text: label)],
          ),
        ),
        body: TabBarView(children: [for (final (_, tab) in tabs) tab]),
      ),
    );
  }
}

class _TournamentsTab extends StatefulWidget {
  const _TournamentsTab();

  @override
  State<_TournamentsTab> createState() => _TournamentsTabState();
}

class _TournamentsTabState extends State<_TournamentsTab> {
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (_error != null) return LoadError(message: _error!, onRetry: _load);
    final all = _tournaments;
    if (all == null) return const Center(child: CircularProgressIndicator());

    final shown = _filter == null ? all : all.where((t) => t.status == _filter).toList();
    final counts = {for (final s in TournamentStatus.values) s: all.where((t) => t.status == s).length};

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
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
                FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Nuevo torneo')),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
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
          ),
          const SizedBox(height: 16),
          if (shown.isEmpty)
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
            AdminDataTable(
              columns: const ['Torneo', 'Modalidad', 'Categoría', 'Formato', 'Equipos', 'Entrada', 'Estado'],
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1.3),
                2: FlexColumnWidth(1.3),
                3: FlexColumnWidth(1.4),
                4: FlexColumnWidth(),
                5: FlexColumnWidth(1.2),
                6: FlexColumnWidth(1.3),
              },
              rows: [
                for (final t in shown)
                  [
                    InkWell(
                      onTap: () => _open(t),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name, style: TextStyle(fontWeight: FontWeight.w500, color: scheme.primary)),
                          Text(datesRange(t.startsAt, t.endsAt), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                        ],
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
            ),
        ],
      ),
    );
  }
}
