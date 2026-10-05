part of 'create_sesssions_form_bloc.dart';

@freezed
sealed class CreateSesssionsFormEvent with _$CreateSesssionsFormEvent {
  const factory CreateSesssionsFormEvent.started() = _Started;
  const factory CreateSesssionsFormEvent.changeSelectionClubPartition(ClubPartition clubPartition, bool value) = ChangeSelectionClubPartition;
  const factory CreateSesssionsFormEvent.changeSelectionPhysicalPartition(PhysicalPartition physicalPartition, bool value) = ChangeSelectionPhysicalPartition;
  const factory CreateSesssionsFormEvent.changeSelectionDate(TimeInterval newDate) = ChangeSelectionInitialDate;
  const factory CreateSesssionsFormEvent.addSession(Session session) = AddSession;
  const factory CreateSesssionsFormEvent.addSessions(List<Session> sessions) = AddSessions;
  const factory CreateSesssionsFormEvent.editSession(Session oldSession, Session newSession) = EditSession;
  const factory CreateSesssionsFormEvent.seleteSession(Session session) = DeleteSession;
  const factory CreateSesssionsFormEvent.createSessions() = CreateSessions;
  const factory CreateSesssionsFormEvent.changeDatePreset(DatePreset preset) = ChangeDatePreset;
  const factory CreateSesssionsFormEvent.removeSessionFromPartition(int partitionPhysicalId, Session session) = RemoveSessionFromPartition;
  const factory CreateSesssionsFormEvent.addExtraSessionToPartition(int partitionPhysicalId, Session session) = AddExtraSessionToPartition;
  const factory CreateSesssionsFormEvent.removeExtraSessionFromPartition(int partitionPhysicalId, Session session) = RemoveExtraSessionFromPartition;
  const factory CreateSesssionsFormEvent.resetForm() = ResetForm;
  const factory CreateSesssionsFormEvent.changePriceDayOfWeek(int dayOfWeek) = ChangePriceDayOfWeek;
  /// `price` null vuelve a usar la tarifa.
  const factory CreateSesssionsFormEvent.setManualPrice(int partitionPhysicalId, Session session, double? price) = SetManualPrice;
  /// Vuelve a traer las tarifas de las modalidades seleccionadas (ej. al volver de la configuración).
  const factory CreateSesssionsFormEvent.reloadTariffs() = ReloadTariffs;
  /// Reemplaza la selección por las versiones frescas de [clubPartitions] y
  /// descarta lo que ya no existe o quedó inactivo.
  const factory CreateSesssionsFormEvent.syncClubPartitions(List<ClubPartition> clubPartitions) = SyncClubPartitions;
}
