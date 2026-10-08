import 'package:flutter/material.dart';

import '../../../../domain/entities/club_map/club_map.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/repository_response.dart';
import '../../../../domain/entities/club_map/court_occupancy.dart';
import '../../../../domain/entities/club_map/court_usage.dart';
import '../../../../domain/entities/session.dart';
import 'court_tile.dart';
import 'plan_canvas.dart';

/// Qué muestra el plano: la ocupación de ahora o el uso de un período.
enum ClubMapMode { live, usage }

/// Vista del mapa: el plano del club en modo lectura, con cada cancha libre u
/// ocupada ahora (o pintada según cuánto se usó), y el detalle de la cancha
/// que se toca.
class ClubMapOverview extends StatefulWidget {
  final ClubMapView view;

  /// Ocupación de cada cancha ahora. `null`: todavía no se cargaron los turnos.
  final Map<int, CourtOccupancy>? occupancy;

  /// Cuándo se calculó [occupancy].
  final DateTime? occupancyAt;
  final VoidCallback onEdit;
  final VoidCallback onAddSports;
  final VoidCallback onSeeSessions;
  final ValueChanged<Session> onOpenSession;

  /// Uso de cada cancha en los últimos N días. `null`: no se ofrece la vista.
  final Future<RepositoryResponse<CourtUsageView>> Function(int days)? loadUsage;

  const ClubMapOverview({
    super.key,
    required this.view,
    this.occupancy,
    this.occupancyAt,
    required this.onEdit,
    required this.onAddSports,
    required this.onSeeSessions,
    required this.onOpenSession,
    this.loadUsage,
  });

  /// Períodos que se pueden elegir en la vista de uso, en días.
  static const usagePeriods = [7, 30, 90];

  @override
  State<ClubMapOverview> createState() => _ClubMapOverviewState();
}

class _ClubMapOverviewState extends State<ClubMapOverview> {
  int? _selectedCourtId;
  int? _selectedSpace;

  ClubMapMode _mode = ClubMapMode.live;
  int _usageDays = 30;
  CourtUsageView? _usage;
  String? _usageError;
  bool _loadingUsage = false;

  bool get _showUsage => _mode == ClubMapMode.usage;

  Future<void> _loadUsage() async {
    final load = widget.loadUsage;
    if (load == null) return;
    final days = _usageDays;
    setState(() {
      _loadingUsage = true;
      _usageError = null;
    });
    final result = await load(days);
    if (!mounted || days != _usageDays) return;
    result.when(
      left: (failure) => setState(() {
        _loadingUsage = false;
        _usageError = failure.message;
      }),
      right: (usage) => setState(() {
        _loadingUsage = false;
        _usage = usage;
      }),
    );
  }

  void _setMode(ClubMapMode mode) {
    setState(() => _mode = mode);
    if (mode == ClubMapMode.usage && _usage == null && !_loadingUsage) _loadUsage();
  }

  void _setUsageDays(int days) {
    setState(() {
      _usageDays = days;
      _usage = null;
    });
    _loadUsage();
  }

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
                    Text('Así están ubicadas las canchas en el club y cuáles están ocupadas ahora.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                if (map != null) FilledButton.icon(onPressed: widget.onEdit, icon: const Icon(Icons.edit_outlined), label: const Text('Editar plano')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (map != null && missing.isNotEmpty) ...[_MissingBanner(sports: missing, onAdd: widget.onAddSports), const SizedBox(height: 20)],
          if (map != null && widget.loadUsage != null) ...[_buildModeBar(context), const SizedBox(height: 16)],
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
    final selectedSpace = _selectedSpace == null || _selectedSpace! >= map.spaces.length ? null : map.spaces[_selectedSpace!];

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
                spaces: map.spaces,
                scale: scale,
                selectedCourtId: _selectedCourtId,
                selectedSpaceIndex: _selectedSpace,
                liveStatus: _showUsage ? null : _liveStatus(map),
                usage: _showUsage ? _usage : null,
                onCourtTap: (id) => setState(() {
                  _selectedCourtId = id;
                  _selectedSpace = null;
                }),
                onSpaceTap: (index) => setState(() {
                  _selectedSpace = index;
                  _selectedCourtId = null;
                }),
                onBackgroundTap: () => setState(() {
                  _selectedCourtId = null;
                  _selectedSpace = null;
                }),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_showUsage) ...[
                  if (_usage != null) _UsageLegend(usage: _usage!),
                ] else ...[
                  ..._sportLegend(context, map),
                  if (widget.occupancy != null) _LiveLegend(at: widget.occupancyAt),
                ],
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
      child: selectedSpace != null
          ? _SpaceDetail(space: selectedSpace, name: widget.view.spaceName(selectedSpace), typeName: widget.view.spaceTypeName(selectedSpace.type))
          : selected == null
          ? Text('Tocá una cancha del plano para ver sus datos.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
          : _CourtDetail(
              partition: selected.partition,
              court: selected.court,
              occupancy: _showUsage || widget.occupancy == null ? null : (widget.occupancy![selected.court.id] ?? CourtOccupancy.empty),
              usage: _showUsage && _usage != null ? (court: _usage!.byCourt[selected.court.id], days: _usageDays) : null,
              onSeeSessions: widget.onSeeSessions,
              onOpenSession: widget.onOpenSession,
            ),
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

  Widget _buildModeBar(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<ClubMapMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ClubMapMode.live, icon: Icon(Icons.schedule), label: Text('Ocupación ahora')),
            ButtonSegment(value: ClubMapMode.usage, icon: Icon(Icons.bar_chart), label: Text('Uso por cancha')),
          ],
          selected: {_mode},
          onSelectionChanged: (modes) => _setMode(modes.first),
        ),
        if (_showUsage)
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [for (final days in ClubMapOverview.usagePeriods) ButtonSegment(value: days, label: Text('Últimos $days días'))],
            selected: {_usageDays},
            onSelectionChanged: (days) => _setUsageDays(days.first),
          ),
        if (_showUsage && _loadingUsage) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        if (_showUsage && _usageError != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No se pudo cargar el uso: $_usageError', style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(width: 8),
              TextButton(onPressed: _loadUsage, child: const Text('Reintentar')),
            ],
          ),
      ],
    );
  }

  Map<int, CourtLiveStatus>? _liveStatus(ClubMapLayout map) {
    final occupancy = widget.occupancy;
    if (occupancy == null) return null;
    return {
      for (final e in map.elements) e.courtId: (occupancy[e.courtId]?.isOccupied ?? false) ? CourtLiveStatus.occupied : CourtLiveStatus.free,
    };
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
  final CourtOccupancy? occupancy;

  /// Vista de uso: el uso de la cancha (null si no tuvo turnos) y los días del período.
  final ({CourtUsage? court, int days})? usage;
  final VoidCallback onSeeSessions;
  final ValueChanged<Session> onOpenSession;

  const _CourtDetail({
    required this.partition,
    required this.court,
    required this.occupancy,
    this.usage,
    required this.onSeeSessions,
    required this.onOpenSession,
  });

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
        if (occupancy != null) ...[const SizedBox(height: 16), _NowSection(occupancy: occupancy!)],
        if (usage != null) ...[const SizedBox(height: 16), _UsageSection(usage: usage!.court, days: usage!.days)],
        const SizedBox(height: 16),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            SizedBox(width: 110, child: field('Cubierta', court.isCover ? 'Techada' : 'Descubierta')),
            SizedBox(width: 110, child: field('Jugadores', court.maxPlayers?.toString() ?? '-')),
            SizedBox(width: 110, child: field('Turno', court.defaultSessionDuration != null ? '${court.defaultSessionDuration} min' : '-')),
            SizedBox(width: 110, child: field(court.ownSize != null ? 'Medidas (propias)' : 'Medidas', (court.ownSize ?? partition.courtSize).label)),
          ],
        ),
        const SizedBox(height: 16),
        if (occupancy?.sessionToOpen case final session?) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => onOpenSession(session),
              child: Text(_openLabel(occupancy!)),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(onPressed: onSeeSessions, child: const Text('Ver los turnos')),
        ),
      ],
    );
  }
}

/// Uso de la cancha en el período, en el detalle.
class _UsageSection extends StatelessWidget {
  final CourtUsage? usage;
  final int days;

  const _UsageSection({required this.usage, required this.days});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final u = usage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Uso en los últimos $days días', style: muted),
        const SizedBox(height: 2),
        if (u == null || u.usage == null)
          Text('Sin turnos cargados en el período', style: theme.textTheme.bodyMedium)
        else ...[
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: UsageScale.colorOf(u.usage), borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 8),
              Text(u.percentLabel!, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 2),
          Text('${formatHours(u.reservedMinutes)} reservadas de ${formatHours(u.offeredMinutes)} cargadas', style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }
}

/// Referencia de la escala de uso y el período.
class _UsageLegend extends StatelessWidget {
  final CourtUsageView usage;

  const _UsageLegend({required this.usage});

  String _day(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(label, style: textStyle),
          ],
        );

    // `to` es el inicio del día siguiente al último, o "ahora".
    final last = usage.to.subtract(const Duration(milliseconds: 1));

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Turnos reservados:', style: textStyle),
        for (var i = 0; i < UsageScale.steps.length; i++) item(UsageScale.steps[i], UsageScale.labels[i]),
        item(UsageScale.none, 'Sin turnos'),
        Text('Del ${_day(usage.from)} al ${_day(last)}', style: textStyle),
      ],
    );
  }
}

/// Detalle de un espacio que no es cancha (entrada, bar...).
class _SpaceDetail extends StatelessWidget {
  final ClubMapSpace space;
  final String name;
  final String typeName;

  const _SpaceDetail({required this.space, required this.name, required this.typeName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(typeName.toUpperCase(), style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Text('Tamaño', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text('${space.widthM} × ${space.heightM} m', style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

String _openLabel(CourtOccupancy occupancy) {
  if (occupancy.current != null) return 'Abrir el turno en curso';
  if (occupancy.freeNow != null) return 'Reservar ahora';
  return 'Abrir el próximo turno';
}

String _hhmm(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String _whoText(Session session) => session.isPending ? 'Solicitud pendiente' : (session.client?.person?.fullName.trim() ?? 'Cliente');

/// "Ahora" en el detalle: si se está jugando (quién y hasta qué hora), si hay
/// un turno libre para reservar en el momento, y el próximo turno del día.
class _NowSection extends StatelessWidget {
  final CourtOccupancy occupancy;

  const _NowSection({required this.occupancy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final status = occupancy.isOccupied ? CourtLiveStatus.occupied : CourtLiveStatus.free;
    final current = occupancy.current;
    final freeNow = occupancy.freeNow;
    final next = occupancy.next;

    final String nowText;
    if (current != null) {
      nowText = '${_whoText(current)} · hasta las ${_hhmm(current.endTime as DateTime)}';
    } else if (freeNow != null) {
      nowText = 'Turno libre hasta las ${_hhmm(freeNow.endTime as DateTime)}';
    } else {
      nowText = 'No hay un turno cargado ahora';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(status.label, style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(nowText, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        Text('Próximo turno', style: muted),
        const SizedBox(height: 2),
        Text(
          next == null ? 'No hay más turnos reservados hoy' : '${_hhmm(next.startTime)} · ${_whoText(next)}',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Referencia de Libre / Ocupada y la hora de la última actualización.
class _LiveLegend extends StatelessWidget {
  final DateTime? at;

  const _LiveLegend({required this.at});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    Widget item(CourtLiveStatus status) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(status.label, style: textStyle),
          ],
        );

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        item(CourtLiveStatus.free),
        item(CourtLiveStatus.occupied),
        if (at != null) Text('Actualizado ${_hhmm(at!)}', style: textStyle),
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
