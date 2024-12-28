import 'package:flutter/material.dart';

import '../../../../domain/entities/label.dart';

class Labelchip extends StatelessWidget {

  final Label label;
  const Labelchip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label.value,
        style: TextStyle(
          color: _getContrastingTextColor(context, label.color ?? Theme.of(context).colorScheme.primaryContainer),
        ),
      ),
      backgroundColor: label.color ?? Theme.of(context).colorScheme.primaryContainer,
      visualDensity: const VisualDensity(vertical: -4),
      side: BorderSide.none,
    );
  }

  Color _getContrastingTextColor(context, Color backgroundColor) {

    final colorScheme = Theme.of(context).colorScheme;

    return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? colorScheme.onSurface
        : colorScheme.onPrimary;
  }
}