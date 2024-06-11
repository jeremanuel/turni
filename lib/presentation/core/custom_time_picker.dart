import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';


class CustomTimePicker extends StatefulWidget {

  final String? initialHours;
  final String? initialMinutes;
  final String name;
  final bool autoFocus;
  final FocusNode? focusNode;
  final Function(String)? onSubmit;

  /// Usado para saber si tiene que hacer focus al siguiente input al rellenar los minutos.
  final bool isLastInput;

  const CustomTimePicker({
    super.key, 
    this.initialHours, 
    this.initialMinutes, 
    this.onChange, 
    required this.name, 
    this.autoFocus = false, 
    this.focusNode, 
    this.onSubmit,
    this.isLastInput = false
  });

  final Function(TimeOfDay)? onChange;

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  
  final hoursController = TextEditingController();
  final minutesController = TextEditingController();
  final GlobalKey<FormBuilderFieldState> fieldKey =
      GlobalKey<FormBuilderFieldState>();
  final FocusNode _fieldFocusNode = FocusNode();
  final FocusNode focusNodeMinutes = FocusNode();
  final minuteFieldKey = GlobalKey<FormFieldState>();
  final hourFieldKey = GlobalKey<FormFieldState>();

  @override
  void initState() {
    
    hoursController.text = widget.initialHours ?? '';
    minutesController.text = widget.initialMinutes ?? '';
 
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<TimeOfDay>(

      focusNode: _fieldFocusNode,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      initialValue: widget.initialHours != null && widget.initialMinutes != null ? TimeOfDay(hour: int.parse(widget.initialHours!), minute:int.parse(widget.initialMinutes!)) : null,
      key: fieldKey,
      validator: (value) {

        final isValidMinute = minuteFieldKey.currentState?.isValid ?? true;
        
        final isValidHour = hourFieldKey.currentState?.isValid ?? true;

        if(!isValidMinute || !isValidHour) return "";

        return null;
      }, 
      name: widget.name,
      builder: (field) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: TextFormField(
                focusNode: _fieldFocusNode,
                onFieldSubmitted: widget.onSubmit,
                key: minuteFieldKey,
                autofocus: widget.autoFocus,              
                onChanged: (value) {
                  final hours = value;
                  final minutes = minutesController.text;
    
                  final newValue = TimeOfDay(hour: int.tryParse(hours) ?? 0, minute: int.tryParse(minutes) ?? 0);
                  field.didChange(
                      newValue
                  );

                  if(value.length == 2){
                    focusNodeMinutes.requestFocus();
                  }
                },
                controller: hoursController,
                maxLength: 2,
                expands: true,
                maxLines: null,
                keyboardType: TextInputType.number,
                textAlignVertical: TextAlignVertical.center,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 42),
                validator: validateHour,
                decoration: InputDecoration(    
                  counterText: "",     
                  contentPadding: EdgeInsets.zero,                                            
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),                      
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary )
                  ),
                  helperText: "Hora",
                ),
              
              ),
            ),
            SizedBox(
              height: 80,
              width: 25,
              child: const Text(":", style: TextStyle(fontSize: 40 ), textAlign: TextAlign.center,)),
            SizedBox(
              height: 100,
              width: 100,
              child: TextFormField(
                onFieldSubmitted:  widget.onSubmit,
                key: hourFieldKey,
                focusNode: focusNodeMinutes,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (value) {
                  final hours = hoursController.text;
                  final minutes = value;        
          
                  final newValue = TimeOfDay(hour: int.tryParse(hours) ?? 0, minute: int.tryParse(minutes) ?? 0);
                  field.didChange(
                      newValue
                  );

                  if(!widget.isLastInput && value.length == 2 ){
                    Focus.of(context).nextFocus();
                  }
                },
                controller: minutesController,
                 validator: validatorMinute,
                maxLength: 2,
                expands: true,
                maxLines: null,
                keyboardType: TextInputType.number,
                textAlignVertical: TextAlignVertical.center,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 40),
                 decoration: InputDecoration(         
                  counterText: "",     
                  contentPadding: EdgeInsets.zero,                              
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),                      
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary )
                  ),
                  helperText: "Minutos",

                 ),
              
              ),
            )
        
          ],
        );
      }
    );
  }

  String? validatorMinute(value) {
            
            if(value == null || value == "") return "Inserte minutos";
  
            final intValue = int.tryParse(value);
  
            if(intValue == null) return "Valor incorrecto";
  
            if(intValue > 59 || intValue < 0) return "Valor fuera de rango"; 
          }

  String? validateHour(value) {
            if(value == null || value == "") return "Inserte una hora";
  
            final intValue = int.tryParse(value);
  
            if(intValue == null) return "Valor incorrecto";
  
            if(intValue > 23 || intValue < 0) return "Valor fuera de rango";
  
            return null; 
          }
}