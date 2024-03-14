import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/physical_partition.dart';
import '../../../domain/entities/session.dart';

class Agenda extends StatefulWidget {
  const Agenda({
      super.key,
      required this.sessions,
      required this.buildCard,
      this.heightPerMinute = 2,
      required this.physicalPartitions,
      required this.fromDate,
      required this.lastDate,
      this.columnWidth = 300
      });

  final List<Session> sessions;
  final Widget Function(Session) buildCard;
  final List<PhysicalPartition> physicalPartitions;
  final double heightPerMinute;
  final DateTime fromDate;
  final DateTime lastDate;
  final columnWidth;

  @override
  State<Agenda> createState() => _AgendaState();
}

class _AgendaState extends State<Agenda> {
  List<ScrollController> scrollControllers = [];
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
    currentDate = currentDate.add(Duration(minutes: 30));
  }

  return dates;
}

  @override
  void initState() {

    horariosDisponibles = generateDates(widget.fromDate, widget.lastDate);

    // Genero la lista de scrollcontrollers
    // Contiene un scrollcontroller por cada particion fisica + 2 
    // (esos dos son la lista de horarios y la lista de lineas verticales)
    scrollControllers = List.generate(
        widget.physicalPartitions.length + 2, (index) => ScrollController()
    ); 
      
      

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

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
                      width: widget.columnWidth.toDouble() * widget.physicalPartitions.length,
                      child: cardsLists(context),
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
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          physics: ClampingScrollPhysics()),
        
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


  // Construye las listviews que dibujan las lineas verticales y horizontales
  // Las lineas verticales representan la segmentacion de tiempo
  // Las lineas horizontales representan a cada particion fisica.
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
                height: widget.heightPerMinute * 30,
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
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
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

    if(currentPhysicalPartitionSessions.isEmpty){
      return SizedBox(
        width: widget.columnWidth.toDouble(),
        child: ListView.builder(
          controller: scrollControllers[widget.physicalPartitions.indexOf(physicalPartition) + 2],
          itemCount: 1,
          itemBuilder: (context, index) {

            final height = horariosDisponibles.first.difference(horariosDisponibles.last).inMinutes.abs() * widget.heightPerMinute;
            
            return SizedBox(
              height: height + 40
            );
          },
        ),
        
      );
    }
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

          if(offsetPrevio < 0){
            print("wtf");
          }
          return Padding(
            padding: EdgeInsets.symmetric(vertical: widget.heightPerMinute * 2),
            child: Column(
              children: [
                if (index == 0)
                  
                  // Esta caja mueve toda la lista 15 unidades de altura hacia abajo. 
                  // Ya que la unidad de tiempo ocupa 30 unidades de altura, 
                  // Asi se centra el inicio de cada turno con respecto a la unidad de tiempo.

                   SizedBox( 
                    height: 15 * widget.heightPerMinute,
                  ),
                SizedBox(height: offsetPrevio.toDouble()),
                SizedBox(
                    height: duration * widget.heightPerMinute.toDouble() - widget.heightPerMinute * 4, // Le resto 4 unidades de tiempo por el padding que se aplica luego de 2 arriba y abajo.
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
