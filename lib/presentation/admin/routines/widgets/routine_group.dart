import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../domain/entities/routine/routine_exercise.dart';
import '../../../../domain/entities/routine/routine_group.dart' as rpe;
import '../cubit/new_routine_cubit.dart';
import 'exercise_item.dart';

class RoutineGroup extends StatefulWidget {

  const RoutineGroup({super.key, this.isFirst = true, required this.routineGroup});
  final bool isFirst;
  final rpe.RoutineGroup routineGroup;

  @override
  State<RoutineGroup> createState() => _RoutineGroupState();
}

class _RoutineGroupState extends State<RoutineGroup> {

  final listKey = GlobalKey();

  @override
  Widget build(BuildContext context) {

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
            children: [
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: widget.routineGroup.groupName,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: "Grupo",
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant,
                      ),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(onPressed: widget.isFirst ? null : () => context.read<NewRoutineCubit>().deleteGroup(widget.routineGroup.id), icon: const Icon(Icons.delete))
            ],
          ),
          Container(
         
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(80),
              border: Border.all(
                color: colorScheme.outline,
              ),
             borderRadius: const BorderRadius.only( topRight: Radius.circular(4), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
            ),
            child: Column(
              children: [
                ReorderableListBody(
                  routineGroup: widget.routineGroup,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    context.read<NewRoutineCubit>().addNewExerciseToGroup(widget.routineGroup.id);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Agregar ejercicio"),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
      BlocBuilder<NewRoutineCubit, NewRoutineState>(
                    builder: (context, state) {
                      final copiedExercise = state.copiedExercise;
                      if(copiedExercise == null) {
                        return SizedBox();
                      }
                      return Positioned(
                        bottom: 16,
                        left: 0,
                        child: TextButton.icon(
                          onPressed: () {
                        
                            context.read<NewRoutineCubit>().addExerciseToGroup(widget.routineGroup.id, copiedExercise);
                            context.read<NewRoutineCubit>().setCopiedExercise(null);
                          },
                          icon: const Icon(Icons.paste),
                          label: const Text("Pegar ejercicio"),
                        ),
                      );
                    },
                  )
      ]
    );
  }
}

class ReorderableListBody extends StatefulWidget {
  const ReorderableListBody({
    super.key,
    required this.routineGroup,
  });

  final rpe.RoutineGroup routineGroup;

  @override
  State<ReorderableListBody> createState() => _ReorderableListBodyState();
}

class _ReorderableListBodyState extends State<ReorderableListBody> {

  List<RoutineExercise> cachedExercises = []; // Mantengo una lista local, para que la reorderablelsitview use siempre la misma lista ante cambios de o rden

  @override
  void initState() {
    cachedExercises = widget.routineGroup.exercises.toList();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ReorderableListBody oldWidget) {
    if(oldWidget.routineGroup != widget.routineGroup) {
      cachedExercises = widget.routineGroup.exercises.toList();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    
    return ReorderableListView.builder(
      key: ValueKey("routine_group_${widget.routineGroup.id}_exercises_list"),
      shrinkWrap: true,
      itemCount: cachedExercises.length,
      itemBuilder: (context, index) {
        final exercise = cachedExercises[index];
        return ExerciseItem(
          routineGroupId: widget.routineGroup.id,
          index: index,
          key: ValueKey("${widget.routineGroup.id}_exercise_${exercise.id}"),
          routineExercise: exercise,
        );
      },
      onReorder: (oldIndex, newIndex) {

        if (newIndex > oldIndex) {
          newIndex -= 1;
        }

        final NewRoutineCubit cubit = context.read<NewRoutineCubit>();

        final movedItem = cachedExercises.removeAt(oldIndex);
        cachedExercises.insert(newIndex, movedItem);
        
        // Actualizo lista local, y luego lista del cubit.
        cubit.updateGroup(widget.routineGroup.copyWith(exercises: cachedExercises));

      },
    );
  }
}
