import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatesCarrousel extends StatefulWidget {
  
  DatesCarrousel({super.key, initialDate, required this.onSelect, this.containerWidth = 300, this.datesCarrouselController}) : initialDate = initialDate ?? DateTime.now(); 
  
  
  final double width = 200;
  final DateTime initialDate;
  final Function(DateTime) onSelect;
  final double containerWidth;
  final DatesCarrouselController? datesCarrouselController;

  final daysAfter = 20;
  final daysBefore = 5;
  final itemWidth = 66;

  @override
  State<DatesCarrousel> createState() => _DatesCarrouselState();
}

class _DatesCarrouselState extends State<DatesCarrousel> {
  
  late DateTime selectedDate;

  late final ScrollController scrollController;
  late List<DateTime> dates; 

  @override
  void initState() {

    selectedDate = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);// widget.initialDate;

    dates = generateDateArray(selectedDate, widget.daysBefore, widget.daysAfter); 


    scrollController = ScrollController(
      initialScrollOffset: (widget.itemWidth * widget.daysBefore).toDouble() - (widget.containerWidth - (widget.itemWidth / 2)) / 2
    );

    widget.datesCarrouselController?.setDate = (date){
      setState(() {
        selectedDate = DateTime(date.year, date.month, date.day);
      });
    };
  
    super.initState();
  }

  List<DateTime> generateDateArray(DateTime initialDate, int daysBefore, int daysAfter) {
  List<DateTime> dates = [];

  // Agregar las fechas antes de initialDate
  for (int i = daysBefore; i > 0; i--) {
    dates.add(initialDate.subtract(Duration(days: i)));
  }

  // Agregar initialDate
  dates.add(initialDate);

  // Agregar las fechas después de initialDate
  for (int i = 1; i <= daysAfter; i++) {
    dates.add(initialDate.add(Duration(days: i)));
  }

  return dates;
}
  generateDates(DateTime start, DateTime end) {
    List<DateTime> dates = [];
    DateTime currentDate = start;
    
    while (currentDate.isBefore(end)) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.containerWidth,
      child: buildList(context)
    );
  }

  ScrollConfiguration buildList(BuildContext context) {
    return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: PointerDeviceKind.values.toSet(),
        ),
        child: ListView.separated(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: dates.length,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          addRepaintBoundaries: false,
        
          itemBuilder: (context, index) {
            
            return buildItem(index);
          }),
      );
  }

  /// Los items en una Listview utilizan todo el espacio en su dimension cruzada (En este caso, utilizan todo el alto)
  /// Por eso lo encierro en un center, y su child determina dimensiones. Asi se centran con respecto a todo el ancho del item (dado por el ancho de la lista)
  Widget buildItem(int index) { 
    
    final selectedIndex = dates.indexOf(selectedDate);

  
    return Center(
      child: SizedBox(
        height: selectedIndex == index ? 55 : 50,
        width: selectedIndex == index ? 55 : 50,
        child: Material(
          child: InkWell(
            customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
            ),
            onTap: () {
              setState(() {
                selectedDate = dates[index];
              });
        
              widget.onSelect(selectedDate);
            },
            child: Ink(
                
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: selectedIndex == index ? Colors.white : const Color.fromRGBO(103, 43, 234, 1)
                ),
                width: index == selectedIndex ? 51 : 45,
                height: index == selectedIndex ? 51 : 45,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,              
                  children: [
                      Text(DateFormat.E().format(dates[index]), style: TextStyle(color: index == selectedIndex ? const Color.fromRGBO(103, 43, 234, 1) : Colors.white),),
                      Text(dates[index].day.toString(), style: TextStyle(color: index == selectedIndex ? const Color.fromRGBO(103, 43, 234, 1) : Colors.white),),                  
                  ],
                ),
              ),
          ),
        ),
      ),
    );
  }
}

class DatesCarrouselController {
  void Function(DateTime)? setDate;
}