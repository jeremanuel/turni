import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/thousands_format.dart';

/// `TextFormField` para precios: agrega el separador de miles a medida que
/// se tipea (ej: 9000 -> 9.000). Usar en cualquier campo de precio en vez de
/// un `TextFormField` numérico común; leer el valor con
/// `ThousandsFormat.parsePrice`, no con `double.tryParse`.
class PriceField extends StatelessWidget {
  const PriceField({
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
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_ThousandsInputFormatter()],
      validator: validator,
    );
  }
}

class _ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final commaIndex = text.indexOf(',');

    if (commaIndex == -1) {
      final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return const TextEditingValue(text: '');
      final formatted = ThousandsFormat.group(digits);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    final integerRaw = text.substring(0, commaIndex).replaceAll(RegExp(r'[^0-9]'), '');
    var decimalRaw = text.substring(commaIndex + 1).replaceAll(RegExp(r'[^0-9]'), '');
    if (decimalRaw.length > 2) decimalRaw = decimalRaw.substring(0, 2);

    final formattedInteger = integerRaw.isEmpty ? '0' : ThousandsFormat.group(integerRaw);
    final formatted = '$formattedInteger,$decimalRaw';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
