import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `TextFormField` para duraciones en minutos: muestra como `helperText`
/// la traducción legible (ej: 90 -> "1h 30m"), actualizada a medida que se
/// tipea. Usar en cualquier campo de duración en vez de un `TextFormField`
/// numérico común.
class DurationMinutesField extends StatefulWidget {
  const DurationMinutesField({
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
  State<DurationMinutesField> createState() => _DurationMinutesFieldState();
}

class _DurationMinutesFieldState extends State<DurationMinutesField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String? _helperText() {
    final minutes = int.tryParse(widget.controller.text.trim());
    if (minutes == null || minutes <= 0) return null;

    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '${remainder}m';
    if (remainder == 0) return '${hours}h';
    return '${hours}h ${remainder}m';
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: widget.decoration.copyWith(
        isDense: widget.isDense ? true : widget.decoration.isDense,
        helperText: _helperText(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: widget.validator,
    );
  }
}
