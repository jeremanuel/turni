import 'package:freezed_annotation/freezed_annotation.dart';

import 'exercise.dart';

part 'routine_exercise.freezed.dart';
part 'routine_exercise.g.dart';

@freezed
sealed class RoutineExercise with _$RoutineExercise {

  factory RoutineExercise({
    required int id,
    required Exercise? exercise,
    required String sets,
    required String repetitions,
    required String weight,
    String? observations
  }) = _RoutineExercise;

    RoutineExercise._();

  factory RoutineExercise.fromJson(Map<String, dynamic> json) => _$RoutineExerciseFromJson(json);

  isComplete() {
    return sets.isNotEmpty && repetitions.isNotEmpty && weight.isNotEmpty;
  }
}