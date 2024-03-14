import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/usercases/session_user_cases.dart';
import '../../../../../infrastructure/api/repositories/session_repository_test.dart';
import 'session_manager_event.dart';
import 'session_manager_state.dart';


class SessionManagerBloc extends Bloc<SessionManagerEvent, SessionManagerState> {

  final SessionUserCases _sessionUserCases = SessionUserCases(SessionRepositoryTest());

  SessionManagerBloc() : super(SessionManagerState(currentDate: DateTime.now(), sessions: [], isFirstLoad: true)) {


    on<SessionChangeDateEvent>((event, emit) async {
      emit(
        state.copyWith(currentDate: event.newDate, isLoadingSessions: true),
      );

      final sessions = await _sessionUserCases.getSessions(state.currentDate);
      
      emit(
        state.copyWith(
          sessions: sessions,
          isLoadingSessions: false
        )
      );

    });

    on<SessionLoadEvent>((event, emit) async {
      emit(
        state.copyWith(isFirstLoad: true)
      );

      final sessions = await _sessionUserCases.getSessions(state.currentDate);
      
      emit(
        state.copyWith(
          sessions: sessions,
          isFirstLoad: false
        )
      );
    });

    add(SessionLoadEvent());


  }
  
}
