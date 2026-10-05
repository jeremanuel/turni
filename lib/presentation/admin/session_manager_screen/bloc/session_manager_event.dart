


import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/session.dart';

part 'session_manager_event.freezed.dart';

@freezed
sealed class SessionManagerEvent with _$SessionManagerEvent {

  factory SessionManagerEvent.changeDateEvent(DateTime newDate) = SessionChangeDateEvent;

  factory SessionManagerEvent.loadSessions() = SessionLoadEvent;

  factory SessionManagerEvent.changeClubPartition(ClubPartition newClubPartition) = ChangeClubPartitionEvent;

  factory SessionManagerEvent.reloadSessionsEvent() = ReloadSessionsEvent;

  /// Vuelve a traer los sectores/canchas (ej. al cerrar la configuración,
  /// donde se pudo activar/desactivar alguno).
  factory SessionManagerEvent.reloadClubPartitions() = ReloadClubPartitionsEvent;

  factory SessionManagerEvent.saveSession(Session session) = SaveSessionEvent;

  factory SessionManagerEvent.reserve(Session session, Client client) = ReserveEvent;

  factory SessionManagerEvent.loadFromSessionId(int sessionId, bool isFirstLoad) = LoadFromSessionIdEvent;

  factory SessionManagerEvent.deleteSession(int sessionId) = DeleteSession;

  factory SessionManagerEvent.setSelectedSession(Session? session) = SetSelectedSession;

  factory SessionManagerEvent.acceptSessionRequest(int sessionId) = AcceptSessionRequest;

  factory SessionManagerEvent.rejectSessionRequest(int sessionId) = RejectSessionRequest;

}
