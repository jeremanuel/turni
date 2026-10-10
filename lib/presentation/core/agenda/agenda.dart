import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/utils/permissions.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/router/app_routes.dart';
import '../../../core/utils/types/time_interval.dart';
import '../../../domain/entities/physical_partition.dart';
import '../../../domain/entities/session.dart';

class Agenda extends StatelessWidget {
  Agenda(
      {super.key,
      required List<Session> sessions,
      required this.buildCard,
      this.heightPerMinute = 2,
      required this.physicalPartitions,
      required this.partitionLabelBuilder,
      required this.fromDate,
      required this.lastDate,
      this.columnWidth = 300,
      this.onBlankSpaceTap,
      this.partitionSubtitleBuilder,
      this.showNowIndicator = false,

      }) : sessions = [...sessions]
          ..sort((a, b) => a.startTime.compareTo(b.startTime)) {
    horariosDisponibles = generateDates(fromDate, lastDate);
    scrollControllers = generateScrollControllers();
    initializeScrollControllerListeners();
  }

  final List<Session> sessions;
  final Widget Function(Session, PhysicalPartition, double) buildCard;
  final List<PhysicalPartition> physicalPartitions;
  final String Function(PhysicalPartition) partitionLabelBuilder;
  final double heightPerMinute;
  final DateTime fromDate;
  final DateTime lastDate;
  final double columnWidth;
  final double hoursWidth = 64;

  /// Si se pasa, se usa en vez de la navegacion default a
  /// SESSION_MANAGER_ADD_ROUTE cuando se toca un espacio vacio — para
  /// reusar esta misma grilla en pantallas donde "agregar" no debe navegar
  /// afuera (ej. el paso "Canchas" de la carga masiva).
  final void Function(PhysicalPartition, TimeInterval)? onBlankSpaceTap;

  /// Segunda linea opcional en el header de cada columna (ej. capacidad de
  /// jugadores) — null mantiene el header de una sola linea de siempre.
  final String Function(PhysicalPartition)? partitionSubtitleBuilder;

  /// Dibuja la línea de "ahora" (punto + línea `tertiary`) a la altura exacta
  /// de la hora actual, si el día mostrado es hoy. Apagado por defecto: en
  /// la plantilla del agregador de turnos no tiene sentido.
  final bool showNowIndicator;

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
 
  Widget buildEmptyList(ScrollController controller, [PhysicalPartition? physicalPartition]) {
    return ListView.builder(
            controller: controller,
            itemCount: 1,
            itemBuilder: (context, index) {
                
              final height = horariosDisponibles.first.difference(horariosDisponibles.last).inMinutes.abs() * heightPerMinute;
              
              return BlankSpace(
                canHover: physicalPartition?.durationInMinutes != null,
                height: height + 80,
                minHeightToHover: 0,
                physicalPartition: physicalPartition,
                blankSpaceTimeInterval: TimeInterval(initialDate: horariosDisponibles.first, endDate: horariosDisponibles.last),
                onTap: onBlankSpaceTap,
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
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              children: physicalPartitions
                  .map((el) => buildPartitionColumn(el, context))
                  .toList(),
            ),
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
      padding: EdgeInsets.only(top: headerHeight),
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

              final divider = SizedBox(
                height: heightPerMinute * 30,
                child: Divider(
                  color: isCurrentDivider ? Theme.of(context).colorScheme.primary : null,
                ),
              );

              final isToday = DateUtils.isSameDay(fromDate, now);
              if (!showNowIndicator || !isCurrentDivider || !isToday) return divider;

              // Cada fila mide 30 min y su divisor (centro de la fila) es la
              // hora de `horariosDisponibles[index]`: la línea de "ahora" va
              // desplazada desde ese centro según los minutos transcurridos.
              final minutesIn = now.difference(horariosDisponibles[index]).inSeconds / 60;
              final top = heightPerMinute * 15 + minutesIn * heightPerMinute;
              final tertiary = Theme.of(context).colorScheme.tertiary;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  divider,
                  Positioned(
                    left: 0,
                    right: 0,
                    top: top - 4,
                    child: IgnorePointer(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: tertiary, shape: BoxShape.circle),
                          ),
                          Expanded(child: Container(height: 2, color: tertiary)),
                        ],
                      ),
                    ),
                  ),
                ],
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
        padding: EdgeInsets.only(top: headerHeight),
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

  /// Alto de la fila de encabezados de cancha. Con subtítulo ("Cubierta ·
  /// 4 jug.") necesita dos líneas: nombre 14px + bajada 12px + margen.
  double get headerHeight => partitionSubtitleBuilder == null ? 40 : 52;

  Widget buildPartitionHeader(PhysicalPartition physicalPartition, context) {
    final subtitle = partitionSubtitleBuilder?.call(physicalPartition);
    final scheme = Theme.of(context).colorScheme;

    if (subtitle != null) {
      return SizedBox(
        width: columnWidth,
        height: headerHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                partitionLabelBuilder(physicalPartition),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child:Container(
        width: columnWidth- 16,
        height: 40 - 16,
        decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha:0.5),
              borderRadius: BorderRadius.circular(4),
        ),

        child: Center(child: Text(partitionLabelBuilder(physicalPartition))),
      ),
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
        child: buildEmptyList(scrollControllers[physicalPartitions.indexOf(physicalPartition)], physicalPartition) ,
        
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

          final int duration = currentSession.getDurationInMinutes();

          int? previousDuration;
          Session? previousSession;
          
          DateTime previousBlankSpaceStartTime;


          if(index != 0){
            previousSession = currentPhysicalPartitionSessions[index - 1];
            previousDuration = previousSession.getDurationInMinutes();
            previousBlankSpaceStartTime = previousSession.endTime;
          } else {
            previousBlankSpaceStartTime = horariosDisponibles[0];
          }

     

          
          

          if (index == 0) {
            offsetPrevio = currentSession.startTime
                    .difference(horariosDisponibles[0])
                    .inMinutes
                    .abs() *
                heightPerMinute;

            
          } else {
            offsetPrevio = (currentSession.startTime.difference(currentPhysicalPartitionSessions[index - 1].startTime).inMinutes.abs() - previousDuration!) * heightPerMinute;
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

            showErrorMessage(previousSession!, currentSession, context);
                      
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
                if(offsetPrevio > 0)
                  BlankSpace(
                    canHover: physicalPartition.durationInMinutes != null,
                    height: offsetPrevio,
                    minHeightToHover: (physicalPartition.durationInMinutes ?? 0) * heightPerMinute,
                    physicalPartition: physicalPartition,
                    blankSpaceTimeInterval: TimeInterval(
                      initialDate: previousBlankSpaceStartTime,
                      endDate: currentSession.startTime
                    ),
                    onTap: onBlankSpaceTap,
                  ),

                SizedBox(
                    height: duration * heightPerMinute.toDouble() -
                        heightPerMinute *
                            4, // Le resto 4 unidades de tiempo por el padding que se aplica luego de 2 arriba y abajo.
                    child: buildCard(currentSession, physicalPartition, duration * heightPerMinute.toDouble() -
                        heightPerMinute *
                            4)
                ),
  
                if (index == currentPhysicalPartitionSessions.length - 1)
                  BlankSpace(
                    canHover: physicalPartition.durationInMinutes != null,
                    height: offsetFinal.toDouble(),
                    minHeightToHover: (physicalPartition.durationInMinutes ?? 0) * heightPerMinute,
                    physicalPartition: physicalPartition,
                    blankSpaceTimeInterval: TimeInterval(
                      initialDate: currentSession.endTime,
                      endDate: horariosDisponibles.last
                    ),
                    onTap: onBlankSpaceTap,
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

class BlankSpace extends StatefulWidget {
    
    const BlankSpace({
    super.key,
    required this.canHover,
    required this.height,
    required this.minHeightToHover,
    this.blankSpaceTimeInterval,
    this.physicalPartition,
    this.onTap,
  });


  final bool canHover;
  final double height;
  final double minHeightToHover;
  final TimeInterval? blankSpaceTimeInterval;
  final PhysicalPartition? physicalPartition;
  final void Function(PhysicalPartition, TimeInterval)? onTap;


  @override
  State<BlankSpace> createState() => _BlankSpaceState();
}

class _BlankSpaceState extends State<BlankSpace> {

  bool isHovered = false;

  @override
  Widget build(BuildContext context) {

    if(!widget.canHover || widget.height < widget.minHeightToHover){
      return SizedBox(height: widget.height);
    }

    const childHovered = Center(
            child: Icon(Icons.add)
          );

    Widget childNotHovered = const Center(child: SizedBox());

    DateFormat dateFormat = DateFormat("HH:mm");

    return MouseRegion(
      cursor: SystemMouseCursors.click,

      onEnter: (event) {
        setState(() {
          isHovered = true;
        });
      },
      onExit: (event) {
        setState(() {
          isHovered = false;
        });
      },      
      child: InkWell(
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!(widget.physicalPartition!, widget.blankSpaceTimeInterval!);
            return;
          }
          // Espacio vacío = crear un turno.
          if (!Permissions.can(Permissions.AGENDA_CREAR)) return;
          context.goNamed(
            AppRoutes.SESSION_MANAGER_ADD_ROUTE.name,
            pathParameters:{
              "idPhysicalPartition":widget.physicalPartition!.partitionPhysicalId.toString()
            },
            queryParameters: {
              "start": dateFormat.format(widget.blankSpaceTimeInterval!.initialDate!),
              'end':dateFormat.format(widget.blankSpaceTimeInterval!.endDate!)
            },
          );
        },
        child: SizedBox(
          height: widget.height.toDouble(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Center(
              child: isHovered ? childHovered : childNotHovered,
            ),
          )                       
        ),
      ));
  }
}
