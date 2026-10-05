import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `TextFormField` para horarios: agrega el ":" y recorta hora/minuto a un
/// rango válido (00-23 / 00-59) a medida que se tipea (ej: 0830 -> 08:30).
/// Usar en cualquier campo de horario en vez de un `TextFormField` común.
class TimeField extends StatelessWidget {
  const TimeField({
    super.key,
    required this.controller,
    required this.decoration,
    this.validator,
    this.isDense = false,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: isDense ? decoration.copyWith(isDense: true) : decoration,
      keyboardType: TextInputType.number,
      inputFormatters: [_TimeInputFormatter()],
      validator: validator,
    );
  }
}

class _TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    if (digits.isEmpty) return const TextEditingValue(text: '');

    if (digits.length >= 2) {
      final hour = int.parse(digits.substring(0, 2)).clamp(0, 23);
      digits = hour.toString().padLeft(2, '0') + digits.substring(2);
    }
    if (digits.length >= 4) {
      final minute = int.parse(digits.substring(2, 4)).clamp(0, 59);
      digits = digits.substring(0, 2) + minute.toString().padLeft(2, '0');
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write(':');
      buffer.write(digits[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
