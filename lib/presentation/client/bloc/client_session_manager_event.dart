import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entities/club_type.dart';

part 'client_session_manager_event.freezed.dart';

@freezed
sealed class ClientSessionManagerEvent with _$ClientSessionManagerEvent {
  factory ClientSessionManagerEvent.loadSessions() = ClientSessionLoadEvent;

  factory ClientSessionManagerEvent.loadClubType(ClubType clubType) =
      LoadClubTypeEvent;

  factory ClientSessionManagerEvent.changeDateEvent(DateTime newDate) =
      ClientSessionChangeDateEvent;
}
