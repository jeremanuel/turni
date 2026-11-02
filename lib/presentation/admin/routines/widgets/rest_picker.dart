import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/gym/gym.dart';

/// Descansos que se ofrecen de una (en segundos).
const restPresets = [45, 60, 90, 120, 180, 240];

/// Descanso entre series de un ejercicio. Es opcional: sin definir, el
/// cliente arranca con lo último que descansó en ese ejercicio (o con el de
/// la app). Un menú con los valores de siempre, "Otro…" y "Sin definir".
class RestPicker extends StatelessWidget {
  const RestPicker({
    super.key,
    required this.exerciseName,
    required this.value,
    required this.onChanged,
    this.height = 40,
  });

  final String exerciseName;
  final int? value;
  final ValueChanged<int?> onChanged;
  final double height;

  Future<void> _other(BuildContext context) async {
    final seconds = await showDialog<int>(
      context: context,
      builder: (_) => _OtherRestDialog(exerciseName: exerciseName, initial: value),
    );
    if (seconds != null) onChanged(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final value = this.value;
    // Un ítem con valor null cuenta como cancelar: "Otro…" y "Sin definir" van con marcas.
    const other = -1;
    const none = -2;
    return PopupMenuButton<int>(
      tooltip: 'Descanso de $exerciseName',
      initialValue: value ?? none,
      onSelected: (selected) {
        if (selected == other) {
          _other(context);
        } else {
          onChanged(selected == none ? null : selected);
        }
      },
      itemBuilder: (_) => [
        for (final seconds in restPresets) PopupMenuItem<int>(value: seconds, child: Text(formatRest(seconds))),
        const PopupMenuItem<int>(value: other, child: Text('Otro…')),
        const PopupMenuDivider(),
        const PopupMenuItem<int>(value: none, child: Text('Sin definir')),
      ],
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: value == null ? colorScheme.outlineVariant : colorScheme.outline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? 'Sin definir' : formatRest(value),
                textAlign: TextAlign.center,
                style: (value == null ? textTheme.bodyMedium : textTheme.titleSmall)?.copyWith(
                  color: value == null ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 20, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

class _OtherRestDialog extends StatefulWidget {
  const _OtherRestDialog({required this.exerciseName, required this.initial});

  final String exerciseName;
  final int? initial;

  @override
  State<_OtherRestDialog> createState() => _OtherRestDialogState();
}

class _OtherRestDialogState extends State<_OtherRestDialog> {
  late final _controller = TextEditingController(text: widget.initial == null ? '' : formatRest(widget.initial!));
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final seconds = parseRest(_controller.text);
    if (seconds == null) {
      setState(() => _error = 'Escribilo como minutos:segundos (2:30), hasta ${maxRestSeconds ~/ 60}:00.');
      return;
    }
    Navigator.of(context).pop(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text('Descanso de ${widget.exerciseName}'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entre series', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'))],
              decoration: InputDecoration(hintText: '2:30', errorText: _error, border: const OutlineInputBorder()),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Listo')),
      ],
    );
  }
}
