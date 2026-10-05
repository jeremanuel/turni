import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/types/time_interval.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/create_sessions_result.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/entities/price_tariff.dart';
import '../../../../domain/entities/session.dart';
import '../../../../domain/repositories/price_tariff_repository.dart';
import '../../../../domain/use_case/price/session_price_resolver.dart';
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
  PriceTariffRepository? _priceTariffRepository;

  /// Resuelto recién al usarse (no en el constructor) para que los tests que
  /// no tocan tarifas no necesiten registrar nada en el service locator.
  PriceTariffRepository get _tariffRepository =>
      _priceTariffRepository ??= sl<PriceTariffRepository>();

  // `sessionUserCases`/`priceTariffRepository` son inyectables (por default
  // arma los reales) para poder testear el bloc sin pegarle a la red.
  CreateSesssionsFormBloc({
    SessionUserCases? sessionUserCases,
    PriceTariffRepository? priceTariffRepository,
  })  : _sessionUserCases = sessionUserCases ??
            SessionUserCases(
              SessionRepositoryImplementation(sessionProvider: SessionProvider()),
            ),
        _priceTariffRepository = priceTariffRepository,
        // El intervalo inicial se calcula a mano porque el preset por
        // defecto (DatePreset.week) necesita DateTime.now() — @Default no
        // admite eso, y si no lo seteamos acá el chip arranca marcado pero
        // el intervalo queda null (0 días) hasta que el usuario lo reselecciona.
        super(_initialState()) {
    on<ChangeSelectionClubPartition>((
      ChangeSelectionClubPartition event,
      emit,
    ) async {
      // Una modalidad inactiva se muestra deshabilitada: no se puede elegir.
      if (event.value && !event.clubPartition.active) return;

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

      final clubPartitionId = event.clubPartition.club_partition_id;
      if (event.value &&
          clubPartitionId != null &&
          !state.tariffsByClubPartition.containsKey(clubPartitionId)) {
        await _loadTariffs([clubPartitionId], emit);
      }
    });

    on<ChangeSelectionPhysicalPartition>((
      ChangeSelectionPhysicalPartition event,
      emit,
    ) {
      if (event.value && !event.physicalPartition.active) return;

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
      //
      // El precio de cada turno también entra en la clave: se resuelve por
      // cancha (tarifa por horario, precio fijo de la cancha o precio
      // manual) y por día de semana, así que dos canchas con los mismos
      // horarios pero distinta tarifa van en llamadas separadas.
      final resolver = state.priceResolver;
      final groups = <String, _PartitionGroup>{};
      for (final partition in state.selectedPhysicalPartitions) {
        final effective = state.effectiveSessionsForPartition(
          partition.partitionPhysicalId,
        );
        final prices = [
          for (final s in effective)
            resolver.pricesByDayOfWeek(
              partition: partition,
              startMinutes: s.startTime.hour * 60 + s.startTime.minute,
              manualPrice: state.manualPriceFor(partition.partitionPhysicalId, s),
            ),
        ];
        final key = [
          for (var i = 0; i < effective.length; i++)
            '${effective[i].startTime.hour}:${effective[i].startTime.minute}'
                '-${effective[i].duration}=${prices[i].values.join('/')}',
        ].join(',');
        groups
            .putIfAbsent(key, () => _PartitionGroup(effective, prices))
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
          pricesByDayOfWeek: group.pricesByDayOfWeek,
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
      // Las tarifas ya traídas se conservan: no dependen de la plantilla.
      emit(_initialState().copyWith(
        tariffsByClubPartition: state.tariffsByClubPartition,
      ));
    });

    on<ChangePriceDayOfWeek>((event, emit) {
      emit(state.copyWith(priceDayOfWeek: event.dayOfWeek));
    });

    on<SetManualPrice>((event, emit) {
      final all = Map<int, Map<Session, double>>.from(state.courtManualPrices);
      final forPartition = Map<Session, double>.from(
        all[event.partitionPhysicalId] ?? const {},
      );
      if (event.price == null) {
        forPartition.remove(event.session);
      } else {
        forPartition[event.session] = event.price!;
      }
      all[event.partitionPhysicalId] = forPartition;
      emit(state.copyWith(courtManualPrices: all));
    });

    on<ReloadTariffs>((event, emit) async {
      final ids = state.selectedClubPartitions
          .map((p) => p.club_partition_id)
          .whereType<int>()
          .toList();
      if (ids.isEmpty) return;
      await _loadTariffs(ids, emit);
    });

    on<SyncClubPartitions>((event, emit) {
      final freshById = {
        for (final partition in event.clubPartitions)
          if (partition.club_partition_id != null)
            partition.club_partition_id!: partition,
      };

      final selectedClubPartitions = state.selectedClubPartitions
          .map((p) => freshById[p.club_partition_id])
          .whereType<ClubPartition>()
          .where((p) => p.active)
          .toList();

      final freshPhysicalById = {
        for (final partition in selectedClubPartitions)
          for (final physical
              in partition.physicalPartitions ?? const <PhysicalPartition>[])
            physical.partitionPhysicalId: physical,
      };

      final selectedPhysicalPartitions = state.selectedPhysicalPartitions
          .map((p) => freshPhysicalById[p.partitionPhysicalId])
          .whereType<PhysicalPartition>()
          .where((p) => p.active)
          .toList();

      emit(state.copyWith(
        selectedClubPartitions: selectedClubPartitions,
        selectedPhysicalPartitions: selectedPhysicalPartitions,
      ));
    });
  }

  static CreateSesssionsFormState _initialState() => _CreateSessionManagerState(
        interval: DatePreset.week.toInterval(),
        priceDayOfWeek: DateTime.now().weekday,
      );

  /// Trae las tarifas de las modalidades [clubPartitionIds] y las mergea en el
  /// estado. Si falla, la modalidad queda sin tarifas (se usa el precio fijo
  /// de cada cancha) en vez de bloquear la carga de turnos.
  Future<void> _loadTariffs(
    List<int> clubPartitionIds,
    Emitter<CreateSesssionsFormState> emit,
  ) async {
    emit(state.copyWith(isLoadingTariffs: true));

    final results = await Future.wait(
      clubPartitionIds.map(_tariffRepository.listByClubPartition),
    );

    final merged =
        Map<int, List<PriceTariff>>.from(state.tariffsByClubPartition);
    for (var i = 0; i < clubPartitionIds.length; i++) {
      merged[clubPartitionIds[i]] = switch (results[i]) {
        Right(:final value) => value,
        Left() => const <PriceTariff>[],
      };
    }

    emit(state.copyWith(
      tariffsByClubPartition: merged,
      isLoadingTariffs: false,
    ));
  }
}

/// Turnos a crear + canchas que comparten exactamente esos mismos turnos
/// (y precios) — una entrada por cada combinacion distinta (ver el handler
/// de CreateSessions).
class _PartitionGroup {
  _PartitionGroup(this.sessions, this.pricesByDayOfWeek);

  final List<Session> sessions;

  /// Alineado con [sessions]: precio de cada turno por día de semana (1..7).
  final List<Map<int, double>> pricesByDayOfWeek;
  final List<int> partitionIds = [];
}
