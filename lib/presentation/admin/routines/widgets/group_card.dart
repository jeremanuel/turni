import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/gym/gym.dart';
import '../../../../domain/entities/gym/gym_progress.dart';
import '../routine_draft.dart';
import 'progress_history.dart';
import 'series_dialog.dart';

/// Ancho mínimo de la grilla de ejercicios: más angosta, scrollea de costado.
const _gridMinWidth = 820.0;
const _handleWidth = 40.0;
const _numberWidth = 104.0;
const _weightWidth = 132.0;
const _actionsWidth = 116.0;

/// Un grupo de la rutina en desktop: nombre, músculos, grilla de ejercicios
/// editable celda por celda y el buscador para agregar ([addField]).
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.draft,
    required this.group,
    required this.index,
    required this.showHelp,
    required this.addField,
    required this.onChangeExercise,
    this.progress,
    this.clientFirstName = 'El cliente',
  });

  final RoutineDraft draft;
  final DraftGroup group;
  final int index;
  final bool showHelp;
  final Widget addField;
  final void Function(DraftExercise exercise) onChangeExercise;

  /// Al editar una rutina: lo que fue cambiando cada ejercicio.
  final RoutineProgress? progress;
  final String clientFirstName;

  Future<void> _remove(BuildContext context) async {
    if (group.exercises.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Borrar "${group.name}"?'),
          content: Text('Se sacan sus ${group.exercises.length} ejercicios de la rutina.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Borrar'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    draft.removeGroup(group);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isTarget = draft.target?.key == group.key;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isTarget ? colorScheme.primary : Colors.transparent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Tooltip(
                    message: 'Arrastrá para cambiar el orden (es el orden en que el cliente rota los grupos)',
                    child: MouseRegion(cursor: SystemMouseCursors.grab, child: Icon(Icons.drag_indicator, size: 20, color: colorScheme.outline)),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(width: 200, child: _GroupName(draft: draft, group: group)),
                const SizedBox(width: 12),
                Text(
                  group.exercises.length == 1 ? '1 ejercicio' : '${group.exercises.length} ejercicios',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final muscle in group.muscles) MuscleTag(muscle)],
                  ),
                ),
                const SizedBox(width: 8),
                if (isTarget)
                  const _TargetBadge()
                else
                  OutlinedButton(
                    onPressed: () => draft.setTarget(group.key),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: textTheme.labelMedium,
                    ),
                    child: const Text('Copiar acá'),
                  ),
                const SizedBox(width: 4),
                IconButton(tooltip: 'Duplicar grupo', icon: const Icon(Icons.copy_all_outlined, size: 20), onPressed: () => draft.duplicateGroup(group)),
                IconButton(tooltip: 'Borrar grupo', icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _remove(context)),
              ],
            ),
            if (showHelp && group.exercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.info_outline, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Hacé clic en un número para escribirlo, o usá − y + al pasar el mouse. Tab pasa a la celda siguiente.',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 12),
            if (group.exercises.isEmpty)
              const _EmptyGroup()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth < _gridMinWidth ? _gridMinWidth : constraints.maxWidth;
                  final grid = SizedBox(
                    width: width,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            const _HeaderRow(),
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              buildDefaultDragHandles: false,
                              itemCount: group.exercises.length,
                              onReorder: (oldIndex, newIndex) => draft.moveExercise(group, oldIndex, newIndex > oldIndex ? newIndex - 1 : newIndex),
                              itemBuilder: (context, i) {
                                final exercise = group.exercises[i];
                                return ExerciseRow(
                                  key: ValueKey(exercise.key),
                                  draft: draft,
                                  group: group,
                                  exercise: exercise,
                                  index: i,
                                  onChangeExercise: () => onChangeExercise(exercise),
                                  progress: exercise.id == null ? null : progress?.exercise(exercise.id!),
                                  routineStart: progress?.startDate,
                                  clientFirstName: clientFirstName,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  if (width == constraints.maxWidth) return grid;
                  return SingleChildScrollView(scrollDirection: Axis.horizontal, child: grid);
                },
              ),
            const SizedBox(height: 12),
            addField,
          ],
        ),
      ),
    );
  }
}

class _TargetBadge extends StatelessWidget {
  const _TargetBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.south, size: 16, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text('Lo que copies va acá', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onPrimaryContainer)),
        ],
      ),
    );
  }
}

/// Músculo de un grupo: chip lleno chico (radio 8).
class MuscleTag extends StatelessWidget {
  const MuscleTag(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Center(
        widthFactor: 1,
        child: Text(name, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSecondaryContainer)),
      ),
    );
  }
}

/// Caja de texto con borde (radio 4) para los campos del editor.
InputDecoration editorFieldDecoration(BuildContext context, {String? hint, Color? borderColor}) {
  final colorScheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: color, width: width));
  return InputDecoration(
    isDense: true,
    hintText: hint,
    counterText: '',
    filled: true,
    fillColor: colorScheme.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: border(borderColor ?? colorScheme.outline),
    enabledBorder: border(borderColor ?? colorScheme.outline),
    focusedBorder: border(colorScheme.primary, 2),
  );
}

class _GroupName extends StatefulWidget {
  const _GroupName({required this.draft, required this.group});

  final RoutineDraft draft;
  final DraftGroup group;

  @override
  State<_GroupName> createState() => _GroupNameState();
}

class _GroupNameState extends State<_GroupName> {
  late final _controller = TextEditingController(text: widget.group.name);

  @override
  void didUpdateWidget(covariant _GroupName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.group.name != _controller.text) _controller.text = widget.group.name;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Nombre del grupo',
      child: TextField(
        controller: _controller,
        maxLength: 40,
        style: Theme.of(context).textTheme.titleMedium,
        decoration: editorFieldDecoration(context, hint: 'Nombre del grupo'),
        onChanged: (value) => widget.draft.renameGroup(widget.group, value),
      ),
    );
  }
}

/// Borde punteado (estados vacíos del editor).
class DashedBorder extends StatelessWidget {
  const DashedBorder({super.key, required this.child, required this.color, this.radius = 8});

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DashedPainter(color, radius), child: child);
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter oldDelegate) => oldDelegate.color != color || oldDelegate.radius != radius;
}

class _EmptyGroup extends StatelessWidget {
  const _EmptyGroup();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return DashedBorder(
      color: colorScheme.outline,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            Text('Este grupo está vacío', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Copiá un grupo entero o ejercicios sueltos desde el panel de la derecha, o buscá un ejercicio acá abajo.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant);
    Widget cell(String text, {double? width, int? flex, TextAlign align = TextAlign.start}) {
      final child = Container(
        height: 40,
        alignment: align == TextAlign.center ? Alignment.center : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border(right: BorderSide(color: colorScheme.outlineVariant))),
        child: Text(text, style: style),
      );
      return width != null ? SizedBox(width: width, child: child) : Expanded(flex: flex ?? 1, child: child);
    }

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          cell('', width: _handleWidth),
          cell('Ejercicio', flex: 2),
          cell('Series', width: _numberWidth, align: TextAlign.center),
          cell('Reps', width: _numberWidth, align: TextAlign.center),
          cell('Peso (kg)', width: _weightWidth, align: TextAlign.center),
          cell('Indicación para el cliente', flex: 2),
          SizedBox(width: _actionsWidth, child: Container(height: 40)),
        ],
      ),
    );
  }
}

/// Una fila de la grilla: cada número se escribe directo en su celda.
class ExerciseRow extends StatefulWidget {
  const ExerciseRow({
    super.key,
    required this.draft,
    required this.group,
    required this.exercise,
    required this.index,
    required this.onChangeExercise,
    this.progress,
    this.routineStart,
    this.clientFirstName = 'El cliente',
  });

  final RoutineDraft draft;
  final DraftGroup group;
  final DraftExercise exercise;
  final int index;
  final VoidCallback onChangeExercise;
  final ExerciseProgress? progress;
  final DateTime? routineStart;
  final String clientFirstName;

  @override
  State<ExerciseRow> createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<ExerciseRow> {
  late final _notes = TextEditingController(text: widget.exercise.notes);

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  DraftExercise get _exercise => widget.exercise;
  bool get _uniform => isUniform(_exercise.series);

  void _setSets(int sets) {
    final count = sets.clamp(1, 20);
    final series = _exercise.series;
    final next = List.generate(count, (i) => i < series.length ? series[i] : series.last);
    widget.draft.setSeries(_exercise, next);
  }

  void _setAll({int? reps, double? kg}) {
    widget.draft.setSeries(_exercise, _exercise.series.map((s) => s.copyWith(reps: reps, weightKg: kg)).toList());
  }

  Future<void> _editSeries() async {
    final series = await showSeriesDialog(context, exerciseName: _exercise.name, series: _exercise.series);
    if (series != null) widget.draft.setSeries(_exercise, series);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final border = BorderSide(color: colorScheme.outlineVariant);
    final series = _exercise.series;
    final first = series.first;

    Widget box({required Widget child, double? width, int? flex}) {
      final content = Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(border: Border(right: border, top: border)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        alignment: Alignment.centerLeft,
        child: child,
      );
      return width != null ? SizedBox(width: width, child: content) : Expanded(flex: flex ?? 1, child: content);
    }

    final repsLabel = series.map((s) => s.reps).toSet().length == 1 ? '${first.reps}' : series.map((s) => s.reps).join('/');
    final kgLabel = series.map((s) => s.weightKg).toSet().length == 1
        ? formatKg(first.weightKg)
        : '${formatKg(series.first.weightKg)}→${formatKg(series.last.weightKg)}';

    return Material(
      color: colorScheme.surfaceContainerHigh,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            box(
              width: _handleWidth,
              child: ReorderableDragStartListener(
                index: widget.index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Center(child: Text('${widget.index + 1}', style: textTheme.bodySmall?.copyWith(color: colorScheme.outline))),
                ),
              ),
            ),
            box(
              flex: 2,
              child: InkWell(
                onTap: widget.onChangeExercise,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_exercise.name, style: textTheme.titleSmall),
                            if (_exercise.muscles.isNotEmpty)
                              Text(_exercise.muscles.join(' · '), style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                            if (widget.progress != null)
                              _DoneHint(
                                progress: widget.progress!,
                                current: series,
                                clientFirstName: widget.clientFirstName,
                                routineStart: widget.routineStart,
                                onUse: (done) => widget.draft.setSeries(_exercise, [...done]),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: colorScheme.outline),
                    ],
                  ),
                ),
              ),
            ),
            box(
              width: _numberWidth,
              child: NumberCell(
                value: '${series.length}',
                label: 'Series de ${_exercise.name}',
                onChanged: (text) {
                  final sets = int.tryParse(text);
                  if (sets != null && sets > 0) _setSets(sets);
                },
                onStep: (delta) => _setSets(series.length + delta),
              ),
            ),
            box(
              width: _numberWidth,
              child: _uniform
                  ? NumberCell(
                      value: repsLabel,
                      label: 'Repeticiones de ${_exercise.name}',
                      onChanged: (text) {
                        final reps = int.tryParse(text);
                        if (reps != null && reps >= 0) _setAll(reps: reps);
                      },
                      onStep: (delta) => _setAll(reps: (first.reps + delta).clamp(0, 999)),
                    )
                  : _VariedCell(label: repsLabel, onTap: _editSeries),
            ),
            box(
              width: _weightWidth,
              child: _uniform
                  ? NumberCell(
                      value: kgLabel,
                      label: 'Peso de ${_exercise.name}',
                      suffix: 'kg',
                      decimal: true,
                      onChanged: (text) {
                        final kg = text.trim().isEmpty ? 0.0 : parseKg(text);
                        if (kg != null && kg <= 1000) _setAll(kg: kg);
                      },
                      onStep: (delta) => _setAll(kg: (first.weightKg + delta * 2.5).clamp(0, 1000).toDouble()),
                    )
                  : _VariedCell(label: '$kgLabel kg', onTap: _editSeries),
            ),
            box(
              flex: 2,
              child: TextField(
                controller: _notes,
                maxLength: 500,
                style: textTheme.bodyMedium,
                decoration: editorFieldDecoration(context, hint: 'Ej.: bajar en 3 segundos', borderColor: colorScheme.outlineVariant),
                onChanged: (value) => widget.draft.setNotes(_exercise, value),
              ),
            ),
            SizedBox(
              width: _actionsWidth,
              child: Container(
                decoration: BoxDecoration(border: Border(top: border)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Series distintas (pirámide)',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                      icon: Icon(Icons.bar_chart, size: 20, color: _uniform ? null : colorScheme.primary),
                      onPressed: _editSeries,
                    ),
                    IconButton(
                      tooltip: 'Duplicar fila',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                      icon: const Icon(Icons.copy_outlined, size: 20),
                      onPressed: () => widget.draft.duplicateExercise(widget.group, _exercise),
                    ),
                    IconButton(
                      tooltip: 'Quitar',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => widget.draft.removeExercise(widget.group, _exercise),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Debajo del nombre, al editar: lo último que hizo el cliente si no es lo
/// que dice el plan ("Usar" lo pasa al plan) y el acceso al historial.
class _DoneHint extends StatelessWidget {
  const _DoneHint({
    required this.progress,
    required this.current,
    required this.clientFirstName,
    required this.routineStart,
    required this.onUse,
  });

  final ExerciseProgress progress;

  /// Lo que dice el plan ahora en el borrador.
  final List<Serie> current;
  final String clientFirstName;
  final DateTime? routineStart;
  final ValueChanged<List<Serie>> onUse;

  bool _same(List<Serie> a, List<Serie> b) => a.length == b.length && [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final last = progress.last;
    final done = last != null && last.byClient && !_same(last.series, current) ? last : null;
    final compact = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
      minimumSize: const WidgetStatePropertyAll(Size(0, 28)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
    );
    final historyButton = progress.changesCount == 0
        ? null
        : TextButton(
            style: compact,
            onPressed: () => showExerciseHistoryDialog(
              context,
              exercise: progress,
              clientFirstName: clientFirstName,
              subtitle: '${progress.groupName}${routineStart == null ? '' : ' · rutina desde el ${shortDate(routineStart!)}'}',
            ),
            child: Text(progress.changesCount == 1 ? '1 cambio' : '${progress.changesCount} cambios'),
          );
    if (done == null && historyButton == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          if (done != null) ...[
            Text(
              'Hizo ${seriesLabel(done.series)} · ${weekdayDate(done.date)}',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
            ),
            Tooltip(
              message: 'Pasar al plan lo último que hizo $clientFirstName',
              child: OutlinedButton(style: compact, onPressed: () => onUse(done.series), child: const Text('Usar')),
            ),
          ],
          if (historyButton != null) historyButton,
        ],
      ),
    );
  }
}

/// Celda de series distintas: muestra el resumen y abre el diálogo.
class _VariedCell extends StatelessWidget {
  const _VariedCell({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Series distintas: clic para editarlas',
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: colorScheme.outline), borderRadius: BorderRadius.circular(4)),
          child: Text(label, style: TextStyle(color: colorScheme.primary, fontFeatures: const [FontFeature.tabularFigures()])),
        ),
      ),
    );
  }
}

/// Número editable en una celda: se escribe directo, y al pasar el mouse
/// (o con el foco adentro) aparecen − y +.
class NumberCell extends StatefulWidget {
  const NumberCell({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    required this.onStep,
    this.suffix,
    this.decimal = false,
    this.alwaysShowSteps = false,
  });

  final String value;
  final String label;
  final ValueChanged<String> onChanged;
  final ValueChanged<int> onStep;
  final String? suffix;
  final bool decimal;

  /// En pantallas táctiles no hay hover: los botones se ven siempre.
  final bool alwaysShowSteps;

  @override
  State<NumberCell> createState() => _NumberCellState();
}

class _NumberCellState extends State<NumberCell> {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _controller.text = widget.value;
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant NumberCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió por un botón (o por otra celda), refleja el valor nuevo.
    if (!_focus.hasFocus && _controller.text != widget.value) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showSteps = widget.alwaysShowSteps || _hover || _focus.hasFocus;
    final active = _hover || _focus.hasFocus;

    Widget step(IconData icon, int delta, String tooltip) => SizedBox(
          width: 28,
          child: Visibility(
            visible: showSteps,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: IconButton(
              tooltip: tooltip,
              padding: EdgeInsets.zero,
              iconSize: 16,
              color: colorScheme.primary,
              icon: Icon(icon),
              onPressed: () => widget.onStep(delta),
            ),
          ),
        );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        height: widget.alwaysShowSteps ? 48 : 40,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _focus.hasFocus ? colorScheme.primary : (active ? colorScheme.onSurfaceVariant : colorScheme.outline), width: _focus.hasFocus ? 2 : 1),
        ),
        child: Row(
          children: [
            ExcludeFocus(child: step(Icons.remove, -1, 'Bajar ${widget.label.toLowerCase()}')),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(widget.decimal ? r'[0-9.,]' : r'[0-9]'))],
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  suffixText: widget.suffix,
                  semanticCounterText: widget.label,
                ),
                onChanged: widget.onChanged,
                onTap: () => _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length),
              ),
            ),
            ExcludeFocus(child: step(Icons.add, 1, 'Subir ${widget.label.toLowerCase()}')),
          ],
        ),
      ),
    );
  }
}
