part of 'create_sesssions_form_bloc.dart';

@freezed
class CreateSesssionsFormState with _$CreateSesssionsFormState {
  const factory CreateSesssionsFormState({
    @Default([]) List<ClubPartition> selectedClubPartitions,
    @Default([]) List<PhysicalPartition> selectedPhysicalPartitions,
    TimeInterval? interval,
    @Default([]) List<Session> sessions,

    @Default(false) bool savedSessions


  }) = _CreateSessionManagerState;



}


