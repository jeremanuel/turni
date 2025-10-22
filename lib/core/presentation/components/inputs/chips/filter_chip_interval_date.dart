import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../presentation/client/session_manager_screen/session_feed/session_feed.dart';
import '../../../../utils/types/time_interval.dart';
import '../dropdown_widget.dart';

class FilterChipIntervalDate extends StatefulWidget {

  const FilterChipIntervalDate({
    super.key, 
    this.initialValue, 
    required this.onApply, 
    this.onCancel, 
    this.withSuggesttions = false, 
    this.label, this.initialSuggestion
  });

  final TimeInterval? initialValue;
  final int? initialSuggestion;
  final Function(TimeInterval) onApply;
  final Function()? onCancel;
  final bool withSuggesttions;
  final String? label;


  @override
  State<FilterChipIntervalDate> createState() => _FilterChipIntervalDateState();
}

class _FilterChipIntervalDateState extends State<FilterChipIntervalDate> {
  final DropdownController dropdownController = DropdownController();

  TimeInterval? interval;
  TimeInterval? selectedInterval;

  String? selectedSuggestion;
  bool rangoPersonalizado = false;

  final suggestions = [
    Suggestion(label: "Últimos 7 días", interval: TimeInterval(initialDate: DateTime.now().subtract(const Duration(days: 6)), endDate: DateTime.now()), type: SuggestionType.lastDays),
    Suggestion(label: "Últimos 15 días", interval: TimeInterval(initialDate: DateTime.now().subtract(const Duration(days: 14)), endDate: DateTime.now()), type: SuggestionType.lastDays),
    Suggestion(label: "Último mes", interval: TimeInterval(initialDate: DateTime(DateTime.now().year, DateTime.now().month -1, DateTime.now().day), endDate: DateTime.now()), type: SuggestionType.lastDays),
    ...List.generate(3, (index) {
      final now = DateTime.now();
      final monthDate = DateTime(now.year, now.month - index);
      final startOfMonth = DateTime(monthDate.year, monthDate.month);
      final endOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
      final monthName = DateFormat.MMMM('es').format(monthDate).capitalize();
      return Suggestion(label: monthName, interval: TimeInterval(initialDate: startOfMonth, endDate: endOfMonth), type: SuggestionType.month);
    })
  ];


  @override
  void initState() {
    interval = widget.initialValue;

    if(widget.initialSuggestion != null && widget.initialSuggestion! < suggestions.length) {
      selectedInterval = suggestions[widget.initialSuggestion!].interval;
      interval = selectedInterval;
      selectedSuggestion = suggestions[widget.initialSuggestion!].label;
    }
   
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownWidget(
      onClose: () => setState(() {
        rangoPersonalizado = false;
      }),
      
      dropdownController: dropdownController,
      menuWidget: buildCalendarView(),
      child: FilterChip(
        
      //  onDeleted: onDeleted(),
        label: buildLabel(context),
        
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

  Widget buildLabel(BuildContext context){
    
    if(selectedInterval?.initialDate != null || selectedInterval?.endDate != null){

      final separator = selectedInterval?.initialDate != null && selectedInterval?.endDate != null ? '-' : '';

      return Row(
        spacing: 8,
        children: [
          Icon(Icons.calendar_month_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20,),
          if(selectedSuggestion != null) Text(selectedSuggestion!),
          const VerticalDivider(),
          Text("${selectedInterval!.getInitialTextString()} $separator ${selectedInterval!.getEndTextString()}"),
          
          Icon(Icons.arrow_drop_down_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant,),
        ],
      );
    }

    
    return const Text("Seleccione una fecha de pago");
    
  }

  Widget buildCalendarView() {

    if(widget.withSuggesttions && !rangoPersonalizado){ 
      return ListView(
        shrinkWrap: true,
        children: [

          ...suggestions.where((element) => element.type == SuggestionType.lastDays,).map((e) => ListTile(
            selected: e.label == selectedSuggestion,
            dense: true,
            title: Text(e.label),
            onTap: () {
              widget.onApply(e.interval);
              selectedInterval = e.interval;
              interval = selectedInterval;
              dropdownController.hide!();
              selectedSuggestion = e.label;
              setState(() {});
            },
          )),

          const Divider(
            height: 1,
          ),
          ...suggestions.where((element) => element.type == SuggestionType.month,).map((e) => ListTile(
            dense: true,
            selected: e.label == selectedSuggestion,
            title: Text(e.label),
            onTap: () {
              widget.onApply(e.interval);
              selectedInterval = e.interval;
              interval = selectedInterval;
              dropdownController.hide!();
              selectedSuggestion = e.label;
              setState(() {});
            },
          )),
          const Divider(
            height: 1,
          ),
          ListTile(
            dense: true,
            title: const Text("Rango personalizado"),
            selected: "Rango personalizado" == selectedSuggestion,

            onTap: () {
              setState(() {
                rangoPersonalizado = true;
                selectedSuggestion = "Rango personalizado";
              });
              
            },
          )
        ],
      );
    }

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
              //firstDate: DateTime.now()
              
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


enum SuggestionType {
  lastDays,
  month,
  custom
}
class Suggestion {
  final String label;
  final TimeInterval interval;
  final SuggestionType type;

  Suggestion({
    required this.label,
    required this.interval,
    required this.type
  });
}