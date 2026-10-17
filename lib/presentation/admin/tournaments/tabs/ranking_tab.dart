import '../../../../core/utils/either.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/app_routes.dart';
import '../../../../core/config/service_locator.dart';
import '../../../../domain/entities/tournament/tournament.dart';
import '../../../../domain/repositories/tournament_repository.dart';
import '../../club_config/widgets/admin_data_table.dart';
import '../widgets/tournament_ui.dart';

/// Ranking del club o de su ciudad (últimos 12 meses), por deporte, categoría
/// y rama, con las sugerencias de cambio de categoría.
class RankingTab extends StatefulWidget {
  const RankingTab({super.key});

  @override
  State<RankingTab> createState() => _RankingTabState();
}

/// Valor del filtro de categoría para "torneos sin categoría" (libre o suma).
const _noCategory = -1;

class _RankingTabState extends State<RankingTab> {
  final _repository = sl<TournamentRepository>();

  List<CatalogSport>? _sports;
  int? _sportId;
  int? _categoryId;
  TournamentBranch? _branch;
  bool _city = false;

  RankingResult? _result;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  CatalogSport? get _sport => _sports?.where((s) => s.clubTypeId == _sportId).firstOrNull;

  Future<void> _loadCatalog() async {
    setState(() => _error = null);
    final result = await _repository.getCatalog();
    if (!mounted) return;
    result.when(
      left: (failure) => setState(() => _error = failure.message),
      right: (sports) {
        final withCategories = sports.where((s) => s.categories.isNotEmpty).toList();
        setState(() {
          _sports = withCategories;
          final first = withCategories.firstOrNull;
          _sportId = first?.clubTypeId;
          _categoryId = first?.categories.firstOrNull?.id;
        });
        _load();
      },
    );
  }

  Future<void> _load() async {
    final sportId = _sportId;
    if (sportId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getRanking(
      clubTypeId: sportId,
      categoryId: _categoryId == _noCategory ? null : _categoryId,
      branch: _branch,
      city: _city,
    );
    if (!mounted) return;
    result.when(
      left: (failure) => setState(() {
        _loading = false;
        _result = null;
        _error = failure.message;
      }),
      right: (r) => setState(() {
        _loading = false;
        _result = r;
      }),
    );
  }

  void _openClient(int clientId) {
    context.pushNamed(AppRoutes.CLIENT_ROUTE.name, pathParameters: {'clientId': '$clientId'});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final sports = _sports;
    if (sports == null) {
      return _error != null ? LoadError(message: _error!, onRetry: _loadCatalog) : const Center(child: CircularProgressIndicator());
    }
    if (sports.isEmpty) {
      return const Center(child: Text('El club no tiene deportes con categorías.'));
    }
    final sport = _sport!;
    final result = _result;

    final filters = Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<int>(
            initialValue: _sportId,
            decoration: const InputDecoration(labelText: 'Deporte'),
            items: [for (final s in sports) DropdownMenuItem(value: s.clubTypeId, child: Text(s.name))],
            onChanged: (v) {
              setState(() {
                _sportId = v;
                _categoryId = _sport?.categories.firstOrNull?.id;
              });
              _load();
            },
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int>(
            key: ValueKey('cat-$_sportId'),
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: [
              for (final c in sport.categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
              const DropdownMenuItem(value: _noCategory, child: Text('Libre / suma')),
            ],
            onChanged: (v) {
              setState(() => _categoryId = v);
              _load();
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<TournamentBranch?>(
            initialValue: _branch,
            decoration: const InputDecoration(labelText: 'Rama'),
            items: [
              const DropdownMenuItem(child: Text('Todas')),
              for (final b in TournamentBranch.values) DropdownMenuItem(value: b, child: Text(b.label)),
            ],
            onChanged: (v) {
              setState(() => _branch = v);
              _load();
            },
          ),
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Club'), icon: Icon(Icons.storefront_outlined)),
            ButtonSegment(value: true, label: Text('Ciudad'), icon: Icon(Icons.location_city_outlined)),
          ],
          selected: {_city},
          onSelectionChanged: (v) {
            setState(() => _city = v.first);
            _load();
          },
        ),
      ],
    );

    final table = _loading
        ? const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
        : _error != null
            ? Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: TextStyle(color: scheme.error)))
            : result == null || result.rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Todavía no hay puntos en este ranking. Se suman cuando termina un torneo.',
                      style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  )
                : AdminDataTable(
                    // Tabla de posiciones: se compara entre filas, queda como tabla.
                    mobileLayout: AdminTableMobileLayout.scroll,
                    columns: [
                      '#',
                      'Jugador',
                      'Categoría',
                      if (result.scope == 'city') 'Club' else 'Torneos',
                      'Puntos',
                    ],
                    columnWidths: const {0: FixedColumnWidth(56), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.6), 3: FlexColumnWidth(1.4), 4: FixedColumnWidth(90)},
                    rows: [
                      for (final r in result.rows)
                        [
                          Text('${r.position}', style: TextStyle(fontWeight: FontWeight.w700, color: r.position <= 3 ? scheme.primary : scheme.onSurfaceVariant)),
                          InkWell(onTap: () => _openClient(r.clientId), child: Text(r.fullName, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w500))),
                          Row(
                            children: [
                              Text(r.category?.name ?? '—'),
                              if (r.category != null) ...[
                                const SizedBox(width: 6),
                                StatusBadge(
                                  label: r.category!.isClub ? 'Del club' : 'Personal',
                                  tone: r.category!.isClub ? StatusTone.success(scheme) : StatusTone.neutral(scheme),
                                ),
                              ],
                              if (r.observation != CategoryObservation.none) ...[
                                const SizedBox(width: 6),
                                Icon(r.observation == CategoryObservation.up ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: StatusTone.warning(scheme).foreground),
                              ],
                            ],
                          ),
                          Text(result.scope == 'city' ? r.clubName : '${r.tournaments}'),
                          Text('${r.points}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                    ],
                  );

    final aside = result == null
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (result.categorizes)
                SectionCard(
                  title: 'Sugerencias de categoría',
                  subtitle: 'Por títulos en su categoría y votos de los rivales.',
                  child: result.suggestions.isEmpty
                      ? Text('No hay sugerencias por ahora.', style: TextStyle(color: scheme.onSurfaceVariant))
                      : Column(
                          children: [
                            for (final s in result.suggestions)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(s.suggestion.isUp ? Icons.trending_up : Icons.trending_down, color: scheme.primary),
                                title: Text(s.name),
                                subtitle: Text('${s.from} → ${s.suggestion.to.name}\n${s.suggestion.reasons.join(' · ')}'),
                                isThreeLine: true,
                                trailing: OutlinedButton(onPressed: () => _openClient(s.clientId), child: const Text('Ver ficha')),
                              ),
                          ],
                        ),
                ),
              if (result.categorizes && result.withoutClubCategory > 0) ...[
                const SizedBox(height: 16),
                InfoBanner(
                  icon: Icons.help_outline,
                  text: '${result.withoutClubCategory} jugadores del ranking juegan con su categoría personal. Asignales la del club desde su ficha.',
                ),
              ],
              if (!result.categorizes) ...[
                InfoBanner(text: 'El club no categoriza ${sport.name}: el ranking muestra la categoría personal de cada jugador. Activalo en la pestaña Categorías.'),
              ],
            ],
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 1100;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _city && result?.city != null ? 'Ranking de ${result!.city!.name} · últimos 12 meses' : 'Ranking del club · últimos 12 meses',
              style: text.titleMedium,
            ),
            const SizedBox(height: 16),
            filters,
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: table),
                  const SizedBox(width: 24),
                  SizedBox(width: 360, child: aside),
                ],
              )
            else ...[
              table,
              const SizedBox(height: 16),
              aside,
            ],
          ],
        );
      },
    );
  }
}
