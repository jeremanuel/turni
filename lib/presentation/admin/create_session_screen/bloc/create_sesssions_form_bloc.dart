import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/types/time_interval.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/create_sessions_result.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/entities/session.dart';
import '../../../../domain/usercases/session_user_cases.dart';
import '../../../../infrastructure/api/providers/session_provider.dart';
import '../../../../infrastructure/api/repositories/session_repository_impl.dart';

part 'create_sesssions_form_event.dart';
part 'create_sesssions_form_state.dart';
part 'create_sesssions_form_bloc.freezed.dart';

class CreateSesssionsFormBloc
    extends Bloc<CreateSesssionsFormEvent, CreateSesssionsFormState> {
  final SessionUserCases _sessionUserCases = SessionUserCases(
    SessionRepositoryImplementation(sessionProvider: SessionProvider()),
  );

  CreateSesssionsFormBloc() : super(const _CreateSessionManagerState()) {
    on<ChangeSelectionClubPartition>((
      ChangeSelectionClubPartition event,
      emit,
    ) {
      final currentSelectedClubPartitions = state.selectedClubPartitions
          .toList();
      final currentSelectedPhysicalPartitions = state.selectedPhysicalPartitions
          .toList();

      if (event.value) {
        currentSelectedClubPartitions.add(event.clubPartition);
      } else {
        currentSelectedClubPartitions.remove(event.clubPartition);

        // Keep selected courts aligned with currently selected club partitions.
        final validPhysicalIds = currentSelectedClubPartitions
            .expand((partition) => partition.physicalPartitions ?? const [])
            .map((partition) => partition.partitionPhysicalId)
            .toSet();

        currentSelectedPhysicalPartitions.removeWhere(
          (partition) =>
              !validPhysicalIds.contains(partition.partitionPhysicalId),
        );
      }

      emit(
        state.copyWith(
          selectedClubPartitions: currentSelectedClubPartitions,
          selectedPhysicalPartitions: currentSelectedPhysicalPartitions,
        ),
      );
    });

    on<ChangeSelectionPhysicalPartition>((
      ChangeSelectionPhysicalPartition event,
      emit,
    ) {
      final currentSelectedClubPartitions = state.selectedPhysicalPartitions
          .toList();

      if (event.value) {
        currentSelectedClubPartitions.add(event.physicalPartition);
      } else {
        currentSelectedClubPartitions.remove(event.physicalPartition);
      }

      emit(
        state.copyWith(
          selectedPhysicalPartitions: currentSelectedClubPartitions,
        ),
      );
    });

    on<ChangeSelectionInitialDate>((ChangeSelectionInitialDate event, emit) {
      emit(state.copyWith(interval: event.newDate));
    });
    on<AddSession>((AddSession event, emit) {
      emit(state.copyWith(sessions: [...state.sessions, event.session]));
    });
    on<AddSessions>((AddSessions event, emit) {
      if (event.sessions.isEmpty) {
        return;
      }
      emit(state.copyWith(sessions: [...state.sessions, ...event.sessions]));
    });
    on<EditSession>((EditSession event, emit) {
      final sessions = state.sessions
          .map((e) => e != event.oldSession ? e : event.newSession)
          .toList();

      emit(state.copyWith(sessions: sessions));
    });

    on<DeleteSession>((event, emit) {
      final sessions = state.sessions
          .where((element) => element != event.session)
          .toList();

      emit(state.copyWith(sessions: sessions));
    });

    on<CreateSessions>((event, emit) async {
      emit(state.copyWith(
        savedSessions: false,
        createdCount: 0,
        skippedSessions: const [],
      ));

      final result = await _sessionUserCases.createSessions(
        state.sessions,
        state.selectedPhysicalPartitions
            .map((el) => el.partitionPhysicalId)
            .toList(),
        state.interval!,
      );

      emit(state.copyWith(
        savedSessions: true,
        createdCount: result.createdCount,
        skippedSessions: result.skipped,
      ));
    });
  }
}
