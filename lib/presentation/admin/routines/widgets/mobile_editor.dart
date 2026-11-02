import 'package:flutter/material.dart';

import 'rest_picker.dart';

import '../../../../domain/entities/gym/gym.dart';
import '../routine_draft.dart';
import 'group_card.dart';
import 'series_dialog.dart';

/// Editor en el teléfono: los grupos son pestañas y se ve uno a la vez; cada
/// ejercicio es una card con series, reps y peso (− y + siempre visibles).
class MobileRoutineEditor extends StatelessWidget {
  const MobileRoutineEditor({
    super.key,
    required this.draft,
    required this.onAddExercise,
    required this.onChangeExercise,
    required this.header,
  });

  final RoutineDraft draft;
  final void Function(DraftGroup group) onAddExercise;
  final void Function(DraftExercise exercise) onChangeExercise;

  /// Fecha de inicio y aviso de "usar de base", arriba de todo.
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final group = draft.target;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        header,
        const SizedBox(height: 16),
        if (group == null)
          Text('Agregá un grupo para empezar.', style: textTheme.bodyMedium)
        else ...[
          Row(
            children: [
              Expanded(child: _MobileGroupName(key: ValueKey('name-${group.key}'), draft: draft, group: group)),
              IconButton(tooltip: 'Duplicar grupo', icon: const Icon(Icons.copy_all_outlined), onPressed: () => draft.duplicateGroup(group)),
              IconButton(tooltip: 'Borrar grupo', icon: const Icon(Icons.delete_outline), onPressed: () => draft.removeGroup(group)),
            ],
          ),
          if (group.muscles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final muscle in group.muscles) MuscleTag(muscle)]),
          ],
          const SizedBox(height: 12),
          for (final (index, exercise) in group.exercises.indexed) ...[
            _MobileExerciseCard(
              key: ValueKey(exercise.key),
              draft: draft,
              group: group,
              exercise: exercise,
              index: index,
              onChange: () => onChangeExercise(exercise),
            ),
            const SizedBox(height: 12),
          ],
          if (group.exercises.isEmpty)
            DashedBorder(
              color: colorScheme.outline,
              radius: 12,
              child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Text('Este grupo está vacío', style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Copiá un grupo o ejercicios de otra rutina, o buscá uno abajo.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ]),
            )),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => onAddExercise(group),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(children: [
                Icon(Icons.add, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Text('Agregar ejercicio: escribí el nombre…', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
              ]),
            ),
          ),
        ],
      ],
    );
  }
}

class _MobileGroupName extends StatefulWidget {
  const _MobileGroupName({super.key, required this.draft, required this.group});

  final RoutineDraft draft;
  final DraftGroup group;

  @override
  State<_MobileGroupName> createState() => _MobileGroupNameState();
}

class _MobileGroupNameState extends State<_MobileGroupName> {
  late final _controller = TextEditingController(text: widget.group.name);

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
        decoration: editorFieldDecoration(context, hint: 'Nombre del grupo').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
        onChanged: (value) => widget.draft.renameGroup(widget.group, value),
      ),
    );
  }
}

class _MobileExerciseCard extends StatefulWidget {
  const _MobileExerciseCard({
    super.key,
    required this.draft,
    required this.group,
    required this.exercise,
    required this.index,
    required this.onChange,
  });

  final RoutineDraft draft;
  final DraftGroup group;
  final DraftExercise exercise;
  final int index;
  final VoidCallback onChange;

  @override
  State<_MobileExerciseCard> createState() => _MobileExerciseCardState();
}

class _MobileExerciseCardState extends State<_MobileExerciseCard> {
  late final _notes = TextEditingController(text: widget.exercise.notes);

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  DraftExercise get _exercise => widget.exercise;

  void _setSets(int sets) {
    final series = _exercise.series;
    final count = sets.clamp(1, 20);
    widget.draft.setSeries(_exercise, List.generate(count, (i) => i < series.length ? series[i] : series.last));
  }

  void _setAll({int? reps, double? kg}) =>
      widget.draft.setSeries(_exercise, _exercise.series.map((s) => s.copyWith(reps: reps, weightKg: kg)).toList());

  Future<void> _editSeries() async {
    final series = await showSeriesDialog(context, exerciseName: _exercise.name, series: _exercise.series);
    if (series != null) widget.draft.setSeries(_exercise, series);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final series = _exercise.series;
    final first = series.first;
    final uniform = isUniform(series);

    Widget labeled(String label, Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(label, style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)), const SizedBox(height: 4), child],
        );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.onChange,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${widget.index + 1}. ${_exercise.name}', style: textTheme.titleSmall),
                                if (_exercise.muscles.isNotEmpty)
                                  Text(_exercise.muscles.join(' · '), style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: colorScheme.outline),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(tooltip: 'Quitar ${_exercise.name}', icon: const Icon(Icons.close), onPressed: () => widget.draft.removeExercise(widget.group, _exercise)),
              ],
            ),
            const SizedBox(height: 8),
            if (uniform)
              Row(
                children: [
                  Expanded(
                    child: labeled(
                      'Series',
                      NumberCell(
                        alwaysShowSteps: true,
                        value: '${series.length}',
                        label: 'Series de ${_exercise.name}',
                        onChanged: (t) {
                          final n = int.tryParse(t);
                          if (n != null && n > 0) _setSets(n);
                        },
                        onStep: (d) => _setSets(series.length + d),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: labeled(
                      'Reps',
                      NumberCell(
                        alwaysShowSteps: true,
                        value: '${first.reps}',
                        label: 'Repeticiones de ${_exercise.name}',
                        onChanged: (t) {
                          final n = int.tryParse(t);
                          if (n != null && n >= 0) _setAll(reps: n);
                        },
                        onStep: (d) => _setAll(reps: (first.reps + d).clamp(0, 999)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: labeled(
                      'Peso (kg)',
                      NumberCell(
                        alwaysShowSteps: true,
                        decimal: true,
                        value: formatKg(first.weightKg),
                        label: 'Peso de ${_exercise.name}',
                        onChanged: (t) {
                          final kg = t.trim().isEmpty ? 0.0 : parseKg(t);
                          if (kg != null && kg <= 1000) _setAll(kg: kg);
                        },
                        onStep: (d) => _setAll(kg: (first.weightKg + d * 2.5).clamp(0, 1000).toDouble()),
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton(onPressed: _editSeries, child: Text('Series distintas: ${seriesLabel(series)}')),
            const SizedBox(height: 8),
            labeled(
              'Descanso entre series (opcional)',
              RestPicker(
                exerciseName: _exercise.name,
                value: _exercise.restSeconds,
                height: 48,
                onChanged: (seconds) => widget.draft.setRest(_exercise, seconds),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _notes,
                    maxLength: 500,
                    style: textTheme.bodyMedium,
                    decoration: editorFieldDecoration(context, hint: 'Indicación para el cliente (opcional)', borderColor: colorScheme.outlineVariant),
                    onChanged: (value) => widget.draft.setNotes(_exercise, value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Series distintas (pirámide)',
                  icon: const Icon(Icons.bar_chart, size: 18),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  onPressed: _editSeries,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pestañas de los grupos del editor en el teléfono (van en la barra de
/// arriba): nombre y cantidad de ejercicios, y "+" para agregar un grupo.
class MobileGroupTabs extends StatelessWidget implements PreferredSizeWidget {
  const MobileGroupTabs({super.key, required this.draft});

  final RoutineDraft draft;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = draft.target?.key;
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        children: [
          for (final g in draft.groups) ...[
            ChoiceChip(
              label: Text('${g.name.trim().isEmpty ? 'Sin nombre' : g.name}  ${g.exercises.length}'),
              selected: g.key == selected,
              onSelected: (_) => draft.setTarget(g.key),
            ),
            const SizedBox(width: 8),
          ],
          DashedBorder(
            color: colorScheme.outline,
            child: SizedBox(
              width: 40,
              height: 40,
              child: IconButton(tooltip: 'Agregar grupo', icon: Icon(Icons.add, size: 18, color: colorScheme.primary), onPressed: draft.addGroup),
            ),
          ),
        ],
      ),
    );
  }
}
