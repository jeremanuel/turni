import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/physical_partition.dart';
import '../../../domain/entities/session.dart';

class Agenda extends StatelessWidget {
   Agenda({
      super.key,
      required this.sessions,
      required this.buildCard,
      this.heightPerMinute = 2,
      required this.physicalPartitions,
      required this.fromDate,
      required this.lastDate,
      this.columnWidth = 300
      }){
          horariosDisponibles = generateDates(fromDate, lastDate);
          scrollControllers = generateScrollControllers();
          initializeScrollControllerListeners();
      }

  final List<Session> sessions;
  final Widget Function(Session) buildCard;
  final List<PhysicalPartition> physicalPartitions;
  final double heightPerMinute;
  final DateTime fromDate;
  final DateTime lastDate;
  final columnWidth;
  
  late final List<ScrollController> scrollControllers;
  final ScrollController horizontalController = ScrollController();
  final ScrollController horizontalController2 = ScrollController();

  late final List<DateTime> horariosDisponibles;



  List<DateTime> generateDates(DateTime startDate, DateTime endDate) {
    List<DateTime> dates = [];
    // Initialize the current date with the start date
    DateTime currentDate = startDate;

    // Loop until the current date reaches the end date
    while (currentDate.isBefore(endDate)) {
      // Add the current date to the list
      dates.add(currentDate);

      // Increment the current date by 30 minutes
      currentDate = currentDate.add(const Duration(minutes: 30));
    }

    return dates;
  }

  List<ScrollController> generateScrollControllers(){
        return List.generate(
        physicalPartitions.length + 2, (index) => ScrollController()
    ); 
  }

  initializeScrollControllerListeners(){
        for (var (index, currentScrollController) in scrollControllers.indexed) {


       // A cada uno de los scrollControlles le agrego un listener para que si el offset de alguno de los otros controllers cambia
       // Este salte al offset del otro
       // Para sincronizar todas las listas verticales y que simule ser una unica lista

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

  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Scrollbar(
        controller: scrollControllers.first,
        thumbVisibility: true,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            physics: ClampingScrollPhysics()),
            child: Row(
            children: [
              hoursList(context),
              
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
                          width: columnWidth.toDouble() * physicalPartitions.length,
                          child: cardsLists(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Column cardsLists(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
            children: physicalPartitions
                .map((el) => buildPartitionHeader(el, context))
                .toList()),
        Expanded(
          child: Row(
            children: physicalPartitions
                .map((el) => buildPartitionColumn(el, context))
                .toList(),
          ),
        ),
      ],
    );
  }

  // Construye las listviews que dibujan las lineas verticales y horizontales
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
                height: heightPerMinute * 30,
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
          
              return SizedBox(
                width: columnWidth.toDouble(),
                child: const Row(
                  children: [
                    VerticalDivider(width: 1,),
                  ],
                )
              );
            },
            itemCount: physicalPartitions.length,
          ),
        ],
      ),
    );
  }

  // Listview encargada de mostrar los distintos horarios
  SizedBox hoursList(BuildContext context) {
    return SizedBox(
      width: 64,
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
                height: 30 * heightPerMinute,
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

  Widget buildPartitionHeader(PhysicalPartition physicalPartition, context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child:Container(
        width: columnWidth - 16,
        height: 40 - 16,
        decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
        ),
           
        child: Center(
          child: Text("Cancha ${physicalPartition.physicalIdentifier!.toString()}")
        )),
    );
  }

  Widget buildPartitionColumn(PhysicalPartition physicalPartition, context) {
    final currentPhysicalPartitionSessions = sessions
        .where((element) =>
            element.partitionPhysicalId ==
            physicalPartition.partitionPhysicalId)
        .toList();

    if(currentPhysicalPartitionSessions.isEmpty){
      return SizedBox(
        width: columnWidth.toDouble(),
        child: ListView.builder(
          controller: scrollControllers[physicalPartitions.indexOf(physicalPartition) + 2],
          itemCount: 1,
          itemBuilder: (context, index) {

            final height = horariosDisponibles.first.difference(horariosDisponibles.last).inMinutes.abs() * heightPerMinute;
            
            return SizedBox(
              height: height + 40
            );
          },
        ),
        
      );
    }
    return SizedBox(
      width: columnWidth.toDouble(),
      child: ListView.builder(
        controller: scrollControllers[physicalPartitions.indexOf(physicalPartition) + 2],
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
                heightPerMinute;
          } else {
            offsetPrevio = (currentSession.startTime.difference(currentPhysicalPartitionSessions[index - 1].startTime).inMinutes.abs() -duration) * heightPerMinute;
          }
          

          if (index == currentPhysicalPartitionSessions.length - 1) {
            offsetFinal = (currentSession.startTime
                        .difference(
                            horariosDisponibles[horariosDisponibles.length - 1])
                        .inMinutes
                        .abs() -
                    duration) *
                heightPerMinute;
            
            offsetFinal += 40;
          }

          if(offsetPrevio < 0){
            print("wtf");
          }
          return Padding(
            padding: EdgeInsets.symmetric(vertical: heightPerMinute * 2),
            child: Column(
              children: [
                if (index == 0)
                  
                  // Esta caja mueve toda la lista 15 unidades de altura hacia abajo. 
                  // Ya que la unidad de tiempo ocupa 30 unidades de altura, 
                  // Asi se centra el inicio de cada turno con respecto a la unidad de tiempo.

                   SizedBox( 
                    height: 15 * heightPerMinute,
                  ),
                SizedBox(height: offsetPrevio.toDouble()),
                SizedBox(
                    height: duration * heightPerMinute.toDouble() - heightPerMinute * 4, // Le resto 4 unidades de tiempo por el padding que se aplica luego de 2 arriba y abajo.
                    child: buildCard(currentSession)),
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
