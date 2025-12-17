import 'package:freezed_annotation/freezed_annotation.dart';

import 'routine_group.dart';

part 'routine.freezed.dart';
part 'routine.g.dart';

@freezed
sealed class Routine with _$Routine {

  factory Routine({
    required String routineId,
    required DateTime createdAt,
    DateTime? endDate,
    required List<RoutineGroup> exercises,
    
  }) = _Routine;

  factory Routine.fromJson(Map<String, dynamic> json) => _$RoutineFromJson(json);
}