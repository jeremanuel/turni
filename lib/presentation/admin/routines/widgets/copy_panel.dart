import 'package:flutter/material.dart';

import '../../../../domain/entities/gym/gym.dart';
import '../routine_draft.dart';

/// "Copiar de otra rutina": las rutinas del cliente y las últimas que armó el
/// admin, para copiar grupos enteros o ejercicios sueltos al grupo destino,
/// o usar una entera de base. En desktop va al costado del editor; en el
/// teléfono, en un sheet con el selector de grupo destino ([showTargets]).
class CopyPanel extends StatefulWidget {
  const CopyPanel({
    super.key,
    required this.draft,
    required this.clientName,
    required this.clientRoutines,
    required this.recentRoutines,
    this.showTargets = false,
    this.scrollController,
    this.doneLabel,
  });

  final RoutineDraft draft;
  final String clientName;
  final List<Routine> clientRoutines;
  final List<Routine> recentRoutines;
  final bool showTargets;
  final ScrollController? scrollController;

  /// En el sheet del teléfono: el texto del botón de abajo ("Listo · 1 grupo y
  /// 2 ejercicios agregados").
  final ValueNotifier<String>? doneLabel;

  @override
  State<CopyPanel> createState() => _CopyPanelState();
}

class _CopyPanelState extends State<CopyPanel> {
  bool _recent = false;
  String _query = '';
  final Set<String> _expanded = {};
  final Set<String> _added = {};
  int _groupsCopied = 0;
  int _exercisesAdded = 0;

  void _countAdded({bool group = false}) {
    if (group) {
      _groupsCopied++;
    } else {
      _exercisesAdded++;
    }
    final parts = [
      if (_groupsCopied > 0) _groupsCopied == 1 ? '1 grupo' : '$_groupsCopied grupos',
      if (_exercisesAdded > 0) _exercisesAdded == 1 ? '1 ejercicio' : '$_exercisesAdded ejercicios',
    ];
    widget.doneLabel?.value = 'Listo · ${parts.join(' y ')} ${_groupsCopied + _exercisesAdded == 1 ? 'agregado' : 'agregados'}';
  }

  @override
  void initState() {
    super.initState();
    final active = widget.clientRoutines.where((r) => r.isActive).firstOrNull ?? widget.clientRoutines.firstOrNull;
    if (active != null) _expanded.add(active.id);
  }

  String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp('[áà]'), 'a')
      .replaceAll(RegExp('[éè]'), 'e')
      .replaceAll(RegExp('[íì]'), 'i')
      .replaceAll(RegExp('[óò]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u');

  String _routineTitle(Routine routine) => _recent ? (routine.clientName ?? 'Cliente') : routineMonthsLabel(routine);

  String _routineMeta(Routine routine) {
    final groups = routine.groups.map((g) => g.name).join(' · ');
    if (_recent) return '${agoLabel(routine.createdAt)} · $groups';
    return '${routine.groups.length == 1 ? '1 grupo' : '${routine.groups.length} grupos'} · ${routine.exercisesCount} ejercicios';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final routines = _recent ? widget.recentRoutines : widget.clientRoutines;
    final query = _normalize(_query.trim());

    return ListenableBuilder(
      listenable: widget.draft,
      builder: (context, _) {
        final target = widget.draft.target;
        final targetName = target?.name.trim().isNotEmpty == true ? target!.name : 'un grupo nuevo';
        final visible = <Widget>[];

        for (final routine in routines) {
          final groups = <_SourceGroup>[];
          for (final (gi, group) in routine.groups.indexed) {
            final groupMatches = query.isEmpty || _normalize(group.name).contains(query);
            final exercises = [
              for (final (ei, exercise) in group.exercises.indexed)
                if (groupMatches || _normalize(exercise.name).contains(query)) (index: ei, exercise: exercise),
            ];
            if (exercises.isEmpty) continue;
            final groupKey = '${routine.id}-$gi';
            groups.add(_SourceGroup(
              group: group,
              copied: _added.contains(groupKey),
              onCopy: () {
                widget.draft.copyGroup(group);
                setState(() => _added.add(groupKey));
                _countAdded(group: true);
              },
              exercises: [
                for (final item in exercises)
                  _SourceExercise(
                    exercise: item.exercise,
                    added: _added.contains('$groupKey-${item.index}'),
                    tooltip: 'Agregar ${item.exercise.name} a $targetName',
                    onAdd: () {
                      widget.draft.addExercise(DraftExercise.fromRoutine(item.exercise));
                      setState(() => _added.add('$groupKey-${item.index}'));
                      _countAdded();
                    },
                  ),
              ],
            ));
          }
          if (groups.isEmpty) continue;
          final expanded = query.isNotEmpty || _expanded.contains(routine.id);
          visible.add(Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _SourceCard(
              title: _routineTitle(routine),
              meta: _routineMeta(routine),
              current: !_recent && routine.isActive,
              expanded: expanded,
              onToggle: () => setState(() => _expanded.contains(routine.id) ? _expanded.remove(routine.id) : _expanded.add(routine.id)),
              onUseAsBase: () => widget.draft.useAsBase(
                routine,
                _recent ? 'la rutina de ${routine.clientName ?? 'otro cliente'}' : 'la rutina ${routineMonthsLabel(routine)}',
              ),
              groups: groups,
            ),
          ));
        }

        return ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Text('Copiar de otra rutina', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Lo que copies se agrega en '),
                TextSpan(text: targetName, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                const TextSpan(text: '. Un grupo entero se suma como grupo nuevo.'),
              ]),
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            if (widget.showTargets && widget.draft.groups.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Se agrega en', style: textTheme.labelMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final group in widget.draft.groups)
                    ChoiceChip(
                      label: Text(group.name.trim().isEmpty ? 'Sin nombre' : group.name),
                      selected: group.key == target?.key,
                      onSelected: (_) => widget.draft.setTarget(group.key),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text('De ${widget.clientName.split(' ').first}'),
                  selected: !_recent,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => setState(() => _recent = false),
                ),
                ChoiceChip(
                  label: const Text('Tus últimas rutinas'),
                  selected: _recent,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => setState(() => _recent = true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: TextField(
                style: textTheme.bodyMedium,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: 'Buscar ejercicio o grupo',
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: colorScheme.outline)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: colorScheme.outline)),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const SizedBox(height: 20),
            if (visible.isEmpty)
              Text(
                query.isNotEmpty
                    ? 'Nada coincide con "${_query.trim()}".'
                    : (_recent ? 'Todavía no armaste rutinas para otros clientes.' : '${widget.clientName} no tiene rutinas anteriores.'),
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              )
            else
              ...visible,
          ],
        );
      },
    );
  }
}

/// Medidas comunes de las cards del panel: todo se alinea a la misma grilla,
/// sin importar el largo de los textos.
const _cardPadding = 16.0;

/// Ancho de la flecha de la card + su separación: el contenido de adentro
/// arranca alineado con el título de la rutina.
const _indent = 32.0;

/// Columna derecha de los botones ("Usar de base", "Copiar grupo").
const _actionWidth = 116.0;

ButtonStyle _compact(TextTheme textTheme) => ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
      textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      visualDensity: VisualDensity.compact,
    );

/// Una rutina de origen: encabezado plegable y, abierta, sus grupos.
class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.title,
    required this.meta,
    required this.current,
    required this.expanded,
    required this.onToggle,
    required this.onUseAsBase,
    required this.groups,
  });

  final String title;
  final String meta;
  final bool current;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onUseAsBase;
  final List<_SourceGroup> groups;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colorScheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_cardPadding, 14, _cardPadding, 14),
              child: Row(
                children: [
                  SizedBox(
                    width: _indent,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(expanded ? Icons.expand_more : Icons.chevron_right, size: 20, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(title, style: textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            if (current) ...[
                              const SizedBox(width: 8),
                              Container(
                                height: 20,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
                                child: Center(
                                  widthFactor: 1,
                                  child: Text('Actual', style: textTheme.labelSmall?.copyWith(color: colorScheme.onSecondaryContainer)),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: _actionWidth,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(style: _compact(textTheme), onPressed: onUseAsBase, child: const Text('Usar de base')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(_cardPadding + _indent, 0, _cardPadding, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: groups),
            ),
        ],
      ),
    );
  }
}

/// Un grupo de la rutina de origen: nombre y músculos a la izquierda,
/// "Copiar grupo" en la columna de botones, y sus ejercicios debajo.
class _SourceGroup extends StatelessWidget {
  const _SourceGroup({required this.group, required this.copied, required this.onCopy, required this.exercises});

  final RoutineGroup group;
  final bool copied;
  final VoidCallback onCopy;
  final List<_SourceExercise> exercises;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: colorScheme.outlineVariant),
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (group.muscles.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        group.muscles.join(' · '),
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: _actionWidth,
                child: copied
                    ? FilledButton.tonalIcon(
                        onPressed: null,
                        style: _compact(textTheme),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Copiado'),
                      )
                    : OutlinedButton(style: _compact(textTheme), onPressed: onCopy, child: const Text('Copiar grupo')),
              ),
            ],
          ),
        ),
        ...exercises,
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Un ejercicio de la rutina de origen: nombre y, debajo, sus series; el "+"
/// siempre en la misma columna, sin importar el largo de los textos.
class _SourceExercise extends StatelessWidget {
  const _SourceExercise({required this.exercise, required this.added, required this.tooltip, required this.onAdd});

  final RoutineExercise exercise;
  final bool added;
  final String tooltip;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  seriesLabel(exercise.series),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              tooltip: tooltip,
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: Icon(added ? Icons.check : Icons.add),
              color: added ? colorScheme.onSecondaryContainer : colorScheme.primary,
              style: added
                  ? IconButton.styleFrom(backgroundColor: colorScheme.secondaryContainer)
                  : IconButton.styleFrom(side: BorderSide(color: colorScheme.outlineVariant)),
              onPressed: onAdd,
            ),
          ),
        ],
      ),
    );
  }
}
