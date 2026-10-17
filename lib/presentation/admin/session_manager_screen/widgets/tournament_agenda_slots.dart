import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/app_routes.dart';
import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../domain/entities/session.dart';
import '../../../../domain/entities/tournament/tournament.dart';
import '../../../../domain/repositories/tournament_repository.dart';
import '../../tournaments/widgets/tournament_ui.dart';

/// Partidos de torneo programados del día que muestra la agenda. Ocupan la
/// cancha aunque el turno figure libre (`tournament_session`, ver
/// turni_mono_be docs/feature/TORNEOS.md): la agenda marca esos turnos y la
/// app de clientes no los ofrece.
class TournamentAgendaSlots extends StatefulWidget {
  const TournamentAgendaSlots({super.key, required this.day, required this.child});

  final DateTime day;
  final Widget child;

  static List<TournamentAgendaSlot> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SlotsScope>()?.slots ?? const [];

  /// Partido que ocupa la cancha del turno, si hay.
  static TournamentAgendaSlot? blocking(BuildContext context, Session session) {
    final end = session.startTime.add(Duration(minutes: session.getDurationInMinutes()));
    return of(context)
        .where((s) => s.courtId == session.partitionPhysicalId && s.start.isBefore(end) && s.end.isAfter(session.startTime))
        .firstOrNull;
  }

  @override
  State<TournamentAgendaSlots> createState() => _TournamentAgendaSlotsState();
}

class _TournamentAgendaSlotsState extends State<TournamentAgendaSlots> {
  List<TournamentAgendaSlot> _slots = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TournamentAgendaSlots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.day, widget.day)) _load();
  }

  Future<void> _load() async {
    final from = DateTime(widget.day.year, widget.day.month, widget.day.day);
    final result = await sl<TournamentRepository>().getAgendaSlots(from, from.add(const Duration(days: 1)));
    if (!mounted) return;
    // Si falla (ej. sin permiso), la agenda se ve igual que antes.
    result.when(left: (_) {}, right: (slots) => setState(() => _slots = slots));
  }

  @override
  Widget build(BuildContext context) => _SlotsScope(slots: _slots, child: widget.child);
}

class _SlotsScope extends InheritedWidget {
  const _SlotsScope({required this.slots, required super.child});

  final List<TournamentAgendaSlot> slots;

  @override
  bool updateShouldNotify(_SlotsScope oldWidget) => oldWidget.slots != slots;
}

/// Franja con los partidos de torneo del día, arriba de la agenda.
class TournamentAgendaBanner extends StatelessWidget {
  const TournamentAgendaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final slots = TournamentAgendaSlots.of(context);
    if (slots.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final byTournament = <int, List<TournamentAgendaSlot>>{};
    for (final s in slots) {
      byTournament.putIfAbsent(s.tournamentId, () => []).add(s);
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.emoji_events_outlined, size: 18, color: scheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                for (final group in byTournament.values)
                  '${group.first.tournamentName}: ${group.map((s) => '${s.courtName} ${hhmm(s.start)}').join(', ')}',
              ].join(' · '),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: scheme.onPrimaryContainer),
            ),
          ),
          if (Permissions.can(Permissions.TORNEOS_VER))
            TextButton(
              onPressed: () => context.goNamed(
                AppRoutes.TOURNAMENT_DETAIL_ROUTE.name,
                pathParameters: {'tournamentId': '${byTournament.keys.first}'},
              ),
              child: const Text('Ver torneo'),
            ),
        ],
      ),
    );
  }
}

/// Turno libre que se pisa con un partido de torneo: la cancha está ocupada.
class TournamentBlockedCard extends StatelessWidget {
  const TournamentBlockedCard({super.key, required this.slot, required this.height});

  final TournamentAgendaSlot slot;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.secondary),
      ),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_outlined, size: 14, color: scheme.onSecondaryContainer),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Partido de torneo · ${hhmm(slot.start)}–${hhmm(slot.end)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
            if (height > 48)
              Text(slot.tournamentName, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: scheme.onSecondaryContainer)),
          ],
        ),
      ),
    );
  }
}
