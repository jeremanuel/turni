import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/physical_partition.dart';
import '../../../domain/entities/session.dart';

class Agenda extends StatefulWidget {
  const Agenda(
      {super.key, required this.sessions,
      required this.buildCard,
      this.heightPerMinute = 2,
      required this.physicalPartitions});

  final List<Session> sessions;
  final Widget Function(Session) buildCard;
  final List<PhysicalPartition> physicalPartitions;
  final double heightPerMinute;

  final columnWidth = 300;

  @override
  State<Agenda> createState() => _AgendaState();
}

class _AgendaState extends State<Agenda> {
  List<ScrollController> scrollControllers = [];
  final ScrollController horizontalController = ScrollController();
  final ScrollController horizontalController2 = ScrollController();

  final horariosDisponibles = [
    DateTime(
      2024,
      3,
      8,
      9,
    ),
    DateTime(2024, 3,  8,  8, 30),
    DateTime(2024, 3,  8, 10),
    DateTime(2024, 3,  8, 10, 30),
    DateTime(2024, 3,  8, 11),
    DateTime(2024, 3,  8, 11, 30),
    DateTime(2024, 3,  8, 12),
    DateTime(2024, 3,  8, 12, 30),
    DateTime(2024, 3,  8, 13),
    DateTime(2024, 3,  8, 13, 30),
    DateTime(2024, 3,  8, 14),
    DateTime(2024, 3,  8, 14, 30),
    DateTime(2024, 3,  8, 15),
    DateTime(2024, 3,  8, 15, 30),
    DateTime(2024, 3,  8, 16),
    DateTime(2024, 3,  8, 16, 30),
    DateTime(2024, 3,  8, 17),
    DateTime(2024, 3,  8, 17, 30),
    DateTime(2024, 3,  8, 18),
    DateTime(2024, 3,  8, 18, 30),
    DateTime(2024, 3,  8, 19),
    DateTime(2024, 3,  8, 19, 30),
    DateTime(2024, 3,  8, 20),
    DateTime(2024, 3,  8, 20, 30),
    DateTime(2024, 3,  8, 21),
  ];

  @override
  void initState() {
    scrollControllers = List.generate(
        widget.physicalPartitions.length + 2, (index) => ScrollController());

    for (var (index, currentScrollController) in scrollControllers.indexed) {
      currentScrollController.addListener(() {
        var currentIndex = 0;
        for (var scrollController in scrollControllers) {
          if (currentIndex == index) {
            currentIndex++;
            continue;
          }

          if (currentScrollController.offset != scrollController.offset) {
            scrollController.jumpTo(currentScrollController.offset);
          }
        }
      });
    }

    horizontalController.addListener(() {
      if (horizontalController.offset != horizontalController2.offset) {
        horizontalController2.jumpTo(horizontalController.offset);
      }
    });




    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          hoursList(context),
          const SizedBox(
            width: 25,
          ),
          Expanded(
            child: Stack(
              children: [
                linesList(),
                Scrollbar(
                  thumbVisibility: true,
                  controller: horizontalController,
                  child: SingleChildScrollView(
                    controller: horizontalController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: widget.columnWidth.toDouble() * widget.physicalPartitions.length,
                      child: Stack(
                        children: [
                          cardsLists(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ScrollConfiguration cardsLists(BuildContext context) {
    return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
                children: widget.physicalPartitions
                    .map(buildPartitionHeader)
                    .toList()),
            Expanded(
              child: Row(
                children: widget.physicalPartitions
                    .map(buildPartitionColumn)
                    .toList(),
              ),
            ),
          ],
        ));
  }

  Padding linesList() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Stack(
        children: [
          ListView.builder(
            controller: scrollControllers[1],
            itemBuilder: (context, index) {
              final now = DateTime.now();
              bool isCurrentDivider = false;
          
              if (index < horariosDisponibles.length - 1 &&
                  horariosDisponibles[index].isBefore(now) &&
                  horariosDisponibles[index + 1].isAfter(now)) {
                isCurrentDivider = true;
              }
          
              return SizedBox(
                height: 60,
                child: Divider(
                  color: isCurrentDivider ? Colors.black : null,
                ),
              );
            },
            itemCount: horariosDisponibles.length,
          ),
          ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: horizontalController2,
            itemBuilder: (context, index) {
              final now = DateTime.now();
              bool isCurrentDivider = false;
          
              if (index < horariosDisponibles.length - 1 &&
                  horariosDisponibles[index].isBefore(now) &&
                  horariosDisponibles[index + 1].isAfter(now)) {
                isCurrentDivider = true;
              }
          
              return Container(
                width: widget.columnWidth.toDouble(),
                child: const Row(
                  children: [
                    VerticalDivider(width: 1,),
                  ],
                )
              );
            },
            itemCount: widget.physicalPartitions.length,
          ),
        ],
      ),
    );
  }

  SizedBox hoursList(BuildContext context) {
    return SizedBox(
      width: 100,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: ListView.builder(
            controller: scrollControllers[0],
            itemBuilder: (context, index) {
              final now = DateTime.now();
              bool isCurrentDivider = false;

              if (index < horariosDisponibles.length - 1 &&
                  horariosDisponibles[index].isBefore(now) &&
                  horariosDisponibles[index + 1].isAfter(now)) {
                isCurrentDivider = true;
              }

              return SizedBox(
                height: 30 * widget.heightPerMinute,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat.jm().format(horariosDisponibles[index]),
                      style: TextStyle(
                          fontWeight:
                              isCurrentDivider ? FontWeight.bold : null),
                    )
                  ],
                ),
              );
            },
            itemCount: horariosDisponibles.length,
          ),
        ),
      ),
    );
  }

  Widget buildPartitionHeader(PhysicalPartition physicalPartition) {
    return Container(
      padding: const EdgeInsets.all(8),
      child:Container(
        width: widget.columnWidth - 16,
        height: 40 - 16,
        decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
        ),
          
      
        child: Center(
          child: Text("Cancha ${physicalPartition.physicalIdentifier!.toString()}")
        )),
    );
  }

  Widget buildPartitionColumn(PhysicalPartition physicalPartition) {
    final currentPhysicalPartitionSessions = widget.sessions
        .where((element) =>
            element.partitionPhysicalId ==
            physicalPartition.partitionPhysicalId)
        .toList();
    return SizedBox(
      width: widget.columnWidth.toDouble(),
      child: ListView.builder(
        controller: scrollControllers[widget.physicalPartitions.indexOf(physicalPartition) + 2],
        itemBuilder: (context, index) {
          double offsetPrevio = 0;
          double offsetFinal = 0;
          final currentSession = currentPhysicalPartitionSessions[index];
          final int duration = currentSession.getDurationInMinutes();
          if (index == 0) {
            offsetPrevio = currentSession.startTime
                    .difference(horariosDisponibles[0])
                    .inMinutes
                    .abs() *
                widget.heightPerMinute;
          } else {
            offsetPrevio = (currentSession.startTime.difference(currentPhysicalPartitionSessions[index - 1].startTime).inMinutes.abs() -duration) * widget.heightPerMinute;
          }

          if (index == currentPhysicalPartitionSessions.length - 1) {
            offsetFinal = (currentSession.startTime
                        .difference(
                            horariosDisponibles[horariosDisponibles.length - 1])
                        .inMinutes
                        .abs() -
                    duration) *
                widget.heightPerMinute;
            
            offsetFinal += 40;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                if (index == 0)
                  const SizedBox(
                    height: 30,
                  ),
                SizedBox(height: offsetPrevio.toDouble()),
                SizedBox(
                    height: duration * widget.heightPerMinute.toDouble() - 8,
                    child: widget.buildCard(currentSession)),
                if (index == currentPhysicalPartitionSessions.length - 1)
                  SizedBox(
                    height: offsetFinal.toDouble(),
                  ),
              ],
            ),
          );
        },
        itemCount: currentPhysicalPartitionSessions.length,
      ),
    );
  }
}
