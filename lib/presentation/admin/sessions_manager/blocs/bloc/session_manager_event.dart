


import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_manager_event.freezed.dart';

@freezed
class SessionManagerEvent with _$SessionManagerEvent {

  factory SessionManagerEvent.changeDateEvent(DateTime newDate) = SessionChangeDateEvent;

  factory SessionManagerEvent.loadSessions() = SessionLoadEvent;

}
