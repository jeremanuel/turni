import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/gym/gym.dart';

/// Series de un ejercicio, una por una (pirámides, series distintas).
/// Devuelve las series nuevas, o null si se canceló.
Future<List<Serie>?> showSeriesDialog(BuildContext context, {required String exerciseName, required List<Serie> series}) {
  return showDialog<List<Serie>>(
    context: context,
    builder: (_) => _SeriesDialog(exerciseName: exerciseName, initial: series),
  );
}

class _Row {
  _Row(Serie serie)
      : reps = TextEditingController(text: '${serie.reps}'),
        kg = TextEditingController(text: formatKg(serie.weightKg));

  final TextEditingController reps;
  final TextEditingController kg;

  Serie? get value {
    final r = int.tryParse(reps.text.trim());
    final w = kg.text.trim().isEmpty ? 0.0 : parseKg(kg.text);
    if (r == null || r < 0 || w == null) return null;
    return Serie(reps: r, weightKg: w);
  }

  void set(Serie serie) {
    reps.text = '${serie.reps}';
    kg.text = formatKg(serie.weightKg);
  }

  void dispose() {
    reps.dispose();
    kg.dispose();
  }
}

class _SeriesDialog extends StatefulWidget {
  const _SeriesDialog({required this.exerciseName, required this.initial});

  final String exerciseName;
  final List<Serie> initial;

  @override
  State<_SeriesDialog> createState() => _SeriesDialogState();
}

class _SeriesDialogState extends State<_SeriesDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<_Row> _rows = (widget.initial.isEmpty ? [const Serie(reps: 10, weightKg: 0)] : widget.initial).map(_Row.new).toList();

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Serie get _first => _rows.first.value ?? const Serie(reps: 10, weightKg: 0);

  void _addSerie() => setState(() => _rows.add(_Row(_rows.last.value ?? _first)));

  void _pyramid() {
    final base = _first;
    setState(() {
      for (var i = 0; i < _rows.length; i++) {
        _rows[i].set(Serie(reps: (base.reps - 2 * i).clamp(1, 999), weightKg: base.weightKg + 2.5 * i));
      }
    });
  }

  void _copyFirst() {
    final base = _first;
    setState(() {
      for (final row in _rows.skip(1)) {
        row.set(base);
      }
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_rows.map((r) => r.value!).toList());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final current = _rows.map((r) => r.value).whereType<Serie>().toList();

    String? validateReps(String? value) {
      final reps = int.tryParse(value?.trim() ?? '');
      return reps == null || reps < 0 || reps > 999 ? 'Entre 0 y 999' : null;
    }

    String? validateKg(String? value) {
      if (value == null || value.trim().isEmpty) return null;
      final kg = parseKg(value);
      return kg == null || kg > 1000 ? 'Entre 0 y 1000' : null;
    }

    return AlertDialog(
      title: Text(widget.exerciseName),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(current.length == _rows.length ? seriesLabel(current) : 'Revisá los valores', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                Table(
                  border: TableBorder.all(color: colorScheme.outlineVariant),
                  columnWidths: const {0: FixedColumnWidth(72), 3: FixedColumnWidth(48)},
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
                      children: [
                        for (final header in ['Serie', 'Reps', 'Peso (kg)', ''])
                          Padding(padding: const EdgeInsets.all(10), child: Text(header, style: textTheme.labelMedium)),
                      ],
                    ),
                    for (var i = 0; i < _rows.length; i++)
                      TableRow(children: [
                        Padding(padding: const EdgeInsets.all(10), child: Text('${i + 1}')),
                        _cell(_rows[i].reps, 'Repeticiones de la serie ${i + 1}', validateReps, decimal: false),
                        _cell(_rows[i].kg, 'Peso de la serie ${i + 1}', validateKg, decimal: true),
                        IconButton(
                          tooltip: 'Quitar la serie ${i + 1}',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _rows.length == 1 ? null : () => setState(() => _rows.removeAt(i).dispose()),
                        ),
                      ]),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(onPressed: _rows.length >= 20 ? null : _addSerie, icon: const Icon(Icons.add), label: const Text('Agregar serie')),
                    TextButton(onPressed: _pyramid, child: const Text('Pirámide: +2,5 kg y −2 reps')),
                    TextButton(onPressed: _copyFirst, child: const Text('Copiar la serie 1 a todas')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Aceptar')),
      ],
    );
  }

  Widget _cell(TextEditingController controller, String label, String? Function(String?) validator, {required bool decimal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextFormField(
        controller: controller,
        validator: validator,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]'))],
        decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: label.startsWith('Peso') ? '0' : null),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
