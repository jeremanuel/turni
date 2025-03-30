import 'package:flutter/material.dart';

import '../../../../domain/entities/label.dart';

class Labelchip extends StatelessWidget {

  final Label label;
  final VoidCallback? onDelete;
  const Labelchip(this.label, {super.key, this.onDelete});

  @override
  Widget build(BuildContext context) {

    if(label.value == "Primer etiqueta"){
      print("test");
    }

    final labelColor = label.color ?? Theme.of(context).colorScheme.primaryContainer;

    final labelColorIsDark = ThemeData.estimateBrightnessForColor(labelColor) == Brightness.dark;

    final backgroundColor = adjustColorBrightness(labelColor);

    final borderColor = labelColor;

    return Chip(
      onDeleted: onDelete,
      deleteIcon: Icon(Icons.close),
      label: Text(
        label.value,
        style: TextStyle(
          color: _getContrastingTextColor(context, backgroundColor) ,
        ),
      ),
      backgroundColor: backgroundColor,
      visualDensity: const VisualDensity(vertical: -4),
      side: BorderSide(
        color: borderColor
      )
    );
  }

Color adjustColorBrightness(Color color, [double amount = 0.4, bool invert = false]) {
  final hsl = HSLColor.fromColor(color);
  
  // Si el color es oscuro (luminosidad < 0.5), aclararlo; si es brillante, oscurecerlo
  final adjustedLightness = hsl.lightness < 0.5
      ? (hsl.lightness + amount).clamp(0.0, 1.0)  // Aclara
      : (hsl.lightness - amount).clamp(0.0, 1.0); // Oscurece

  return hsl.withLightness(adjustedLightness).toColor();
}


  Color _getContrastingTextColor(context, Color backgroundColor) {

    final colorScheme = Theme.of(context).colorScheme;

    return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? colorScheme.onSurface
        : colorScheme.onPrimary;
  }

}