import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import 'package:turni/core/utils/either.dart';
import 'package:turni/core/utils/types/time_interval.dart';
import 'package:turni/domain/entities/club_partition.dart';
import 'package:turni/domain/entities/create_sessions_result.dart';
import 'package:turni/domain/entities/physical_partition.dart';
import 'package:turni/domain/entities/price_rule.dart';
import 'package:turni/domain/entities/price_tariff.dart';
import 'package:turni/domain/entities/session.dart';
import 'package:turni/domain/repositories/price_tariff_repository.dart';
import 'package:turni/domain/repositories/session_repository.dart';
import 'package:turni/domain/usercases/session_user_cases.dart';
import 'package:turni/presentation/admin/create_session_screen/bloc/create_sesssions_form_bloc.dart';
import 'package:turni/presentation/admin/create_session_screen/bloc/date_preset.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

class _MockPriceTariffRepository extends Mock implements PriceTariffRepository {}

void main() {
  late _MockSessionRepository repository;
  late _MockPriceTariffRepository tariffRepository;
  late SessionUserCases userCases;

  // Rango fijo (un solo día) para no depender de DateTime.now() en los asserts.
  final interval = TimeInterval(
    initialDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 1, 1),
  );

  final templateSession = Session.fromDates(
    DateTime(2026, 1, 1, 8, 30),
    const TimeOfDay(hour: 1, minute: 0),
  );

  final physicalPartition = PhysicalPartition(
    partitionPhysicalId: 10,
    clubPartitionId: 1,
    minPlayers: 1,
    maxPlayers: 4,
    physicalIdentifier: 1,
    isCover: 'true',
    description: '',
  );

  setUp(() {
    repository = _MockSessionRepository();
    tariffRepository = _MockPriceTariffRepository();
    userCases = SessionUserCases(repository);
  });

  CreateSesssionsFormBloc buildBloc() => CreateSesssionsFormBloc(
        sessionUserCases: userCases,
        priceTariffRepository: tariffRepository,
      );

  // Estado de partida ya listo para crear (plantilla + cancha + fecha
  // elegidas) — seedeado directo, sin pasar por el stream de eventos, para
  // que el `expect` de cada test solo vea los estados que dispara
  // CreateSessions.
  CreateSesssionsFormState readySeed() => CreateSesssionsFormState(
        sessions: [templateSession],
        selectedPhysicalPartitions: [physicalPartition],
        interval: interval,
      );

  group('CreateSessions', () {
    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'muestra isSubmitting mientras está en vuelo y lo apaga con el resultado',
      build: buildBloc,
      seed: readySeed,
      act: (bloc) => bloc.add(const CreateSessions()),
      setUp: () {
        when(() => repository.createSessions(any(), any(), any(), pricesByDayOfWeek: any(named: 'pricesByDayOfWeek'))).thenAnswer(
          (_) async => const CreateSessionsResult(createdCount: 5, skipped: []),
        );
      },
      wait: const Duration(milliseconds: 1),
      expect: () => [
        predicate<CreateSesssionsFormState>(
          (s) => s.isSubmitting == true && s.savedSessions == false,
          'isSubmitting=true, savedSessions=false',
        ),
        predicate<CreateSesssionsFormState>(
          (s) =>
              s.isSubmitting == false &&
              s.savedSessions == true &&
              s.createdCount == 5 &&
              s.skippedSessions.isEmpty,
          'isSubmitting=false, savedSessions=true, createdCount=5, sin skips',
        ),
      ],
      verify: (_) {
        verify(() => repository.createSessions(any(), any(), any(), pricesByDayOfWeek: any(named: 'pricesByDayOfWeek'))).called(1);
      },
    );

    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'reporta el detalle de los turnos no creados por superposición',
      build: buildBloc,
      seed: readySeed,
      act: (bloc) => bloc.add(const CreateSessions()),
      setUp: () {
        when(() => repository.createSessions(any(), any(), any(), pricesByDayOfWeek: any(named: 'pricesByDayOfWeek'))).thenAnswer(
          (_) async => CreateSessionsResult(
            createdCount: 1,
            skipped: [
              SkippedSession(
                partitionPhysicalId: physicalPartition.partitionPhysicalId,
                startTime: DateTime(2026, 1, 1, 8, 30),
                duration: 60,
                reason: SkipReason.overlap,
                conflictingSessionIds: const [999],
              ),
            ],
          ),
        );
      },
      wait: const Duration(milliseconds: 1),
      expect: () => [
        predicate<CreateSesssionsFormState>((s) => s.isSubmitting == true),
        predicate<CreateSesssionsFormState>((s) {
          if (!s.savedSessions || s.skippedSessions.length != 1) return false;
          final skipped = s.skippedSessions.first;
          return s.createdCount == 1 &&
              skipped.reason == SkipReason.overlap &&
              skipped.reason.label == 'Superposición con turno existente' &&
              skipped.timeRangeLabel == '08:30 – 09:30' &&
              skipped.conflictingSessionIds.contains(999);
        }, 'incluye el turno saltado con motivo de superposición'),
      ],
    );

    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'ignora un segundo submit mientras el primero sigue en vuelo (no duplica la llamada)',
      build: buildBloc,
      seed: readySeed,
      act: (bloc) {
        bloc.add(const CreateSessions());
        bloc.add(const CreateSessions());
      },
      setUp: () {
        when(() => repository.createSessions(any(), any(), any(), pricesByDayOfWeek: any(named: 'pricesByDayOfWeek'))).thenAnswer(
          (_) async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return const CreateSessionsResult(createdCount: 1, skipped: []);
          },
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repository.createSessions(any(), any(), any(), pricesByDayOfWeek: any(named: 'pricesByDayOfWeek'))).called(1);
      },
    );

    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'agrupa canchas con la misma plantilla efectiva en una sola llamada, '
      'y separa las que tienen ajustes propios en otra',
      build: buildBloc,
      seed: () {
        final secondSession = Session.fromDates(
          DateTime(2026, 1, 1, 10, 0),
          const TimeOfDay(hour: 1, minute: 0),
        );
        final partitionWithOverride = PhysicalPartition(
          partitionPhysicalId: 30,
          clubPartitionId: 1,
          minPlayers: 1,
          maxPlayers: 4,
          physicalIdentifier: 3,
          isCover: 'true',
          description: '',
        );
        final partitionSameAsFirst = PhysicalPartition(
          partitionPhysicalId: 20,
          clubPartitionId: 1,
          minPlayers: 1,
          maxPlayers: 4,
          physicalIdentifier: 2,
          isCover: 'true',
          description: '',
        );

        return CreateSesssionsFormState(
          sessions: [templateSession, secondSession],
          selectedPhysicalPartitions: [
            physicalPartition,
            partitionSameAsFirst,
            partitionWithOverride,
          ],
          interval: interval,
          courtRemovedSessions: {
            partitionWithOverride.partitionPhysicalId: [templateSession],
          },
        );
      },
      act: (bloc) => bloc.add(const CreateSessions()),
      setUp: () {
        when(() => repository.createSessions(captureAny(), captureAny(), any(), pricesByDayOfWeek: any(named: 'pricesByDayOfWeek')))
            .thenAnswer((_) async => const CreateSessionsResult(createdCount: 1, skipped: []));
      },
      wait: const Duration(milliseconds: 1),
      verify: (_) {
        final captured =
            verify(() => repository.createSessions(captureAny(), captureAny(), any(), pricesByDayOfWeek: any(named: 'pricesByDayOfWeek')))
                .captured;

        expect(captured.length, 4);

        final firstGroupSessions = captured[0] as List<Session>;
        final firstGroupPartitionIds = captured[1] as List<int>;
        final secondGroupSessions = captured[2] as List<Session>;
        final secondGroupPartitionIds = captured[3] as List<int>;

        // Grupo 1: las dos canchas sin ajustes propios, con la plantilla completa.
        expect(firstGroupSessions, hasLength(2));
        expect(firstGroupPartitionIds.toSet(), {10, 20});

        // Grupo 2: la cancha con un turno quitado, sola, con la plantilla reducida.
        expect(secondGroupSessions, [
          anything,
        ]);
        expect(secondGroupPartitionIds, [30]);
      },
    );
  });

  group('ChangeDatePreset', () {
    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'hoy resuelve un intervalo de un solo día',
      build: buildBloc,
      act: (bloc) => bloc.add(const ChangeDatePreset(DatePreset.today)),
      expect: () => [
        predicate<CreateSesssionsFormState>((s) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          return s.datePreset == DatePreset.today &&
              s.interval?.initialDate == today &&
              s.interval?.endDate == today;
        }, 'datePreset=today con intervalo de hoy a hoy'),
      ],
    );

    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'personalizado conserva el intervalo que ya estaba elegido',
      build: buildBloc,
      seed: () => CreateSesssionsFormState(
        interval: interval,
        datePreset: DatePreset.week,
      ),
      act: (bloc) => bloc.add(const ChangeDatePreset(DatePreset.custom)),
      expect: () => [
        predicate<CreateSesssionsFormState>(
          (s) => s.datePreset == DatePreset.custom && s.interval == interval,
          'datePreset=custom, intervalo sin cambios',
        ),
      ],
    );
  });

  group('Ajustes por cancha', () {
    final partitionB = PhysicalPartition(
      partitionPhysicalId: 11,
      clubPartitionId: 1,
      minPlayers: 1,
      maxPlayers: 4,
      physicalIdentifier: 2,
      isCover: 'true',
      description: '',
    );

    final secondTemplateSession = Session.fromDates(
      DateTime(2026, 1, 1, 10, 0),
      const TimeOfDay(hour: 1, minute: 0),
    );

    CreateSesssionsFormState baseSeed() => CreateSesssionsFormState(
          sessions: [templateSession, secondTemplateSession],
          selectedPhysicalPartitions: [physicalPartition, partitionB],
          interval: interval,
        );

    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'quitar un turno de una cancha solo la afecta a ella',
      build: buildBloc,
      seed: baseSeed,
      act: (bloc) => bloc.add(
        RemoveSessionFromPartition(
          physicalPartition.partitionPhysicalId,
          templateSession,
        ),
      ),
      expect: () => [
        predicate<CreateSesssionsFormState>((s) {
          final affected = s.effectiveSessionsForPartition(
            physicalPartition.partitionPhysicalId,
          );
          final untouched = s.effectiveSessionsForPartition(
            partitionB.partitionPhysicalId,
          );
          return affected.length == 1 &&
              affected.single == secondTemplateSession &&
              untouched.length == 2;
        }, 'la cancha afectada pierde el turno, la otra queda igual'),
      ],
    );

    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'agregar y luego quitar un turno extra en una cancha la deja como estaba',
      build: buildBloc,
      seed: baseSeed,
      act: (bloc) {
        final extraSession = Session.fromDates(
          DateTime(2026, 1, 1, 18, 0),
          const TimeOfDay(hour: 1, minute: 0),
        );
        bloc.add(
          AddExtraSessionToPartition(
            physicalPartition.partitionPhysicalId,
            extraSession,
          ),
        );
        bloc.add(
          RemoveExtraSessionFromPartition(
            physicalPartition.partitionPhysicalId,
            extraSession,
          ),
        );
      },
      expect: () => [
        predicate<CreateSesssionsFormState>(
          (s) => s.effectiveSessionsForPartition(
                    physicalPartition.partitionPhysicalId,
                  ).length ==
                  3,
          'con el extra agregado',
        ),
        predicate<CreateSesssionsFormState>(
          (s) => s.effectiveSessionsForPartition(
                    physicalPartition.partitionPhysicalId,
                  ).length ==
                  2,
          'vuelve a la plantilla original tras quitarlo',
        ),
      ],
    );
  });

  group('Estado inicial y reseteo', () {
    test(
      'el estado inicial ya trae resuelto el intervalo del preset por defecto',
      () {
        final bloc = buildBloc();

        expect(bloc.state.datePreset, DatePreset.week);
        expect(bloc.state.interval, isNotNull);
        expect(bloc.state.interval!.generateDateRange(), hasLength(7));

        bloc.close();
      },
    );

    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'ResetForm vuelve a un estado en blanco, con el intervalo del preset '
      'por defecto ya resuelto (no en 0 días)',
      build: buildBloc,
      seed: () => CreateSesssionsFormState(
        sessions: [templateSession],
        selectedPhysicalPartitions: [physicalPartition],
        interval: interval,
        datePreset: DatePreset.custom,
        createdCount: 5,
        savedSessions: true,
      ),
      act: (bloc) => bloc.add(const ResetForm()),
      expect: () => [
        predicate<CreateSesssionsFormState>((s) {
          return s.sessions.isEmpty &&
              s.selectedPhysicalPartitions.isEmpty &&
              s.savedSessions == false &&
              s.createdCount == 0 &&
              s.datePreset == DatePreset.week &&
              s.interval != null &&
              s.interval!.generateDateRange().length == 7;
        }, 'plantilla y selección vacías, con el rango de 7 días ya resuelto'),
      ],
    );
  });

  group('Tarifas por horario', () {
    final clubPartition = ClubPartition(
      club_partition_id: 1,
      club_id: 1,
      club_type_id: 1,
      physicalPartitions: [physicalPartition],
    );

    // Franja de lunes a viernes de 8 a 12 ($9.000) sobre la cancha 10; el
    // resto de los días se cobra el precio base de la cancha ($4.000).
    final morningTariff = PriceTariff(
      priceTariffId: 100,
      clubPartitionId: 1,
      name: 'Mañana',
      active: true,
      memberPartitionPhysicalIds: [physicalPartition.partitionPhysicalId],
      rules: [
        PriceRule(
          priceRuleId: 7,
          priceTariffId: 100,
          daysOfWeek: const [1, 2, 3, 4, 5],
          startTime: '08:00',
          endTime: '12:00',
          price: 9000,
          active: true,
        ),
      ],
    );

    final pricedPartition = physicalPartition.copyWith(defaultSessionPrice: 4000);

    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'al seleccionar una modalidad trae sus tarifas',
      build: buildBloc,
      setUp: () {
        when(() => tariffRepository.listByClubPartition(1))
            .thenAnswer((_) async => Right([morningTariff]));
      },
      act: (bloc) => bloc.add(ChangeSelectionClubPartition(clubPartition, true)),
      wait: const Duration(milliseconds: 1),
      verify: (bloc) {
        expect(bloc.state.tariffsByClubPartition[1], [morningTariff]);
        expect(bloc.state.isLoadingTariffs, isFalse);
      },
    );

    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'no deja seleccionar una modalidad ni una cancha inactivas',
      build: buildBloc,
      act: (bloc) {
        bloc.add(ChangeSelectionClubPartition(clubPartition.copyWith(active: false), true));
        bloc.add(ChangeSelectionPhysicalPartition(physicalPartition.copyWith(active: false), true));
      },
      expect: () => const <CreateSesssionsFormState>[],
      verify: (_) => verifyNever(() => tariffRepository.listByClubPartition(any())),
    );

    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'resuelve el precio del día elegido con la regla que aplica',
      build: buildBloc,
      seed: () => CreateSesssionsFormState(
        sessions: [templateSession],
        selectedPhysicalPartitions: [pricedPartition],
        tariffsByClubPartition: {1: [morningTariff]},
        priceDayOfWeek: 1,
      ),
      act: (bloc) => bloc.add(const ChangePriceDayOfWeek(6)),
      verify: (bloc) {
        final saturday = bloc.state.resolvePrice(pricedPartition, templateSession);
        final monday = bloc.state.resolvePrice(pricedPartition, templateSession, dayOfWeek: 1);
        expect(saturday.price, 4000);
        expect(monday.price, 9000);
        expect(monday.rule?.priceRuleId, 7);
      },
    );

    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'manda al backend el precio de cada turno por día de semana, '
      'con el precio manual pisando la tarifa solo en su cancha',
      build: buildBloc,
      seed: () {
        final otherCourt = pricedPartition.copyWith(partitionPhysicalId: 20);
        return CreateSesssionsFormState(
          sessions: [templateSession],
          selectedPhysicalPartitions: [pricedPartition, otherCourt],
          interval: interval,
          tariffsByClubPartition: {
            1: [
              PriceTariff(
                priceTariffId: morningTariff.priceTariffId,
                clubPartitionId: 1,
                name: morningTariff.name,
                active: true,
                memberPartitionPhysicalIds: const [10, 20],
                rules: morningTariff.rules,
              ),
            ],
          },
          courtManualPrices: {
            20: {templateSession: 6500},
          },
        );
      },
      act: (bloc) => bloc.add(const CreateSessions()),
      setUp: () {
        when(() => repository.createSessions(any(), any(), any(),
                pricesByDayOfWeek: any(named: 'pricesByDayOfWeek')))
            .thenAnswer((_) async => const CreateSessionsResult(createdCount: 1, skipped: []));
      },
      wait: const Duration(milliseconds: 1),
      verify: (_) {
        final calls = verify(() => repository.createSessions(any(), captureAny(), any(),
                pricesByDayOfWeek: captureAny(named: 'pricesByDayOfWeek')))
            .captured;

        // Dos llamadas: misma plantilla pero distinto precio por cancha.
        expect(calls, hasLength(4));
        final byPartition = {
          for (var i = 0; i < calls.length; i += 2)
            (calls[i] as List<int>).single: (calls[i + 1] as List<Map<int, double>>).single,
        };

        expect(byPartition[10], {1: 9000, 2: 9000, 3: 9000, 4: 9000, 5: 9000, 6: 4000, 7: 4000});
        expect(byPartition[20]!.values.toSet(), {6500});
      },
    );

    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'SyncClubPartitions descarta de la selección lo que quedó inactivo',
      build: buildBloc,
      seed: () => CreateSesssionsFormState(
        selectedClubPartitions: [clubPartition],
        selectedPhysicalPartitions: [physicalPartition],
      ),
      act: (bloc) => bloc.add(SyncClubPartitions([
        clubPartition.copyWith(
          physicalPartitions: [physicalPartition.copyWith(active: false)],
        ),
      ])),
      expect: () => [
        predicate<CreateSesssionsFormState>(
          (s) => s.selectedClubPartitions.length == 1 && s.selectedPhysicalPartitions.isEmpty,
          'mantiene la modalidad activa y saca la cancha inactiva',
        ),
      ],
    );
  });
}
