import 'dart:math';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/physical_partition.dart';
import '../../../domain/entities/session.dart';
import '../../core/agenda/agenda.dart';

class SessionsManager extends StatelessWidget {
  const SessionsManager({
    super.key,
  });
  DateTime get _now => DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            height: 800,
            margin: const EdgeInsets.symmetric(vertical: 58, horizontal: 10),
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(blurRadius: 5, spreadRadius: 5, color: Theme.of(context).colorScheme.shadow.withOpacity(0.1))],
                color: Theme.of(context).colorScheme.surface,
               ),
            child: Agenda(
              buildCard: (session) {

                return Container(
                  width: 280,
                  decoration: BoxDecoration(
                  color: session.clientId != null ? Theme.of(context).colorScheme.surfaceVariant : Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12)
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: session.clientId != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                        width: 16,
                      ),
                      const SizedBox(width: 4,),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.access_time),
                                Text(
                                  DateFormat.jm().format(session.startTime),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if(session.clientId != null)
                              const Row(
                              children: [
                                Icon(Icons.person),
                                Text("Lucas Medico"),
                              ],
                            ),
                           if(session.clientId == null) FilledButton(onPressed: (){}, style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Theme.of(context).colorScheme.error)),  child: const Text("Reservar"), ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, right: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: (){},),
                            const Spacer(),
                            Text(
                              "\$ ${session.price.toString()}"
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );

              },
              sessions: [
              
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 10 ), "01:30", null, 1500, 1, 1),
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 11, 30 ), "01:30", null, 1500, 1, 1),
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 13 ), "01:30", 1, 1500, 1, 1),

                Session(1, DateTime.now(), DateTime(2024, 3, 8, 14, 30 ), "01:30", 1, 1500, 1, 1),
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 16 ), "01:30", 1, 1500, 1, 1),
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 17, 45 ), "01:30", null, 1500, 1, 1),
                
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 19, 30 ), "01:30", 1, 1500, 1, 1),
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 9 ), "01:30", null, 1500, 1, 2),
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 10, 45 ), "01:30", null, 1500, 1, 2),

                Session(1, DateTime.now(), DateTime(2024, 3, 8, 13 ), "01:30", 1, 1500, 1, 2),
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 14, 30 ), "01:30", 1, 1500, 1, 2),
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 16 ), "01:30", 1, 1500, 1, 2),

                Session(1, DateTime.now(), DateTime(2024, 3, 8, 17, 45 ), "01:30", null, 1500, 1, 2),
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 19, 30 ), "01:30", 1, 1500, 1, 2),
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 15 ), "01:30", 2, 1500, 1, 2),

                Session(1, DateTime.now(), DateTime(2024, 3, 8, 15), "01:30", 2, 1500, 1, 2),
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 15 ), "01:30", 2, 1500, 1, 3),
                Session(1, DateTime.now(), DateTime(2024, 3, 8, 15 ), "01:30", 2, 1500, 1, 4),
              
              ],
              physicalPartitions: [
                PhysicalPartition(partitionPhysicalId: 1, clubPartitionId: 1, minPlayers: 5, maxPlayers: 2, physicalIdentifier: 25, isCover: "false", description: "description"),
                PhysicalPartition(partitionPhysicalId: 2, clubPartitionId: 1, minPlayers: 5, maxPlayers: 2, physicalIdentifier: 14, isCover: "false", description: "description"),
                PhysicalPartition(partitionPhysicalId: 3, clubPartitionId: 1, minPlayers: 5, maxPlayers: 2, physicalIdentifier: 12, isCover: "false", description: "description"),
                PhysicalPartition(partitionPhysicalId: 4, clubPartitionId: 1, minPlayers: 5, maxPlayers: 2, physicalIdentifier: 13, isCover: "false", description: "description")

                ],
            )
          ),
        ),
        const VerticalDivider(),
        const SizedBox(
          width: 16,
        ),
        SizedBox(
          width: 400,
          child: Column(
            children: [
              const SizedBox(
                height: 24,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Domingo"),
                      SizedBox(
                        width: 8,
                      ),
                      Icon(
                        Icons.circle,
                        size: 8,
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Text("5 de Junio"),
                    ]),
              ),
              const SizedBox(
                height: 8,
              ),
              const Divider(),
              const SizedBox(
                height: 8,
              ),
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      //boxShadow: [BoxShadow(blurRadius: 5, spreadRadius: 5, color: Theme.of(context).colorScheme.shadow.withOpacity(0.2))],

                      ),
                  width: 400,
                  child: CalendarDatepicker2(context)),
              const Spacer(),
              SizedBox(
                height: 36,
                child: FilledButton(
                    onPressed: () {
                      final horaInicio = (Random().nextDouble() * 16 + 8).floor();
                      final horaInicio2 = (Random().nextDouble() * 16 + 8).floor();

                      print(horaInicio);
                      
                      CalendarControllerProvider.of(context)
                          .controller
                          .addAll([
                            CalendarEventData(
                            title: "test 1",
                            date: DateTime(2024, 3, 3),
                            startTime: DateTime(2024, 3, 3, horaInicio),
                            endTime: DateTime(2024, 3,3, horaInicio + 2),
                            description: "DESCRIPCION XD",
                            color: Theme.of(context).colorScheme.primary,
                            ),
                            CalendarEventData(
                            title: "test 2",
                            date: DateTime(2024, 3, 3),
                            startTime: DateTime(2024, 3, 3, horaInicio),
                            endTime: DateTime(2024, 3,3, horaInicio + 2),
                            description: "asdasdasdasd",
                            color: Theme.of(context).colorScheme.tertiary,
                            ),
                            CalendarEventData(
                            title: "test 3",
                            date: DateTime(2024, 3, 3),
                            startTime: DateTime(2024, 3, 3, horaInicio),
                            endTime: DateTime(2024, 3,3, horaInicio + 1, 25),
                            description: "asdasdasdasd",
                            color: Theme.of(context).colorScheme.secondary,
                            ),
                                CalendarEventData(
                            title: "test 4",
                            date: DateTime(2024, 3, 3),
                            startTime: DateTime(2024, 3, 3, horaInicio2),
                            endTime: DateTime(2024, 3,3, horaInicio2 + 2),
                            description: "DESCRIPCION XD",
                            color: Theme.of(context).colorScheme.primary,
                            ),
                            CalendarEventData(
                            title: "test 5",
                            date: DateTime(2024, 3, 3),
                            startTime: DateTime(2024, 3, 3, horaInicio2),
                            endTime: DateTime(2024, 3,3, horaInicio2 + 2),
                            description: "asdasdasdasd",
                            color: Theme.of(context).colorScheme.tertiary,
                            ),
                            CalendarEventData(
                            title: "test 6",
                            date: DateTime(2024, 3, 3),
                            startTime: DateTime(2024, 3, 3, horaInicio2),
                            endTime: DateTime(2024, 3,3, horaInicio2 + 1, 25),
                            description: "asdasdasdasd",
                            color: Theme.of(context).colorScheme.secondary,
                            ),
                            CalendarEventData(
                            title: "test 7",
                            date: DateTime(2024, 3, 3),
                            startTime: DateTime(2024, 3, 3, 10),
                            endTime: DateTime(2024, 3,3, 10 + 2, 25),
                            description: "asdasdasdasd",
                            color: Theme.of(context).colorScheme.secondary,
                            ),

                          ]);

                          
                    },
                    child: const Text("Test Agregar Turnos")),
              ),
            ],
          ),
        )
      ],
    );
  }

  CalendarDatePicker2 CalendarDatepicker2(BuildContext context) {
    return CalendarDatePicker2(
      
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
        value: [DateTime.now()]);
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
