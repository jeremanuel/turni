part of 'create_sesssions_form_bloc.dart';

@freezed
class CreateSesssionsFormEvent with _$CreateSesssionsFormEvent {
  const factory CreateSesssionsFormEvent.started() = _Started;
  const factory CreateSesssionsFormEvent.changeSelectionClubPartition(ClubPartition clubPartition, bool value) = ChangeSelectionClubPartition;
  const factory CreateSesssionsFormEvent.changeSelectionPhysicalPartition(PhysicalPartition physicalPartition, bool value) = ChangeSelectionPhysicalPartition;
  const factory CreateSesssionsFormEvent.changeSelectionDate(TimeInterval newDate) = ChangeSelectionInitialDate;
  const factory CreateSesssionsFormEvent.addSession(Session session) = AddSession;
  const factory CreateSesssionsFormEvent.editSession(Session oldSession, Session newSession) = EditSession;
  const factory CreateSesssionsFormEvent.seleteSession(Session session) = DeleteSession;
  const factory CreateSesssionsFormEvent.createSessions() = CreateSessions;



}