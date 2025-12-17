import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../domain/entities/routine/routine.dart';
import '../../../../domain/entities/routine/routine_exercise.dart';
import '../../../../domain/entities/routine/routine_group.dart';
import '../../states/scaffold_cubit/scaffold_cubit.dart';
import '../cubit/new_routine_cubit.dart';

class RoutineCard extends StatefulWidget {
  final Routine routine;
  final bool expanded;

  const RoutineCard({super.key, required this.routine, this.expanded = true});

  @override
  State<RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<RoutineCard> with AutomaticKeepAliveClientMixin {
  final ExpansibleController expansibleController = ExpansibleController();
  late final Map<int, ExpansibleController> groupControllers;
  final scrollController = ScrollController();
  @override
  void initState() {
    expansibleController.expand();
    super.initState();
    groupControllers = {
      for (var group in widget.routine.exercises) group.id: ExpansibleController()
    };
  }

  @override
  void dispose() {
    for (var controller in groupControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Expansible(
      
      controller: expansibleController,
      headerBuilder: (context, animation) => buildHeader(colorScheme),

      bodyBuilder: (context, animation) {
        return buildBody(colorScheme);
      },
    );
  }

  Widget buildBody(ColorScheme colorScheme) {
    return Container(
      height: 300, // Altura fija para forzar scroll si el contenido es largo
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
        border: Border(bottom: BorderSide(color: colorScheme.outline), left: BorderSide(color: colorScheme.outline), right: BorderSide(color: colorScheme.outline)),
      ),
      child: Scrollbar(
        trackVisibility: true,
        thumbVisibility: true,
        controller: scrollController,
        thickness: 8.0, // Grosor de la scrollbar
        radius: const Radius.circular(4),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.only(right: 12), // Espacio para la scrollbar
          child: Column(
            children: widget.routine.exercises
                .map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: buildGroup(group, colorScheme),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget buildHeader(ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    final totalExercises = widget.routine.exercises.fold<int>(
      0,
      (sum, group) => sum + group.exercises.length,
    );
    final estimatedDuration = totalExercises * 7; // ~3 min por ejercicio

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: getHeaderBorderRadius(),
        border: getHeaderBorder(colorScheme),
      ),
      child: InkWell(
        onTap: () => expansibleController.isExpanded ? expansibleController.collapse() : expansibleController.expand(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "11/06/2024 - Actualidad",
                    style: textTheme.bodyLarge,
                  ),
                ),
                Icon(
                  expansibleController.isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _InfoChip(
                  icon: Icons.fitness_center,
                  label: '$totalExercises ejercicios',
                  colorScheme: colorScheme,
                ),
                _InfoChip(
                  icon: Icons.access_time,
                  label: '~$estimatedDuration min',
                  colorScheme: colorScheme,
                ),
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: 'Hace 24 dias',
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Border getHeaderBorder(ColorScheme colorScheme){
    if(!expansibleController.isExpanded){
      return Border.all(color: colorScheme.outline);
    }
    return Border(top: BorderSide(color: colorScheme.outline), left: BorderSide(color: colorScheme.outline), right: BorderSide(color: colorScheme.outline));
  }

  BorderRadius getHeaderBorderRadius() {
    return expansibleController.isExpanded
        ? const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))
        : BorderRadius.circular(4);
  } 

  Widget buildGroup(RoutineGroup group, ColorScheme colorScheme) {
    final controller = groupControllers[group.id]!;
    
    return Expansible(
      controller: controller,
      headerBuilder: (context, animation) => buildGroupHeader(group, controller, colorScheme),
      bodyBuilder: (context, animation) => buildGroupBody(group, controller, colorScheme),
    );
  }

  Widget buildGroupHeader(RoutineGroup group, ExpansibleController controller, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: controller.isExpanded
            ? const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))
            : BorderRadius.circular(8),
        border: controller.isExpanded
            ? Border(
                top: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                left: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                right: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              )
            : Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => controller.isExpanded ? controller.collapse() : controller.expand(),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    group.groupName,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${group.exercises.length}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                context.read<NewRoutineCubit>().setCopiedGroup(group);
              },
              icon: const Icon(Icons.copy, size: 16),
              tooltip: 'Copiar grupo',
              visualDensity: const VisualDensity(
                horizontal: VisualDensity.minimumDensity,
                vertical: VisualDensity.minimumDensity,
              ),
            ),
            Icon(
              controller.isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildGroupBody(RoutineGroup group, ExpansibleController controller, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
          left: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
          right: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: group.exercises
            .mapIndexed(
              (index, e) => Padding(
                padding: EdgeInsets.only(
                  bottom: index < group.exercises.length - 1 ? 8 : 0,
                ),
                child: buildExerciseRow(e, colorScheme, index),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget buildExerciseRow(RoutineExercise exercise, ColorScheme colorScheme, index) {
    return ListTile(
      contentPadding: const EdgeInsets.only(),
      dense: true,
      title: Text(
            exercise.exercise!.name,
          ),
      subtitle: Text("${exercise.sets}x${exercise.weight}${exercise.observations != null ? " | ${exercise.observations}" : ''}", style: TextStyle(color: colorScheme.primary),),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: (){}, icon: const Badge(child: Icon(Icons.comment, size: 16,),), visualDensity: VisualDensity.compact),
          IconButton(onPressed: (){
            context.read<NewRoutineCubit>().setCopiedExercise(exercise);
            sl<ScaffoldCubit>().showSnackbar("Ejercicio copiado");
          }, icon: const Icon(Icons.copy, size: 16,), visualDensity: VisualDensity.compact),
          IconButton(onPressed: (){}, icon: Icon(Random().nextBool() ? Icons.thumb_up : Icons.thumb_down, size: 16,), visualDensity: VisualDensity.compact),

        ],
      ),
    
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  const _ExerciseChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
    this.isSecondary = false,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isSecondary
            ? colorScheme.surfaceContainerHighest
            : colorScheme.tertiaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: isSecondary
            ? null
            : Border.all(
                color: colorScheme.tertiary.withOpacity(0.3),
                width: 0.5,
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isSecondary
                ? colorScheme.onSurfaceVariant
                : colorScheme.tertiary,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSecondary
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
