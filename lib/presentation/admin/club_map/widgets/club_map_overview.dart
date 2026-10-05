import 'package:flutter/material.dart';

import '../../../../domain/entities/club_map/club_map.dart';
import 'court_tile.dart';
import 'plan_canvas.dart';

/// Vista del mapa: el plano del club en modo lectura y el detalle de la
/// cancha que se toca.
class ClubMapOverview extends StatefulWidget {
  final ClubMapView view;
  final VoidCallback onEdit;
  final VoidCallback onAddSports;
  final VoidCallback onSeeSessions;

  const ClubMapOverview({super.key, required this.view, required this.onEdit, required this.onAddSports, required this.onSeeSessions});

  @override
  State<ClubMapOverview> createState() => _ClubMapOverviewState();
}

class _ClubMapOverviewState extends State<ClubMapOverview> {
  int? _selectedCourtId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = widget.view.map;
    final missing = _missingSports();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Mapa del club', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text('Así están ubicadas las canchas en el club, todas en un mismo plano.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                if (map != null) FilledButton.icon(onPressed: widget.onEdit, icon: const Icon(Icons.edit_outlined), label: const Text('Editar plano')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (map != null && missing.isNotEmpty) ...[_MissingBanner(sports: missing, onAdd: widget.onAddSports), const SizedBox(height: 20)],
          if (map == null) _EmptyState(hasCourts: _hasCourts(), onDesign: widget.onAddSports) else _buildPlan(context, map),
        ],
      ),
    );
  }

  bool _hasCourts() => widget.view.partitions.any((p) => p.courts.isNotEmpty);

  List<String> _missingSports() {
    final map = widget.view.map;
    if (map == null) return const [];
    final inMap = widget.view.partitionIdsInMap(map.elements);
    return [
      for (final p in widget.view.partitions)
        if (p.courts.isNotEmpty && !inMap.contains(p.id)) p.sport,
    ];
  }

  Widget _buildPlan(BuildContext context, ClubMapLayout map) {
    final theme = Theme.of(context);
    final selected = _selectedCourtId == null ? null : widget.view.findCourt(_selectedCourtId!);

    final plan = LayoutBuilder(
      builder: (context, constraints) {
        // Que el plano use el alto de la pantalla (menos el encabezado), no un tope fijo.
        final maxHeight = (MediaQuery.sizeOf(context).height - 300).clamp(360.0, double.infinity);
        final scale = planScale(map.widthM, map.heightM, constraints.maxWidth - 34, maxHeight);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PlanCanvas(
                view: widget.view,
                widthM: map.widthM,
                heightM: map.heightM,
                elements: map.elements,
                scale: scale,
                selectedCourtId: _selectedCourtId,
                onCourtTap: (id) => setState(() => _selectedCourtId = id),
                onBackgroundTap: () => setState(() => _selectedCourtId = null),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ..._sportLegend(context, map),
                PlanScaleLegend(scale: scale, widthM: map.widthM, heightM: map.heightM),
              ],
            ),
          ],
        );
      },
    );

    final detail = Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: selected == null
          ? Text('Tocá una cancha del plano para ver sus datos.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
          : _CourtDetail(partition: selected.partition, court: selected.court, onSeeSessions: widget.onSeeSessions),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [plan, const SizedBox(height: 20), detail]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: plan),
            const SizedBox(width: 24),
            detail,
          ],
        );
      },
    );
  }

  List<Widget> _sportLegend(BuildContext context, ClubMapLayout map) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final counts = <int, int>{};
    for (final e in map.elements) {
      final found = widget.view.findCourt(e.courtId);
      if (found != null) counts[found.partition.id] = (counts[found.partition.id] ?? 0) + 1;
    }

    return [
      for (final p in widget.view.partitions)
        if (counts.containsKey(p.id))
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: SportStyle.of(p.clubTypeId).fill, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 6),
              Text('${p.sport} · ${counts[p.id]} ${counts[p.id] == 1 ? 'cancha' : 'canchas'}', style: textStyle),
            ],
          ),
    ];
  }
}

class _CourtDetail extends StatelessWidget {
  final ClubMapPartition partition;
  final ClubMapCourt court;
  final VoidCallback onSeeSessions;

  const _CourtDetail({required this.partition, required this.court, required this.onSeeSessions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    Widget field(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(partition.sport.toUpperCase(), style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(court.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            SizedBox(width: 110, child: field('Cubierta', court.isCover ? 'Techada' : 'Descubierta')),
            SizedBox(width: 110, child: field('Jugadores', court.maxPlayers?.toString() ?? '-')),
            SizedBox(width: 110, child: field('Turno', court.defaultSessionDuration != null ? '${court.defaultSessionDuration} min' : '-')),
            SizedBox(width: 110, child: field('Medidas', partition.courtSize.label)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(onPressed: onSeeSessions, child: const Text('Ver los turnos')),
        ),
      ],
    );
  }
}

class _MissingBanner extends StatelessWidget {
  final List<String> sports;
  final VoidCallback onAdd;

  const _MissingBanner({required this.sports, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final names = sports.length == 1 ? sports.first : '${sports.sublist(0, sports.length - 1).join(', ')} y ${sports.last}';
    final text = sports.length == 1 ? '$names todavía no está en el plano.' : '$names todavía no están en el plano.';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: colors.onPrimaryContainer)),
          ),
          const SizedBox(width: 12),
          FilledButton(onPressed: onAdd, child: const Text('Sumar al plano')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasCourts;
  final VoidCallback onDesign;

  const _EmptyState({required this.hasCourts, required this.onDesign});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.map_outlined, size: 40, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text('El club todavía no tiene plano', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            hasCourts ? 'Ubicá las canchas en el plano para que el club y los jugadores vean dónde está cada una.' : 'Para armar el plano, primero cargá las canchas del club.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (hasCourts) ...[const SizedBox(height: 16), FilledButton(onPressed: onDesign, child: const Text('Diseñar el plano'))],
        ],
      ),
    );
  }
}
