import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive_builder.dart';
import '../../../../core/utils/physical_partition_naming.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../core/agenda/agenda.dart';
import '../../club_config/club_config_focus.dart';
import '../../club_config/widgets/inactive_partition_hint.dart';
import '../bloc/session_manager_bloc.dart';
import '../bloc/session_manager_event.dart';
import '../bloc/session_manager_state.dart';
import '../../browser/browser.dart';
import '../../browser/browser_options.dart';
import 'session_manager_card.dart';
import 'session_manager_day_carrousel.dart';
import 'mobile_agenda_actions.dart';
import 'tournament_agenda_slots.dart';
import '../../../../core/utils/types/time_interval.dart';

class AgendaContainer extends StatefulWidget {
  const AgendaContainer({super.key});

  @override
  State<AgendaContainer> createState() => _AgendaContainerState();
}

class _AgendaContainerState extends State<AgendaContainer> {
  /// Celular: la cancha que se está viendo (una a la vez, diseño "Admin
  /// mobile"). null = la primera del servicio elegido.
  int? _mobileCourtId;

  /// Canchas visibles del servicio elegido: las inactivas no se muestran,
  /// salvo que ese día tengan turnos (dar de baja no borra los turnos ya
  /// creados).
  List<PhysicalPartition> _courts(SessionManagerState state) =>
      (state.selectedClubPartition?.physicalPartitions ?? [])
          .where((p) => p.active || state.sessions.any((s) => s.partitionPhysicalId == p.partitionPhysicalId))
          .toList();

  /// Nombre de la cancha en el chip; si dos canchas se llaman igual, se
  /// agrega su número para poder distinguirlas.
  String _courtChipLabel(PhysicalPartition court, SessionManagerState state) {
    String label(PhysicalPartition p) =>
        PhysicalPartitionNaming.labelFromPhysicalPartition(p, fallbackClubPartition: state.selectedClubPartition);
    final own = label(court);
    final repeated = _courts(state).where((p) => label(p) == own).length > 1;
    return repeated ? '$own · ${court.physicalIdentifier ?? court.partitionPhysicalId}' : own;
  }

  PhysicalPartition? _mobileCourt(SessionManagerState state) {
    final courts = _courts(state);
    if (courts.isEmpty) return null;
    return courts.firstWhere((p) => p.partitionPhysicalId == _mobileCourtId, orElse: () => courts.first);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
        builder: (context, state) {
          final isMobile = ResponsiveBuilder.isMobile(context);
          final agenda = TournamentAgendaSlots(
            day: state.currentDate,
            child: Column(
            children: [
              if (isMobile) const MobileAgendaToolbar(),
              if (ResponsiveBuilder.isMobile(context))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                      height: 50,
                      child: SessionManagerDayCarrousel(
                        // Celular: alineado con la agenda (16 de margen de cada lado).
                        width: MediaQuery.of(context).size.width - 32,
                      )),
                ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 8),
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final (i, e) in state.clubPartitions.indexed) ...[
                      if (i > 0) SizedBox(width: isMobile ? 8 : 16),
                      buildChip(e, context, state),
                    ],
                  ],
                ),
              ),
              if (ResponsiveBuilder.isMobile(context) && _courts(state).length > 1)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final court in _courts(state)) ...[
                        ChoiceChip(
                          label: Text(_courtChipLabel(court, state)),
                          selected: court.partitionPhysicalId == _mobileCourt(state)?.partitionPhysicalId,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _mobileCourtId = court.partitionPhysicalId),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              const SizedBox(
                height: 8,
              ),
              const TournamentAgendaBanner(),
              Expanded(
                child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            blurRadius: 5,
                            spreadRadius: 5,
                            color: Theme.of(context)
                                .colorScheme
                                .shadow
                                .withValues(alpha:0.1))
                      ],
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: buildAgenda(context)),
              ),
            ],
          ),
          );
          if (!isMobile) return agenda;
          // Celular: botón flotante para cargar turnos, sobre la agenda.
          return Stack(
            children: [
              Positioned.fill(child: agenda),
              const Positioned(right: 0, bottom: 0, child: MobileAgendaAddButton()),
            ],
          );
        });
  }

    Widget buildAgenda(BuildContext context) {
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      buildWhen: (previous, current) =>
          previous.sessions != current.sessions ||
          previous.selectedClubPartition != current.selectedClubPartition ||
          previous.isLoadingSessions != current.isLoadingSessions || previous.selectedSession != current.selectedSession,
      builder: (context, state) {
       
        if (state.isLoadingSessions) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final isMobile = ResponsiveBuilder.isMobile(context);
        final mobileCourt = isMobile ? _mobileCourt(state) : null;
        return LayoutBuilder(builder: (context, constraints) => Agenda(
          // Celular: una cancha a todo el ancho (menos la columna de horas).
          columnWidth: isMobile ? (constraints.maxWidth - 66).clamp(160, 600).toDouble() : 200,
          focusSession: state.selectedSession,
          heightPerMinute: ResponsiveBuilder.isDesktop(context) ? 1.35 : 1.1,
          fromDate:
              state.currentDate.applied(const TimeOfDay(hour: 8, minute: 0)),
          lastDate:
              state.currentDate.applied(const TimeOfDay(hour: 22, minute: 0)),
          buildCard: (session, physicalPartition, height) {
            // Turno libre que se pisa con un partido de torneo: la cancha
            // está ocupada (no se puede reservar, ver tournament_session).
            final blocking = session.isFree ? TournamentAgendaSlots.blocking(context, session) : null;
            if (blocking != null) return TournamentBlockedCard(slot: blocking, height: height);
            return SessionManagerCard(
              height:height,
             hasFocus: state.selectedSession == session, 
              session: session,
              physicalPartition: physicalPartition,
              onReserve: () {
                
              },
            );
          },
              partitionLabelBuilder: (physicalPartition) =>
                  PhysicalPartitionNaming.labelFromPhysicalPartition(
                physicalPartition,
                fallbackClubPartition: state.selectedClubPartition,
              ),
          sessions: state.sessions,
          // Las canchas inactivas no se muestran como columna, salvo que ese
          // día tengan turnos (dar de baja no borra los turnos ya creados).
          physicalPartitions: mobileCourt != null ? [mobileCourt] : _courts(state),
        ));
      },
    );
  }

    Widget buildChip(ClubPartition e, BuildContext context, SessionManagerState state) =>
      InactivePartitionHint(
        inactive: !e.active,
        message: InactivePartitionHint.clubPartitionMessage,
        focus: ClubConfigFocus.clubPartition(e.club_partition_id ?? 0),
        onConfigClosed: () => context
            .read<SessionManagerBloc>()
            .add(ReloadClubPartitionsEvent()),
        child: FilterChip(
          label: Text(e.displayName),
          onSelected: e.active ? onSelectChip(context, e) : null,
          showCheckmark: false,
          selected: e.club_partition_id ==
              state.selectedClubPartition?.club_partition_id,
        ),
      );

      
  onSelectChip(BuildContext context, e) {
    return (val) {
      final sessionManagerBloc = context.read<SessionManagerBloc>();
      sessionManagerBloc.add(ChangeClubPartitionEvent(e));
    };
  }
}