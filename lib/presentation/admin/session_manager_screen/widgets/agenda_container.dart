import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive_builder.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../core/agenda/agenda.dart';
import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';
import '../../bloc/session_manager_state.dart';
import '../../browser/browser.dart';
import '../../browser/browser_options.dart';
import 'session_manager_card.dart';
import 'session_manager_day_carrousel.dart';
import '../../../../core/utils/types/time_interval.dart';

class AgendaContainer extends StatelessWidget {
  const AgendaContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
        builder: (context, state) {
          return Column(
            children: [
              SizedBox(
                  width: 500,
                  child: GenericBrowser(
                    browserOptions:
                        BrowserOptions(clubPartitions: state.clubPartitions),
                  )),
              const SizedBox(
                height: 8,
              ),
              if (ResponsiveBuilder.isMobile(context))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                      height: 50,
                      child: SessionManagerDayCarrousel(
                        width: MediaQuery.of(context).size.width * 0.9,
                      )),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                height: 56,
                child: ListView(
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
                ),
              ),
              const SizedBox(
                height: 8,
              ),
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
                                .withOpacity(0.1))
                      ],
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: buildAgenda(context)),
              ),
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

        return Agenda(
          columnWidth: 200,
          heightPerMinute: ResponsiveBuilder.isDesktop(context) ? 1.35 : 1.1,
          fromDate:
              state.currentDate.applied(const TimeOfDay(hour: 8, minute: 0)),
          lastDate:
              state.currentDate.applied(const TimeOfDay(hour: 22, minute: 0)),
          buildCard: (session, physicalPartition) {
            if(state.selectedSession == session){
            }
            return SessionManagerCard(
             hasFocus: state.selectedSession == session, 
              session: session,
              physicalPartition: physicalPartition,
              onReserve: () {
                
              },
            );
          },
          sessions: state.sessions,
          physicalPartitions:
              state.selectedClubPartition?.physicalPartitions ?? [],
        );
      },
    );
  }

    FilterChip buildChip(ClubPartition e, BuildContext context, SessionManagerState state) =>
      FilterChip(
        label: Text(e.clubType!.name),
        onSelected: onSelectChip(context, e),
        showCheckmark: false,
        selected: e.club_partition_id ==
            state.selectedClubPartition?.club_partition_id,
      );

      
  onSelectChip(BuildContext context, e) {
    return (val) {
      final sessionManagerBloc = context.read<SessionManagerBloc>();
      sessionManagerBloc.add(ChangeClubPartitionEvent(e));
    };
  }
}