import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatesCarrousel extends StatefulWidget {
  
  DatesCarrousel({super.key, initialDate, required this.onSelect}) : initialDate = initialDate ?? DateTime.now(); 
  
  
  final double width = 200;
  final DateTime initialDate;
  final Function(DateTime) onSelect;
  @override
  State<DatesCarrousel> createState() => _DatesCarrouselState();
}

class _DatesCarrouselState extends State<DatesCarrousel> {
  
  late DateTime selectedDate;

  final scrollController = ScrollController(initialScrollOffset: (61 * 4) / 2);
  late List<DateTime> dates; 

  @override
  void initState() {

    selectedDate = widget.initialDate;

    dates = [

    widget.initialDate.subtract(const Duration(days: 4)),
    widget.initialDate.subtract(const Duration(days: 3)),
    widget.initialDate.subtract(const Duration(days: 2)),
    widget.initialDate.subtract(const Duration(days: 1)),
    widget.initialDate,
    widget.initialDate.add(const Duration(days: 1)),
    widget.initialDate.add(const Duration(days: 2)),
    widget.initialDate.add(const Duration(days: 3)),
    widget.initialDate.add(const Duration(days: 4)),
  ];
    
    scrollController.addListener(() {
      
       if(scrollController.offset == 0){

        setState(() {
          dates = [...generateDates(dates.first.subtract(const Duration(days: 4)), dates.first), ...dates];
        });
        
        //scrollController.jumpTo(scrollController.position.minScrollExtent + (61 * 4));
      } 
      if(scrollController.offset == scrollController.position.maxScrollExtent){

        setState(() {
          dates = [ ...dates, ...generateDates(dates.last.add( const Duration(days: 1)), dates.last.add(const Duration(days: 4)) ),];
          scrollController.jumpTo(scrollController.position.maxScrollExtent);          
        });
      }
    });
  
    super.initState();
  }

  generateDates(DateTime start, DateTime end) {
    List<DateTime> dates = [];
    DateTime currentDate = start;
    while (currentDate.isBefore(end)) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    print(dates);
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    return buildList(context);
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

  Widget buildItem(int index) {
    
    final selectedIndex = dates.indexOf(selectedDate);

    return Padding(
      padding:  EdgeInsets.symmetric(vertical: selectedIndex == index ? 0 : 3),
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
    );
  }
}