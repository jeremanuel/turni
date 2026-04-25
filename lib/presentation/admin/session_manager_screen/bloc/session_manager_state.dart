
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/domain_error.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/session.dart';

part 'session_manager_state.freezed.dart';

@freezed
sealed class SessionManagerState with _$SessionManagerState{

  factory SessionManagerState({
    required DateTime currentDate,
    required List<Session> sessions,
    required List<ClubPartition> clubPartitions,
    Session? selectedSession,
    ClubPartition? selectedClubPartition, 
    @Default(false) isFirstLoad,
    @Default(false) isLoadingSessions,
    DomainError? error
  }) = _SessionManagerState;
}


