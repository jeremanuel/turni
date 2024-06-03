import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../domain/entities/physical_partition.dart';
import '../../../domain/entities/session.dart';

class Agenda extends StatelessWidget {
  Agenda(
      {super.key,
      required this.sessions,
      required this.buildCard,
      this.heightPerMinute = 2,
      required this.physicalPartitions,
      required this.fromDate,
      required this.lastDate,
      this.columnWidth = 300}) {
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
  final double columnWidth;
  final double hoursWidth = 64;
  
  late final List<ScrollController> scrollControllers;
  
  final ScrollController horizontalColumnesScrollController = ScrollController();
  final ScrollController horizontalLinesScrollController = ScrollController();
  final ScrollController verticalColumnsScrollController = ScrollController();
  final ScrollController verticalLinesScrollController = ScrollController();
  final ScrollController verticalLinesAuxScrollController = ScrollController();

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
        physicalPartitions.length, (index) => ScrollController()
    ); 
  }

  initializeScrollControllerListeners(){

      for (var (index, currentScrollController) in [verticalLinesScrollController, verticalColumnsScrollController, verticalLinesAuxScrollController,...scrollControllers].indexed) {

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

        if(currentScrollController.offset != verticalLinesScrollController.offset){
          verticalLinesScrollController.jumpTo(currentScrollController.offset);
        }

        if(currentScrollController.offset != verticalColumnsScrollController.offset){
          verticalColumnsScrollController.jumpTo(currentScrollController.offset);
        }


      }); 
    }

    horizontalColumnesScrollController.addListener(() {
      if (horizontalColumnesScrollController.offset != horizontalLinesScrollController.offset) {
        horizontalLinesScrollController.jumpTo(horizontalColumnesScrollController.offset);
      }
    }); 


  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {

        final remainingSpace = calculateRemainingSpace(constraints);

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              dragDevices:PointerDeviceKind.values.toSet(),
              physics: const ClampingScrollPhysics()),
              child: Row(
              children: [
                hoursList(context),                
                Expanded(
                  child: Stack(
                    children: [                                       
                      linesList(),
                      Scrollbar(
                        thumbVisibility: true,
                        controller: horizontalColumnesScrollController,
                        child: SingleChildScrollView(
                          controller: horizontalColumnesScrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              cardsLists(context),
                              if(remainingSpace > 0) // Si hay espacio restante, ponemos una caja, para que ese espacio restante se scrolleable.
                                SizedBox(
                                  width: remainingSpace,
                                  child: buildEmptyList(verticalLinesAuxScrollController),
                                )
                            ],
                          ),
                        ),
                      ),
                      
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  /// Calculo del ancho restante para llenar la Agenda
  /// Es el ancho total - el ocupado por las columnas (ancho utilizado realmente)  - el ancho de la columna de horarios (tambien utilizado)
  /// El ancho de las columnas, se calcula como el ancho de columna * la cantidad de columnas
  double calculateRemainingSpace(BoxConstraints constraints) => constraints.maxWidth - (columnWidth * physicalPartitions.length) - hoursWidth;
  

  // Es una lista vertical que ocupa todo el alto. 
  // Para cuando es necesario tener una lista vacia, para que ese espacio siga pudiendose scrollear.
 
  Widget buildEmptyList(ScrollController controller) {
    return ListView.builder(
            controller: controller,
            itemCount: 1,
            itemBuilder: (context, index) {
                
              final height = horariosDisponibles.first.difference(horariosDisponibles.last).inMinutes.abs() * heightPerMinute;
              
              return SizedBox(
                height: height + 80
              );
            },                                    
        );
  }

  Column cardsLists(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildHeaders(context),
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

  Widget buildHeaders(BuildContext context) {

    if(physicalPartitions.isEmpty){
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text("No hay espacios cargados"),
      );
    } 
    return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: physicalPartitions
              .map((el) => buildPartitionHeader(el, context))
              .toList());
  }

  // Construye las listviews que dibujan las lineas verticales y horizontales
  Padding linesList() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Stack(
        children: [
          ListView.builder(
            
            controller: verticalColumnsScrollController,
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
                  color: isCurrentDivider ? Theme.of(context).colorScheme.primary : null,
                ),
              );
            },
            itemCount: horariosDisponibles.length,
          ),
          ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: horizontalLinesScrollController,
            itemBuilder: (context, index) {
              final now = DateTime.now();

              if (index < horariosDisponibles.length - 1 &&
                  horariosDisponibles[index].isBefore(now) &&
                  horariosDisponibles[index + 1].isAfter(now)) {}

              return SizedBox(
                  width: columnWidth.toDouble(),
                  child: const Row(
                    children: [
                      VerticalDivider(
                        width: 1,
                      ),
                    ],
                  ));
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
      width: hoursWidth,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: ListView.builder(
          controller: verticalLinesScrollController,
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
                        fontWeight: isCurrentDivider ? FontWeight.bold : null),
                  )
                ],
              ),
            );
          },
          itemCount: horariosDisponibles.length,
        ),
      ),
    );
  }

  Widget buildPartitionHeader(PhysicalPartition physicalPartition, context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child:Container(
        width: columnWidth- 16,
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

    if (currentPhysicalPartitionSessions.isEmpty) {
      return SizedBox(
        width: columnWidth.toDouble(),
        child: buildEmptyList(scrollControllers[physicalPartitions.indexOf(physicalPartition)]) ,
        
      );
    }

    return SizedBox(
      width: columnWidth.toDouble(),
      child: ListView.builder(
        controller: scrollControllers[physicalPartitions.indexOf(physicalPartition)],
        itemBuilder: (context, index) {
          double offsetPrevio = 0;
          double offsetFinal = 0;

          final currentSession = currentPhysicalPartitionSessions[index];
          late final Session previousSession;

          final int duration = currentSession.getDurationInMinutes();
          late final int previousDuration;


          if(index != 0){
            previousSession = currentPhysicalPartitionSessions[index - 1];
            previousDuration = previousSession.getDurationInMinutes();
          }
          

          if (index == 0) {
            offsetPrevio = currentSession.startTime
                    .difference(horariosDisponibles[0])
                    .inMinutes
                    .abs() *
                heightPerMinute;
          } else {
            offsetPrevio = (currentSession.startTime.difference(currentPhysicalPartitionSessions[index - 1].startTime).inMinutes.abs() - previousDuration) * heightPerMinute;
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

            showErrorMessage(previousSession, currentSession, context);
                      
            return const SizedBox();
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
                    height: duration * heightPerMinute.toDouble() -
                        heightPerMinute *
                            4, // Le resto 4 unidades de tiempo por el padding que se aplica luego de 2 arriba y abajo.
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

  void showErrorMessage(Session previousSession, Session currentSession, BuildContext context) {
    final text = "Hubo una superposicion entre ${DateFormat.jm().format(previousSession.startTime)} - ${DateFormat.jm().format(previousSession.startTime.add(Duration(minutes: previousSession.getDurationInMinutes()))) } y ${DateFormat.jm().format(currentSession.startTime)} - ${DateFormat.jm().format(currentSession.startTime.add(Duration(minutes: previousSession.getDurationInMinutes())))}";
              
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text))
      );
    });
  }
}
