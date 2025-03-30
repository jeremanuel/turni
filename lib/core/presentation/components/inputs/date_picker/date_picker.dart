import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../utils/date_functions.dart';
import '../dropdown_widget.dart';

class DatePicker extends StatefulWidget {
  const DatePicker({super.key, required this.name, this.initialValue, required this.inputDecoration});

  final String name;
  final DateTime? initialValue;
  final InputDecoration inputDecoration;

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {

  final DropdownController dropdownController = DropdownController();
  late final TextEditingController textEditingController;

  @override
  void initState() {
    final parentFormBuilder = FormBuilder.of(context);

    final initialValue = parentFormBuilder?.initialValue[widget.name];

    if(initialValue != null && initialValue is DateTime){
      textEditingController = TextEditingController(text: DateFunctions.formatDateToDefaultFormat(initialValue));
    } else {
      textEditingController = TextEditingController();
    }

    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return FormBuilderField<DateTime?>(
      onChanged: (value) {

        textEditingController.value = TextEditingValue(text: value != null ?DateFunctions.formatDateToDefaultFormat(value) : "", selection: textEditingController.value.selection);
      },
      builder: (field) {
        
        return DropdownWidget(
          obscureBackground: false,
          menuWidget: MenuWidget(field: field, dropdownController: dropdownController), dropdownController: dropdownController,
          child: ChildWidget(dropdownController: dropdownController, field: field, textEditingController: textEditingController, inputDecoration: widget.inputDecoration,)
        );

      }, 
      name: widget.name
    );
  }
}

class MenuWidget extends StatelessWidget {
  
  const MenuWidget({
    super.key, 
    required this.field, 
    required this.dropdownController,
  });

  final FormFieldState<DateTime?> field;
  final DropdownController dropdownController;

  @override
  Widget build(BuildContext context) {
    return CalendarDatePicker2(
      config: CalendarDatePicker2Config(), 
      value: [field.value ?? DateTime.now()], 
      onValueChanged: (value) {
        field.didChange(value.first);
        dropdownController.hide!();
      });
  }
}

class ChildWidget extends StatelessWidget {

  const ChildWidget({
    super.key, required this.field, required this.dropdownController, required this.textEditingController, required this.inputDecoration,
  });

  final FormFieldState<DateTime?> field;
  final DropdownController dropdownController;
  final TextEditingController textEditingController;
  final InputDecoration inputDecoration;
  @override
  Widget build(BuildContext context) {
    
    return TextFormField(
      inputFormatters: <TextInputFormatter>[
    FilteringTextInputFormatter.allow(
        RegExp(r'[0-9\/]{0,10} ?[0-9]{0,2}:?[0-9]{0,2}')),
      
  ],
  
      onChanged: (value) {
        if(value.isEmpty) return field.didChange(null);

        final date = DateFunctions.tryParseDate(value);

        if(date == null) return FormBuilder.of(context)!.fields['bird_date']!.invalidate("Fecha invalida", shouldFocus: false);

        field.validate();
        
        field.didChange(date);
      },
      decoration: inputDecoration.copyWith(
        helperText: field.value == null ? null : ("${DateFunctions.differenceInYears(field.value!)} años"),
        suffixIcon: field.value != null ? IconButton(onPressed: (){field.didChange(null);}, icon: Icon(Icons.close)) : null,
        errorText: field.errorText,
        errorStyle: TextStyle(fontSize: 10, height: 0.8)
      ),
      controller: textEditingController,
      onTap: () {
        dropdownController.show!();
      },
    );
  }
}



class DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), ''); // Solo números
    String formatted = '';
    int cursorPosition = newValue.selection.end;

    if (text.length > 0) {
      formatted += text.substring(0, text.length > 2 ? 2 : text.length);
      if (text.length > 2) formatted += '/';
    }
    if (text.length > 2) {
      formatted += text.substring(2, text.length > 4 ? 4 : text.length);
      if (text.length > 4) formatted += '/';
    }
    if (text.length > 4) {
      formatted += text.substring(4, text.length > 8 ? 8 : text.length);
    }

    // Ajustar la posición del cursor
    if (cursorPosition > formatted.length) {
      cursorPosition = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}