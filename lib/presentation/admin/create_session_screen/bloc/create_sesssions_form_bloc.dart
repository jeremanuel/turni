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
import 'date_preset.dart';

part 'create_sesssions_form_event.dart';
part 'create_sesssions_form_state.dart';
part 'create_sesssions_form_bloc.freezed.dart';

class CreateSesssionsFormBloc
    extends Bloc<CreateSesssionsFormEvent, CreateSesssionsFormState> {
  final SessionUserCases _sessionUserCases;

  // `sessionUserCases` es inyectable (por default arma el real) para poder
  // testear el bloc con un SessionRepository mockeado, sin pegarle a la red.
  CreateSesssionsFormBloc({SessionUserCases? sessionUserCases})
      : _sessionUserCases = sessionUserCases ??
            SessionUserCases(
              SessionRepositoryImplementation(sessionProvider: SessionProvider()),
            ),
        // El intervalo inicial se calcula a mano porque el preset por
        // defecto (DatePreset.week) necesita DateTime.now() — @Default no
        // admite eso, y si no lo seteamos acá el chip arranca marcado pero
        // el intervalo queda null (0 días) hasta que el usuario lo reselecciona.
        super(_CreateSessionManagerState(interval: DatePreset.week.toInterval())) {
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
      if (state.isSubmitting) return;

      emit(state.copyWith(
        isSubmitting: true,
        savedSessions: false,
        createdCount: 0,
        skippedSessions: const [],
      ));

      // Agrupa canchas por su lista efectiva de turnos (plantilla +/-
      // ajustes propios de esa cancha, ver effectiveSessionsForPartition):
      // las que compartan exactamente la misma lista van en UNA sola
      // llamada al backend (caso normal, sin ajustes por cancha); las que
      // difieren disparan su propia llamada, con sus propios turnos.
      final groups = <String, _PartitionGroup>{};
      for (final partition in state.selectedPhysicalPartitions) {
        final effective = state.effectiveSessionsForPartition(
          partition.partitionPhysicalId,
        );
        final key = effective
            .map((s) => '${s.startTime.hour}:${s.startTime.minute}-${s.duration}')
            .join(',');
        groups
            .putIfAbsent(key, () => _PartitionGroup(effective))
            .partitionIds
            .add(partition.partitionPhysicalId);
      }

      var createdCount = 0;
      final skipped = <SkippedSession>[];
      for (final group in groups.values) {
        if (group.sessions.isEmpty) continue;

        final result = await _sessionUserCases.createSessions(
          group.sessions,
          group.partitionIds,
          state.interval!,
        );
        createdCount += result.createdCount;
        skipped.addAll(result.skipped);
      }

      emit(state.copyWith(
        isSubmitting: false,
        savedSessions: true,
        createdCount: createdCount,
        skippedSessions: skipped,
      ));
    });

    on<ChangeDatePreset>((ChangeDatePreset event, emit) {
      final interval = event.preset.toInterval();
      emit(state.copyWith(
        datePreset: event.preset,
        interval: interval ?? state.interval,
      ));
    });

    on<RemoveSessionFromPartition>((RemoveSessionFromPartition event, emit) {
      final current = Map<int, List<Session>>.from(state.courtRemovedSessions);
      final list = List<Session>.from(
        current[event.partitionPhysicalId] ?? const [],
      );
      if (!list.contains(event.session)) list.add(event.session);
      current[event.partitionPhysicalId] = list;
      emit(state.copyWith(courtRemovedSessions: current));
    });

    on<AddExtraSessionToPartition>((AddExtraSessionToPartition event, emit) {
      final current = Map<int, List<Session>>.from(state.courtExtraSessions);
      final list = List<Session>.from(
        current[event.partitionPhysicalId] ?? const [],
      );
      list.add(event.session);
      current[event.partitionPhysicalId] = list;
      emit(state.copyWith(courtExtraSessions: current));
    });

    on<RemoveExtraSessionFromPartition>((
      RemoveExtraSessionFromPartition event,
      emit,
    ) {
      final current = Map<int, List<Session>>.from(state.courtExtraSessions);
      final list = List<Session>.from(
        current[event.partitionPhysicalId] ?? const [],
      )..remove(event.session);
      current[event.partitionPhysicalId] = list;
      emit(state.copyWith(courtExtraSessions: current));
    });

    on<ResetForm>((event, emit) {
      emit(_CreateSessionManagerState(interval: DatePreset.week.toInterval()));
    });
  }
}

/// Turnos a crear + canchas que comparten exactamente esos mismos turnos —
/// una entrada por cada combinacion distinta (ver el handler de CreateSessions).
class _PartitionGroup {
  _PartitionGroup(this.sessions);

  final List<Session> sessions;
  final List<int> partitionIds = [];
}
