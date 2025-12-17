import 'package:freezed_annotation/freezed_annotation.dart';

import 'routine_exercise.dart';

part 'routine_group.freezed.dart';
part 'routine_group.g.dart';

@freezed
sealed class RoutineGroup with _$RoutineGroup {

  factory RoutineGroup({
    required int id,
    required String groupName,
    required List<RoutineExercise> exercises
  }) = _RoutineGroup;

  factory RoutineGroup.fromJson(Map<String, dynamic> json) => _$RoutineGroupFromJson(json);
}