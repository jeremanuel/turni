part of 'create_sesssions_form_bloc.dart';

@freezed
sealed class CreateSesssionsFormState with _$CreateSesssionsFormState {
  const factory CreateSesssionsFormState({
    @Default([]) List<ClubPartition> selectedClubPartitions,
    @Default([]) List<PhysicalPartition> selectedPhysicalPartitions,
    TimeInterval? interval,
    @Default([]) List<Session> sessions,

    @Default(false) bool savedSessions,

    /// Turnos descartados en la última carga masiva (superposición u otro motivo).
    @Default([]) List<SkippedSession> skippedSessions,

    /// Cuántos turnos se crearon exitosamente en la última carga masiva.
    @Default(0) int createdCount,
  }) = _CreateSessionManagerState;
}
