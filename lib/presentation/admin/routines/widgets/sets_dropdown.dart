import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../domain/entities/routine/routine_exercise.dart';
import '../cubit/new_routine_cubit.dart';

class SetsRepetitionsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Solo permitir dígitos y 'x'
    final filtered = text.replaceAll(RegExp(r'[^0-9x]'), '');
    
    // Si está vacío, permitirlo
    if (filtered.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Dividir por 'x'
    final parts = filtered.split('x');
    
    // Si hay más de una 'x', solo tomar las dos primeras partes
    if (parts.length > 2) {
      final formattedText = '${parts[0]}x${parts[1]}';
      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }
    
    // Si solo hay un dígito sin 'x', agregar 'x' automáticamente
    if (parts.length == 1 && filtered.length == 1 && !filtered.contains('x')) {
      final formattedText = '${filtered}x';
      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }
    
    // Si solo hay dígitos sin 'x' y tiene más de 1 dígito, insertar 'x' después del primer dígito
    if (parts.length == 1 && filtered.length > 1 && !filtered.contains('x')) {
      final formattedText = '${filtered[0]}x${filtered.substring(1)}';
      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }
    
    // Limitar cada parte a máximo 2 dígitos
    if (parts.length == 2) {
      final sets = parts[0].length > 1 ? parts[0].substring(0, 1) : parts[0];
      final reps = parts[1].length > 2 ? parts[1].substring(0, 2) : parts[1];
      final formattedText = '$sets${reps.isNotEmpty ? 'x$reps' : 'x'}';
      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }
    
    return newValue.copyWith(text: filtered);
  }
}

class SetsDropdown extends StatefulWidget {
  const SetsDropdown({super.key, required this.routineExercise, required this.routineGroupId});

  final int routineGroupId;
  final RoutineExercise routineExercise;

  @override
  State<SetsDropdown> createState() => _SetsDropdownState();
}

class _SetsDropdownState extends State<SetsDropdown> {

  final DropdownController dropdownController = DropdownController();
  final formKey = GlobalKey<FormBuilderState>();
  
  void _handleSubmit() {
    if (formKey.currentState?.validate() ?? false) {
      dropdownController.hide!();
      context.read<NewRoutineCubit>().updateExcercise(
        widget.routineGroupId,
        widget.routineExercise.id, 
        widget.routineExercise.copyWith(
          sets: formKey.currentState!.fields["series_repetitions"]!.value.split("x")[0].trim(),
          repetitions: formKey.currentState!.fields["series_repetitions"]!.value.split("x")[1].trim(),
          weight: formKey.currentState!.fields["weight"]!.value,
          observations: formKey.currentState!.fields["description"]!.value,
        )
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return DropdownWidget(
      width: 240, 
      menuWidget: Container(
        padding: const EdgeInsets.all(16),
        
        child: buildForm(),
      ), 
      dropdownController: dropdownController,
      child: SizedBox(
        width: 170,
        child: FilterChip(
          
          visualDensity: VisualDensity(vertical: -4, horizontal: -4),
          label: Row(
            spacing: 4,
            children: [
              if(widget.routineExercise.isComplete()) Expanded(child: buildLabelComplete()),
              if(!widget.routineExercise.isComplete()) const Expanded(child: Text("Series y pesos")),
              const Icon(Icons.arrow_drop_down),
            ],
          ), 
          onSelected: (value) => dropdownController.toggle!(),
        ),
      )
    );
  }

  Text buildLabelComplete(){

     return Text("${widget.routineExercise.sets}x${widget.routineExercise.repetitions} - ${widget.routineExercise.weight}kg${widget.routineExercise.observations != null ? " - ${widget.routineExercise.observations}" : "" }");
  }

  FocusTraversalGroup buildForm() {
    return FocusTraversalGroup(
        child: FormBuilder(
          initialValue: {
            "series_repetitions": widget.routineExercise.sets.isNotEmpty || widget.routineExercise.repetitions.isNotEmpty ? "${widget.routineExercise.sets} x ${widget.routineExercise.repetitions}" : null,
            "weight": widget.routineExercise.weight,
            "description": widget.routineExercise.observations,
          },
          key: formKey,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) {
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                _handleSubmit();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
              SizedBox(
                width: 200,
                child: FormBuilderTextField(
                  autofocus: true,
                  name: "series_repetitions",
                  validator: FormBuilderValidators.required(
                    errorText: "Campo obligatorio"
                  ),
                  inputFormatters: [ 
                    SetsRepetitionsFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: "Series x repeticiones*",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: FormBuilderTextField(
                  name: "weight",
                  keyboardType: const TextInputType.numberWithOptions(),
                  validator: FormBuilderValidators.required(
                    errorText: "Campo obligatorio"
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: InputDecoration(
                    labelText: "Peso*",
                    suffix: const Text("kg"),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                height: 100,
                child: FormBuilderTextField(
                  name: "description",
                  expands: true,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: "Descripcion",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _handleSubmit, 
                    child: const Text("Aceptar")
                  )
                ],
              )
            ],
          ),
        ),
        ),
      );
  }
}