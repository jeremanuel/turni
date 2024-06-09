import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../core/utils/types/time_interval.dart';
import '../../core/agenda/agenda.dart';
import '../bloc/session_manager_bloc.dart';
import '../bloc/session_manager_event.dart';
import '../bloc/session_manager_state.dart';
import '../../../domain/entities/club_partition.dart';
import 'widgets/session_manager_day_carrousel.dart';
import 'widgets/session_manager_card.dart';

class SessionsManager extends StatelessWidget {

  final Widget sideChild;
  
  const SessionsManager({
    super.key, 
    required this.sideChild,
  });

  @override
  Widget build(BuildContext context) {

    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      bloc: sl<SessionManagerBloc>(),
      buildWhen: (previous, current) =>
          previous.isFirstLoad != current.isFirstLoad,
      builder: (context, state) {
        if (state.isFirstLoad) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
    
        if (ResponsiveBuilder.isMobile(context)) {
          return buildAgendaContainer(context);
        }
    
        return buildDesktopManager(context);
      },
    );
  }

  Row buildDesktopManager(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: buildAgendaContainer(context),
          ),
        ),
        const VerticalDivider(),
        const SizedBox(
          width: 16,
        ),
        SizedBox(
          width: 300,
          child: sideChild
        )
      ],
    );
  }

  Column buildAgendaContainer(BuildContext context) {
    return Column(
      children: [
        if (ResponsiveBuilder.isMobile(context))
          const Padding(
            padding:  EdgeInsets.all(8.0),
            child: SizedBox(height: 50, child: SessionManagerDayCarrousel()),
          ),
        SizedBox(
          height: 40,
          child: BlocBuilder<SessionManagerBloc, SessionManagerState>(
            bloc: sl<SessionManagerBloc>(),
            builder: (context, state) {
              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (ResponsiveBuilder.isMobile(context))
                    const SizedBox(
                      width: 8,
                    ),
                  ...state.clubPartitions.expand((e) => [
                        buildChip(e, context, state),
                        const SizedBox(
                          width: 16,
                        ),
                      ]),
                  if (ResponsiveBuilder.isMobile(context))
                    const SizedBox(
                      width: 8,
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        Expanded(
          child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      blurRadius: 5,
                      spreadRadius: 5,
                      color:
                          Theme.of(context).colorScheme.shadow.withOpacity(0.1))
                ],
                color: Theme.of(context).colorScheme.surface,
              ),
              child: buildAgenda(context)),
        ),
      ],
    );
  }

  FilterChip buildChip(
          ClubPartition e, BuildContext context, SessionManagerState state) =>
      FilterChip(
        label: Text(e.clubType!.name),
        onSelected: onSelectChip(context, e),
        showCheckmark: false,
        selected: e.club_partition_id ==
            state.selectedClubPartition?.club_partition_id,
      );

  onSelectChip(context,e) {
    return (val){
      sl<SessionManagerBloc>().add(ChangeClubPartitionEvent(e));
    };
  }
  Widget buildAgenda(BuildContext context) {
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      bloc: sl<SessionManagerBloc>(),
      buildWhen: (previous, current) => previous.sessions != current.sessions || previous.selectedClubPartition != current.selectedClubPartition || previous.isLoadingSessions != current.isLoadingSessions,
      builder: (context, state) {
        
        if(state.isLoadingSessions) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Agenda(
          columnWidth: 200,
          heightPerMinute: ResponsiveBuilder.isDesktop(context) ? 1.35 : 1,
          fromDate: state.currentDate.applied(const TimeOfDay(hour: 8, minute: 0)),
          lastDate: state.currentDate.applied(const TimeOfDay(hour: 22, minute: 0)),
          buildCard: (session) {
            return SessionManagerCard(session: session);
          },
          sessions: state.sessions,
          physicalPartitions:
              state.selectedClubPartition?.physicalPartitions ?? [],
        );
      },
    );
  }
}


