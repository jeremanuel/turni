part of 'new_routine_cubit.dart';

@freezed
sealed class NewRoutineState with _$NewRoutineState {
  const factory NewRoutineState.initial({
    required List<RoutineGroup> routineGroups,
    RoutineGroup? copiedGroup,
    RoutineExercise? copiedExercise,
    List<Routine>? previusRoutines,
    List<Routine>? lastRoutines
  }) = _Initial;
}
