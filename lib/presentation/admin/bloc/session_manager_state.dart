
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/domain_error.dart';
import '../../../domain/entities/club_partition.dart';
import '../../../domain/entities/session.dart';

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
    DomainError? error,
    /// Error de la última acción de aceptar/rechazar una solicitud de turno
    /// (ej. 409 `STALE_STATUS`). Separado de [error] a propósito: ese otro
    /// campo dispara una navegación de vuelta a la agenda general (ver
    /// `session_manager_route.dart`), que no tiene sentido acá — la acción
    /// ya ocurre estando parado en la agenda.
    DomainError? actionError,
  }) = _SessionManagerState;
}


