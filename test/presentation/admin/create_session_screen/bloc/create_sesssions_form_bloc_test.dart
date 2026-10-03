import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import 'package:turni/core/utils/types/time_interval.dart';
import 'package:turni/domain/entities/create_sessions_result.dart';
import 'package:turni/domain/entities/physical_partition.dart';
import 'package:turni/domain/entities/session.dart';
import 'package:turni/domain/repositories/session_repository.dart';
import 'package:turni/domain/usercases/session_user_cases.dart';
import 'package:turni/presentation/admin/create_session_screen/bloc/create_sesssions_form_bloc.dart';
import 'package:turni/presentation/admin/create_session_screen/bloc/date_preset.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late _MockSessionRepository repository;
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
    userCases = SessionUserCases(repository);
  });

  CreateSesssionsFormBloc buildBloc() =>
      CreateSesssionsFormBloc(sessionUserCases: userCases);

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
        when(() => repository.createSessions(any(), any(), any())).thenAnswer(
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
        verify(() => repository.createSessions(any(), any(), any())).called(1);
      },
    );

    blocTest<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      'reporta el detalle de los turnos no creados por superposición',
      build: buildBloc,
      seed: readySeed,
      act: (bloc) => bloc.add(const CreateSessions()),
      setUp: () {
        when(() => repository.createSessions(any(), any(), any())).thenAnswer(
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
        when(() => repository.createSessions(any(), any(), any())).thenAnswer(
          (_) async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return const CreateSessionsResult(createdCount: 1, skipped: []);
          },
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repository.createSessions(any(), any(), any())).called(1);
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
        when(() => repository.createSessions(captureAny(), captureAny(), any()))
            .thenAnswer((_) async => const CreateSessionsResult(createdCount: 1, skipped: []));
      },
      wait: const Duration(milliseconds: 1),
      verify: (_) {
        final captured =
            verify(() => repository.createSessions(captureAny(), captureAny(), any()))
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
}
