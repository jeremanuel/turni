import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/routine/exercise.dart';
import '../../../../domain/entities/routine/routine.dart';
import '../../../../domain/entities/routine/routine_exercise.dart';
import '../../../../domain/entities/routine/routine_group.dart';
import '../cubit/new_routine_cubit.dart';
import '../widgets/routine_card.dart';

class PreviousRoutines extends StatelessWidget {
  const PreviousRoutines({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<NewRoutineCubit, NewRoutineState>(
      buildWhen: (previous, current) => previous.previusRoutines != current.previusRoutines,
      builder: (context, state) {

        if(state.previusRoutines == null) {
          context.read<NewRoutineCubit>().loadPreviusRoutines();
          return Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 16),
          itemCount: state.previusRoutines!.length,
          itemBuilder: (context, index) => RoutineCard(routine: state.previusRoutines![index]),
          separatorBuilder: (context, index) => const SizedBox(height: 16),
        );
      },
    );
  }
}
