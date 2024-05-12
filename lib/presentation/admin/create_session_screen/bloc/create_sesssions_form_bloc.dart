import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/types/time_interval.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/entities/session.dart';
import '../../session_manager_screen/blocs/bloc/session_manager_bloc.dart';

part 'create_sesssions_form_event.dart';
part 'create_sesssions_form_state.dart';
part 'create_sesssions_form_bloc.freezed.dart';

class CreateSesssionsFormBloc extends Bloc<CreateSesssionsFormEvent, CreateSesssionsFormState> {
  CreateSesssionsFormBloc() : super(_CreateSessionManagerState()) {
    on<CreateSesssionsFormEvent>((event, emit) {
      // TODO: implement event handler
    });

    on<ChangeSelectionClubPartition>((ChangeSelectionClubPartition event, emit){

      final currentSelectedClubPartitions = state.selectedClubPartitions.toList();

      if(event.value){
        currentSelectedClubPartitions.add(event.clubPartition);
      } else {
        currentSelectedClubPartitions.remove(event.clubPartition);
      }

      emit(
        state.copyWith(
          selectedClubPartitions: currentSelectedClubPartitions
        )
      );
      
    });

    on<ChangeSelectionPhysicalPartition>((ChangeSelectionPhysicalPartition event, emit){

      final currentSelectedClubPartitions = state.selectedPhysicalPartitions.toList();

      if(event.value){
        currentSelectedClubPartitions.add(event.physicalPartition);
      } else {
        currentSelectedClubPartitions.remove(event.physicalPartition);
      }

      emit(
        state.copyWith(
          selectedPhysicalPartitions: currentSelectedClubPartitions
        )
      );
      
    });

    on<ChangeSelectionInitialDate>((ChangeSelectionInitialDate event, emit){
      emit(
        state.copyWith(interval: event.newDate)
      );
    });
    on<AddSession>((AddSession event, emit){
      emit(
        state.copyWith(sessions: [...state.sessions, event.session])
      );
    });
    on<EditSession>((EditSession event, emit){

      final sessions = state.sessions.map((e) => e != event.oldSession ? e : event.newSession,).toList();

      emit(
        state.copyWith(sessions: sessions)
      );
    });

    on<DeleteSession>((event, emit){

      final sessions = state.sessions.where((element) => element != event.session).toList();

      emit(state.copyWith(sessions: sessions));
    });
  }
}
