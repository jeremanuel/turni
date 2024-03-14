import 'dart:math';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../domain/entities/physical_partition.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/usercases/session_user_cases.dart';
import '../../core/agenda/agenda.dart';
import 'blocs/bloc/session_manager_bloc.dart';
import 'blocs/bloc/session_manager_event.dart';
import 'blocs/bloc/session_manager_state.dart';

class SessionsManager extends StatelessWidget {
  const SessionsManager({
    super.key,
  });
  DateTime get _now => DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionManagerBloc>(
        create: (context) => SessionManagerBloc(),
        child: BlocBuilder<SessionManagerBloc, SessionManagerState>(
          buildWhen: (previous, current) =>
              previous.isFirstLoad != current.isFirstLoad,
          builder: (context, state) {
            if (state.isFirstLoad) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

          if(ResponsiveBuilder.isMobile(context)) {
              return buildAgenda(context);
            } 

            return buildDesktopManager(context);
          },
        ));
  }

  Row buildDesktopManager(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
              margin:
                  const EdgeInsets.only(top: 46, left: 8, right: 8, bottom: 8),
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
        const VerticalDivider(),
        const SizedBox(
          width: 16,
        ),
        SizedBox(
          width: 300,
          child: Column(
            children: [
              buildDayHeader(),
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
                  child: CalendarDatepicker2(context)),
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
                        onPressed: () {}, child: const Text("Agregar Turnos")),
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

  Widget buildDayHeader() {
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      builder: (context, state) {
        return SizedBox(
          height: 24,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(toBeginningOfSentenceCase(
                DateFormat.EEEE().format(state.currentDate))),
            const SizedBox(
              width: 8,
            ),
            const Icon(
              Icons.circle,
              size: 8,
            ),
            const SizedBox(
              width: 8,
            ),
            Text(DateFormat.MMMMd().format(state.currentDate)),
          ]),
        );
      },
    );
  }

  Widget buildAgenda(BuildContext context) {
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      builder: (context, state) {

        if(state.isLoadingSessions){
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        return Agenda(
          columnWidth: 200,
          heightPerMinute: ResponsiveBuilder.isDesktop(context) ? 1.35 : 1,
          fromDate: DateTime(2024, 3, 12, 8),
          lastDate: DateTime(2024, 3, 12, 22),
          buildCard: (session) {
            return Container(
              width: 190,
              decoration: BoxDecoration(
                  color: session.clientId != null
                      ? Theme.of(context).colorScheme.surfaceVariant
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
                              "${DateFormat.jm().format(session.startTime)} - ${DateFormat.jm().format(session.endTime)}",
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
          physicalPartitions: [
            PhysicalPartition(
                partitionPhysicalId: 1,
                clubPartitionId: 1,
                minPlayers: 5,
                maxPlayers: 2,
                physicalIdentifier: 25,
                isCover: "false",
                description: "description"),
            PhysicalPartition(
                partitionPhysicalId: 2,
                clubPartitionId: 1,
                minPlayers: 5,
                maxPlayers: 2,
                physicalIdentifier: 14,
                isCover: "false",
                description: "description"),
            PhysicalPartition(
                partitionPhysicalId: 3,
                clubPartitionId: 1,
                minPlayers: 5,
                maxPlayers: 2,
                physicalIdentifier: 12,
                isCover: "false",
                description: "description"),
            PhysicalPartition(
                partitionPhysicalId: 4,
                clubPartitionId: 1,
                minPlayers: 5,
                maxPlayers: 2,
                physicalIdentifier: 13,
                isCover: "false",
                description: "description")
          ],
        );
      },
    );
  }

  Widget CalendarDatepicker2(BuildContext context) {
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      builder: (context, state) {
        return CalendarDatePicker2(
            onValueChanged: (value) {
              BlocProvider.of<SessionManagerBloc>(context)
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
        isLabelVisible: date.day.isOdd,
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
