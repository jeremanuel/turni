import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/physical_partition_naming.dart';
import '../../../../../domain/entities/session.dart';
import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';
import '../../bloc/session_manager_state.dart';
import '../../utils/pending_request_ttl.dart';
import 'panel_common.dart';

/// Panel derecho del gestor cuando no hay un turno seleccionado: calendario
/// del mes, resumen del día (de la modalidad elegida) y solicitudes por
/// aprobar.
class DaySummaryPanel extends StatelessWidget {
  const DaySummaryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    PendingRequestTtl.ensureLoaded();

    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      buildWhen: (p, c) =>
          p.currentDate != c.currentDate || p.sessions != c.sessions || p.selectedClubPartition != c.selectedClubPartition,
      builder: (context, state) {
        final courts = state.selectedClubPartition?.physicalPartitions ?? const [];
        final courtIds = courts.map((c) => c.partitionPhysicalId).toSet();
        final sessions = state.sessions.where((s) => courtIds.contains(s.partitionPhysicalId)).toList();
        final pending = sessions.where((s) => s.isPending).sortedBy((s) => s.startTime);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthCalendar(selected: state.currentDate),
              const SizedBox(height: 16),
              _DaySummary(sessions: sessions),
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 16),
                _PendingList(
                  sessions: pending,
                  courtLabel: (s) {
                    final court = courts.firstWhereOrNull((c) => c.partitionPhysicalId == s.partitionPhysicalId);
                    return court == null
                        ? ''
                        : PhysicalPartitionNaming.labelFromPhysicalPartition(
                            court,
                            fallbackClubPartition: state.selectedClubPartition,
                          );
                  },
                ),
              ],
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Elegí un turno de la agenda para ver su detalle, cobrarlo o reservarlo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 16 / 12, color: scheme.outline),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthCalendar extends StatefulWidget {
  const _MonthCalendar({required this.selected});

  final DateTime selected;

  @override
  State<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<_MonthCalendar> {
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);

  @override
  void didUpdateWidget(covariant _MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameMonth(oldWidget.selected, widget.selected)) {
      _month = DateTime(widget.selected.year, widget.selected.month);
    }
  }

  void _shift(int months) => setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = DateFormat('MMMM yyyy', 'es').format(_month);
    final leading = _month.weekday - 1; // lunes primero
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final now = DateTime.now();

    final navStyle = IconButton.styleFrom(
      foregroundColor: scheme.onSurfaceVariant,
      minimumSize: const Size(32, 32),
      fixedSize: const Size(32, 32),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );

    final cells = <Widget>[
      for (final w in const ['L', 'M', 'X', 'J', 'V', 'S', 'D'])
        SizedBox(
          height: 28,
          child: Center(child: Text(w, style: TextStyle(fontSize: 12, color: scheme.outline))),
        ),
      for (var i = 0; i < leading; i++) const SizedBox(height: 32),
      for (var d = 1; d <= days; d++)
        _DayCell(
          day: DateTime(_month.year, _month.month, d),
          selected: DateUtils.isSameDay(widget.selected, DateTime(_month.year, _month.month, d)),
          today: DateUtils.isSameDay(now, DateTime(_month.year, _month.month, d)),
        ),
    ];

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title[0].toUpperCase() + title.substring(1),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: scheme.onSurface),
                ),
              ),
              IconButton(
                tooltip: 'Mes anterior',
                style: navStyle,
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left, size: 18),
              ),
              IconButton(
                tooltip: 'Mes siguiente',
                style: navStyle,
                onPressed: () => _shift(1),
                icon: const Icon(Icons.chevron_right, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var row = 0; row * 7 < cells.length; row++) ...[
            if (row > 1) const SizedBox(height: 2),
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: row * 7 + col < cells.length ? cells[row * 7 + col] : const SizedBox(),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.selected, required this.today});

  final DateTime day;
  final bool selected;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Material(
        color: selected ? scheme.primary : Colors.transparent,
        shape: CircleBorder(
          side: today && !selected ? BorderSide(color: scheme.primary) : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.read<SessionManagerBloc>().add(SessionChangeDateEvent(day)),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected
                      ? scheme.onPrimary
                      : today
                          ? scheme.primary
                          : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.sessions});

  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reserved = sessions.where((s) => s.isConfirmed).toList();
    final free = sessions.where((s) => s.isFree).length;
    final pending = sessions.where((s) => s.isPending).length;
    final occupancy = sessions.isEmpty ? 0 : ((reserved.length + pending) * 100 / sessions.length).round();
    final charged = reserved.fold<double>(0, (t, s) => t + s.totalPayedPrice);
    final total = reserved.fold<double>(0, (t, s) => t + s.totalPrice);
    final ratio = total <= 0 ? 0.0 : (charged / total).clamp(0.0, 1.0);

    Widget tile(String label, String value, [Color? color]) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: color ?? scheme.onSurface)),
            ],
          ),
        );

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Resumen del día', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: scheme.onSurface)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: tile('Reservados', '${reserved.length}', scheme.primary)),
              const SizedBox(width: 8),
              Expanded(child: tile('Libres', '$free')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: tile('Por aprobar', '$pending', scheme.tertiary)),
              const SizedBox(width: 8),
              Expanded(child: tile('Ocupación', '$occupancy %')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Cobrado', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
              const Spacer(),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: panelPrice(charged), style: TextStyle(fontWeight: FontWeight.w500, color: scheme.onSurface)),
                    TextSpan(text: ' de ${panelPrice(total)}', style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: scheme.surfaceContainerHighest)),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  const _PendingList({required this.sessions, required this.courtLabel});

  final List<Session> sessions;
  final String Function(Session) courtLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final buttonStyle = IconButton.styleFrom(
      fixedSize: const Size(40, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );

    return PanelCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: ValueListenableBuilder<int?>(
        valueListenable: PendingRequestTtl.minutes,
        builder: (context, _, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Por aprobar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: scheme.onSurface)),
            for (final s in sessions) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  PanelAvatar(
                    name: s.client?.person?.fullName ?? '',
                    size: 32,
                    background: scheme.tertiary,
                    foreground: scheme.onTertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.client?.person?.fullName ?? 'Cliente',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: scheme.onSurface),
                        ),
                        Text(
                          [
                            panelHm(s.startTime),
                            courtLabel(s),
                            PendingRequestTtl.expiresLabel(s.createdAt),
                          ].whereType<String>().where((t) => t.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Aceptar solicitud de ${s.client?.person?.fullName ?? 'cliente'}',
                    style: buttonStyle.copyWith(foregroundColor: WidgetStatePropertyAll(scheme.tertiary)),
                    onPressed: () => context.read<SessionManagerBloc>().add(AcceptSessionRequest(s.sessionId)),
                    icon: const Icon(Icons.check, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Rechazar solicitud de ${s.client?.person?.fullName ?? 'cliente'}',
                    style: buttonStyle.copyWith(foregroundColor: WidgetStatePropertyAll(scheme.onSurfaceVariant)),
                    onPressed: () => context.read<SessionManagerBloc>().add(RejectSessionRequest(s.sessionId)),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
