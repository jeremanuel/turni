
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/entities/session.dart';

part 'session_manager_state.freezed.dart';

@freezed
class SessionManagerState with _$SessionManagerState{

  factory SessionManagerState({
    required DateTime currentDate,
    required List<Session> sessions,
    @Default(false) isFirstLoad,

    @Default(false) isLoadingSessions
  }) = _SessionManagerState;
}


