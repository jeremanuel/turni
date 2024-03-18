import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/entities/club_partition.dart';
import '../../../../../domain/entities/session.dart';
import '../../../../../domain/usercases/session_user_cases.dart';
import '../../../../../infrastructure/api/repositories/session_repository_test.dart';
import 'session_manager_event.dart';
import 'session_manager_state.dart';


class SessionManagerBloc extends Bloc<SessionManagerEvent, SessionManagerState> {

  final SessionUserCases _sessionUserCases = SessionUserCases(SessionRepositoryTest());

  SessionManagerBloc() : super(SessionManagerState(currentDate: DateTime.now(), sessions: [], clubPartitions: [], isFirstLoad: true,)) {


    on<SessionChangeDateEvent>((event, emit) async {
      emit(
        state.copyWith(currentDate: event.newDate, isLoadingSessions: true),
      );

      final sessions = await _sessionUserCases.getSessions(state.currentDate);
      final clubPartitions = await _sessionUserCases.getClubPartitions();
 

      emit(
        state.copyWith(
          sessions: sessions,
          isLoadingSessions: false,
          clubPartitions: clubPartitions
        )
      );

    });

    on<SessionLoadEvent>((event, emit) async {
      emit(
        state.copyWith(isFirstLoad: true)
      );

      final [sessions as List<Session>, clubPartitions as List<ClubPartition>] = await Future.wait([
        _sessionUserCases.getSessions(state.currentDate),
        _sessionUserCases.getClubPartitions()
      ]);
      
      emit(
        state.copyWith(
          sessions: sessions,
          isFirstLoad: false,
          clubPartitions: clubPartitions,
          selectedClubPartition: clubPartitions.last
        )
      );
    });

    on<ChangeClubPartitionEvent>((event, emit){

      emit(
        state.copyWith(
          selectedClubPartition: event.newClubPartition
        )
      );

    });

    add(SessionLoadEvent());


  }


  
}
