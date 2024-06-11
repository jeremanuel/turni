import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../domain/entities/session.dart';
import '../../../core/custom_time_picker.dart';

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
        _formKey.currentState?.validate(focusOnInvalid: false);
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
                    autoFocus: true,
                    name: "startTime",
                    initialHours: widget.session?.startTime.hour.toString(),
                    initialMinutes: widget.session?.startTime.minute.toString(),
                    onSubmit: onSubmit,
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
                        initialHours: ((widget.session?.duration ?? 0) ~/ 60).toString(),
                        initialMinutes: widget.session?.duration != null ? (widget.session!.duration % 60).toString() : null,
                        onSubmit: onSubmit,      
                        isLastInput: true,
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

   onSubmit(value) {
    
    final isValid = _formKey.currentState!.validate();
    
    if(!isValid) return;

    final values = _formKey.currentState!.fields;

    if(!values['startTime']!.isValid || !values['duration']!.isValid) return KeyEventResult.ignored;

    widget.onSave(values['startTime']!.value, values['duration']!.value);

    return KeyEventResult.handled;
            
  }

   onPressedSave(){

    if(!(_formKey.currentState?.isValid ?? false)) return null;

    final values = _formKey.currentState!.fields;
    
    if(!values['startTime']!.isValid || !values['duration']!.isValid) return null;
    
    return (){
      widget.onSave(values['startTime']!.value, values['duration']!.value);
    };

  }
}

