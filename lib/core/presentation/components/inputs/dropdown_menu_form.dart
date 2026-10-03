import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class DropdownMenuForm<T> extends StatelessWidget {

   const DropdownMenuForm({
    super.key,
    required this.name,
    required this.dropdownMenuEntries, 
    this.initialValue,
    
  });


  final String name;
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;
  final T? initialValue;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<T>(
      name: name,
      initialValue: initialValue,
      builder: (field) {
        return DropdownMenu<T>(
          menuHeight: 300,
          alignmentOffset: const Offset(190, 35) ,
          enableFilter: true,
          initialSelection: field.value,
          dropdownMenuEntries: dropdownMenuEntries,
          onSelected: field.didChange
        );
      },
    );
  }
}