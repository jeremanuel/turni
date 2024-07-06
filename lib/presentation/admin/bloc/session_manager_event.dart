


import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entities/client.dart';
import '../../../domain/entities/club_partition.dart';
import '../../../domain/entities/session.dart';

part 'session_manager_event.freezed.dart';

@freezed
class SessionManagerEvent with _$SessionManagerEvent {

  factory SessionManagerEvent.changeDateEvent(DateTime newDate) = SessionChangeDateEvent;

  factory SessionManagerEvent.loadSessions() = SessionLoadEvent;

  factory SessionManagerEvent.changeClubPartition(ClubPartition newClubPartition) = ChangeClubPartitionEvent;

  factory SessionManagerEvent.reloadSessionsEvent() = ReloadSessionsEvent;

  factory SessionManagerEvent.saveSession(Session session) = SaveSessionEvent;

  factory SessionManagerEvent.reserve(Session session, Client client) = ReserveEvent;


}
