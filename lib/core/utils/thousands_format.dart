/// Separador de miles para valores monetarios (precios), convención es-AR:
/// punto cada 3 dígitos, coma para decimales (ej: $9.000, $9.000,50).
class ThousandsFormat {
  const ThousandsFormat._();

  static String group(String digits) {
    if (digits.isEmpty) return digits;
    final reversedChars = digits.split('').reversed.toList();
    final grouped = <String>[];
    for (var i = 0; i < reversedChars.length; i++) {
      if (i != 0 && i % 3 == 0) grouped.add('.');
      grouped.add(reversedChars[i]);
    }
    return grouped.reversed.join();
  }

  /// 9000 -> "9.000", 9000.5 -> "9.000,5". Sin decimales si no hace falta.
  static String formatPrice(num value) {
    final isNegative = value < 0;
    final absValue = value.abs();
    final integerPart = absValue.truncate();
    final integerText = group(integerPart.toString());

    final decimalPart = absValue - integerPart;
    if (decimalPart == 0) return '${isNegative ? '-' : ''}$integerText';

    final decimalDigits = (decimalPart * 100).round();
    final decimalText = decimalDigits % 10 == 0
        ? (decimalDigits ~/ 10).toString()
        : decimalDigits.toString().padLeft(2, '0');

    return '${isNegative ? '-' : ''}$integerText,$decimalText';
  }

  /// "9.000,50" -> 9000.5, "9000" -> 9000.0, "" -> null.
  static double? parsePrice(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return null;
    final normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }
}
