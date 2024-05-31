import 'dart:math';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../core/utils/types/time_interval.dart';
import '../../core/agenda/agenda.dart';
import '../../core/dates_carrousel/dates_carrousel.dart';
import '../bloc/session_manager_bloc.dart';
import '../bloc/session_manager_event.dart';
import '../bloc/session_manager_state.dart';
import '../../../domain/entities/club_partition.dart';

class SessionsManager extends StatelessWidget {
  const SessionsManager({
    super.key,
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
          child: Column(
            children: [
              SizedBox(height: 80, child: buildDayHeader()),
              const SizedBox(
                height: 8,
              ),
              const Divider(),
              const SizedBox(
                height: 8,
              ),
              Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Theme.of(context).colorScheme.surface,
                    //boxShadow: [BoxShadow(blurRadius: 5, spreadRadius: 5, color: Theme.of(context).colorScheme.shadow.withOpacity(0.2))],
                  ),
                  width: 300,
                  child: calendarDatepicker2(context)),
              const SizedBox(
                height: 8,
              ),
              const Divider(),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 36,
                    child: FilledButton(
                        onPressed: () {
                          context.go('/add_sessions');
                        }, 
                        child: const Text("Agregar Turnos")),
                  ),
                  SizedBox(
                    height: 36,
                    child: TextButton(
                        onPressed: () {},
                        child: const Text("Secondary option")),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Column buildAgendaContainer(BuildContext context) {
    return Column(
      children: [
        if (ResponsiveBuilder.isMobile(context))
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(height: 50, child: buildDayHeader()),
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

  Widget buildDayHeader() {
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      bloc: sl<SessionManagerBloc>(),
      builder: (context, state) {
        return DatesCarrousel(
          datesCarrouselController: sl<SessionManagerBloc>().datesCarrouselController ,
          initialDate: state.currentDate,
          onSelect: (date) {
            sl<SessionManagerBloc>()
                .add(SessionChangeDateEvent(date));
          },
        );
      },
    );

  }

  Widget buildAgenda(BuildContext context) {
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      bloc: sl<SessionManagerBloc>(),
      buildWhen: (previous, current) => previous.sessions != current.sessions || previous.selectedClubPartition != current.selectedClubPartition || previous.isLoadingSessions != current.isLoadingSessions,
      builder: (context, state) {
        if (state.isLoadingSessions) {
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
            return Container(
              width: 190,
              decoration: BoxDecoration(
                  color: session.clientId != null
                      ? Theme.of(context).colorScheme.surfaceContainerHigh
                      : Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: session.clientId != null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.tertiary,
                    width: 16,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time),
                            Text(
                              "${DateFormat.jm().format(session.startTime!)} - ${DateFormat.jm().format(session.endTime)}",
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (session.clientId != null)
                          const Row(
                            children: [
                              Icon(Icons.person),
                              Text("Lucas Medico"),
                            ],
                          ),
                        if (session.clientId == null)
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text("Reservar"),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {},
                        ),
                        const Spacer(),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
          sessions: state.sessions,
          physicalPartitions:
              state.selectedClubPartition?.physicalPartitions ?? [],
        );
      },
    );
  }

  Widget calendarDatepicker2(BuildContext context) {
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      bloc: sl<SessionManagerBloc>(),
      buildWhen: (previous, current) => previous.currentDate != current.currentDate,
      builder: (context, state) {
        return CalendarDatePicker2(
            onValueChanged: (value) {
              sl<SessionManagerBloc>()
                  .add(SessionChangeDateEvent(value.first ?? DateTime.now()));
            },
            config: CalendarDatePicker2Config(
              dayBuilder: (
                      {required date,
                      decoration,
                      isDisabled,
                      isSelected,
                      isToday,
                      textStyle}) =>
                  dayBuilder(context,
                      date: date,
                      decoration: decoration,
                      isDisabled: isDisabled,
                      isSelected: isSelected,
                      isToday: isToday,
                      textStyle: textStyle),
            ),
            value: [state.currentDate]);
      },
    );
  }

  Widget? dayBuilder(context,
      {required DateTime date,
      decoration,
      isDisabled,
      isSelected,
      isToday,
      textStyle}) {
    Color? dayColor;
    Color? textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    if (isSelected) {
      dayColor = Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.onPrimary;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: dayColor,
        border: isToday
            ? Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant)
            : null,
      ),
      child: Badge(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        isLabelVisible: date.day.isOdd && Random().nextBool(),
        label: Text(
          "3",
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ),
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black // Color de la línea
      ..strokeWidth = 2; // Grosor de la línea

    final startPoint = Offset(0, size.height / 2); // Punto inicial de la línea
    final endPoint =
        Offset(size.width, size.height / 2); // Punto final de la línea

    canvas.drawLine(startPoint, endPoint, paint); // Dibujar la línea
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // Devuelve true si la línea debe ser repintada
  }
}
