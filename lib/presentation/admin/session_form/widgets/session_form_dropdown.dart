import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/form_builder/form_builder.dart';
import '../../../../core/utils/form_builder/form_builder_field.dart';
import '../../../../domain/entities/session.dart';

class SessionFormDropdown extends StatefulWidget {

  const SessionFormDropdown({super.key, this.session, required this.onCancel, required this.onSave});

  final Function() onCancel;
  final Function(TimeOfDay, TimeOfDay) onSave;

  final Session? session;

  @override
  State<SessionFormDropdown> createState() => _SessionFormDropdownState();
}

class _SessionFormDropdownState extends State<SessionFormDropdown> {

  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();


  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      onChanged: () {
          setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        height: 500,
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if(widget.session != null) const Text("Modificar Turno", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),),
                  if(widget.session == null) const Text("Agregar Turno",  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(       
                crossAxisAlignment: CrossAxisAlignment.start,     
                children: [
                   const SizedBox(height: 40,),
                   const Text("Horario del turno"),
                   const SizedBox(height: 16,),
                   CustomTimePicker(
                    name: "startTime",
                    initialHours: widget.session?.startTime.hour.toString(),
                    initialMinutes: widget.session?.startTime.minute.toString(),
                    onChange: (sessionStartTime) {},
                   ),
                   
                ],
              ),
            ),
            const SizedBox(height: 8,),
            const Divider(),
            const SizedBox(height: 8,),
            Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,     
                    children: [
                      const Text("Duracion del turno"),
                      const SizedBox(height: 16,),
                      CustomTimePicker(
                        name: "duration",
                        initialHours: widget.session?.duration != null ? widget.session?.duration.split(":")[0] : null,
                        initialMinutes: widget.session?.duration != null ? widget.session?.duration.split(":")[1] : null,
                        onChange: (duration) {},
      
                      )
                    ],
                  ),
            
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: widget.onCancel, child: Text("Cancelar"))),
                SizedBox(width: 16,),
                Expanded(child: FilledButton(onPressed: onPressedSave(), child: Text("Guardar")))
              ],
            )
          ],
        ),
      ),
    );
  }

  onPressedSave(){

    if(_formKey.currentState?.instantValue == null) return null;

    final values = _formKey.currentState!.instantValue;

    if(values['startTime'] == null || values['duration'] == null) return null;
    
    return (){
      widget.onSave(values['startTime'], values['duration']);
    };

  }
}

class CustomTimePicker extends StatefulWidget {

  final String? initialHours;
  final String? initialMinutes;
  final String name;

  CustomTimePicker({
    super.key, this.initialHours, this.initialMinutes, required this.onChange, required this.name,
  });

  final Function(TimeOfDay) onChange;

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  
  final hoursController = TextEditingController();
  final minutesController = TextEditingController();
  final GlobalKey<FormBuilderFieldState> fieldKey =
      GlobalKey<FormBuilderFieldState>();

  @override
  void initState() {
    // TODO: implement initState
    hoursController.text = widget.initialHours ?? '';
    minutesController.text = widget.initialMinutes ?? '';

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<TimeOfDay>(
      autovalidateMode: AutovalidateMode.always,
      initialValue: widget.initialHours != null && widget.initialMinutes != null ? TimeOfDay(hour: int.parse(widget.initialHours!), minute:int.parse(widget.initialMinutes!)) : null,
      key: fieldKey,
      validator: (value) {
        if(value == null) return "";
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
                onChanged: (value) {
                  final hours = value;
                  final minutes = minutesController.text;

                  if(validateHour(value) != null){
                    return field.didChange(null);
                  }
                  field.didChange(
                    TimeOfDay(hour: int.tryParse(hours) ?? 0, minute: int.tryParse(minutes) ?? 0)
                  );
                },
                controller: hoursController,
                validator: validateHour,
                maxLength: 2,
                expands: true,
                maxLines: null,
                keyboardType: TextInputType.number,
                textAlignVertical: TextAlignVertical.center,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 42),
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
                  errorText: field.errorText
                ),
              
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              height: 80,
              child:const Text(":", style: TextStyle(fontSize: 40),),
            ),
            SizedBox(
              height: 100,
              width: 100,
              child: TextFormField(
                onChanged: (value) {
                  final hours = hoursController.text;
                  final minutes = value;

                  if(validatorMinute(value) != null){
                    return field.didChange(null);
                  }
        
                  field.didChange(
                    TimeOfDay(hour: int.tryParse(hours) ?? 0, minute: int.tryParse(minutes) ?? 0)
                  );
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
                  errorText: field.errorText

                 ),
              
              ),
            )
        
          ],
        );
      }
    );
  }

  String? validatorMinute(value) {
            
            if(value == null || value == "") return "Inserte Los minutos";
  
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