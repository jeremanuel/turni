import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../utils/types/time_interval.dart';
import '../dropdown_widget.dart';

class FilterChipIntervalDate extends StatefulWidget {
  const FilterChipIntervalDate({super.key, this.initialValue, required this.onApply, this.onCancel});

  final TimeInterval? initialValue;
  final Function(TimeInterval) onApply;
  final Function()? onCancel;

  @override
  State<FilterChipIntervalDate> createState() => _FilterChipIntervalDateState();
}

class _FilterChipIntervalDateState extends State<FilterChipIntervalDate> {
  final DropdownController dropdownController = DropdownController();

  TimeInterval? interval;
  TimeInterval? selectedInterval;


  @override
  void initState() {
    interval = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownWidget(
      dropdownController: dropdownController,
      menuWidget: buildCalendarView(),
      child: InputChip(
        onDeleted: onDeleted(),
        label: buildLabel(),
        onSelected: (value) {
          dropdownController.toggle!();
        },
      ),
    );
  }

  Function()? onDeleted() {

    if(selectedInterval == null) return null; 

    return (){
          selectedInterval = null;
          interval = null;
          setState(() {});
          widget.onApply(TimeInterval());
      };
  }

  Text buildLabel(){
    
    if(selectedInterval?.initialDate != null || selectedInterval?.endDate != null){

      final separator = selectedInterval?.initialDate != null && selectedInterval?.endDate != null ? '-' : '';

      return Text("${selectedInterval!.getInitialTextString()} $separator ${selectedInterval!.getEndTextString()}");
    }

    
    return const Text("Seleccione Fecha");
    
  }

  Widget buildCalendarView() {
    return SizedBox(
      height: 400,
      width: 300,
      child: Column(
        children: [
          buildHeaderLabel(),
          Expanded(
            child: CalendarDatePicker2(
            config: CalendarDatePicker2Config(
              calendarType: CalendarDatePicker2Type.range,
              firstDate: DateTime.now()
              
            ), 
            value: interval?.toArray() ?? [],
            onValueChanged: (value) {
              setState(() {
                interval = TimeInterval.fromArray(value);
              });
            },
                  ),
          ),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: (){
                  dropdownController.hide!();
                  setState(() {
                    interval = selectedInterval;
                  });
                }, child: const Text("Cancelar")),
                const SizedBox(width: 8,),
                TextButton(
                  onPressed: interval == null || interval!.endDate == null && interval!.initialDate == null ? null : (){
                  widget.onApply(interval!);
                  setState(() {
                    selectedInterval = interval;        
                  });
                  dropdownController.hide!();
                }, 
                child: const Text("Aplicar"))

              ],
            ),
          )
      
        ],
      ),
    );
  }

  Widget buildHeaderLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal:24, vertical: 10),
      height: 60,
      child: Row(
          children: [
            if(interval?.initialDate == null) const Text("Inicio"),
            if(interval?.initialDate != null) Text(DateFormat.MMMd().format(interval!.initialDate!)),
            const Text(" - "),
            if(interval?.endDate == null) const Text("Fin"),
            if(interval?.endDate != null) Text(DateFormat.MMMd().format(interval!.endDate!)),
      
          ],
        ),
    );
  }
}