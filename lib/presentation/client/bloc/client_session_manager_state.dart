import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/entities/range_date.dart';
import '../../../domain/entities/club_type.dart';
import '../../../domain/entities/session.dart';

part 'client_session_manager_state.freezed.dart';

@freezed
class ClientSessionManagerState with _$ClientSessionManagerState {
  factory ClientSessionManagerState({
    required DateTime currentDate,
    required List<Session> sessions,
    RangeDate? rangeDate,
    @Default([]) List<Session> filteredSessions,
    @Default(null) ClubType? clubType,
    @Default(false) isFirstLoad,
    @Default(false) isLoadingSessions,
  }) = _ClientSessionManagerState;
}
