import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:turni/core/utils/domain_error.dart';
import 'package:turni/core/utils/either.dart';
import 'package:turni/domain/entities/bulk_sessions.dart';
import 'package:turni/domain/entities/club_partition.dart';
import 'package:turni/domain/entities/physical_partition.dart';
import 'package:turni/domain/repositories/bulk_session_repository.dart';
import 'package:turni/presentation/admin/bulk_sessions/cubit/bulk_edit_cubit.dart';

class _MockRepository extends Mock implements BulkSessionRepository {}

void main() {
  late _MockRepository repository;
  // Domingo 4/10/2026.
  final now = DateTime(2026, 10, 4, 15, 30);

  PhysicalPartition court(int id, {bool active = true}) => PhysicalPartition(
        partitionPhysicalId: id,
        clubPartitionId: 1,
        minPlayers: 1,
        maxPlayers: 4,
        physicalIdentifier: id,
        isCover: '0',
        description: null,
        active: active,
      );

  final padel = ClubPartition(
    club_partition_id: 1,
    club_id: 1,
    club_type_id: 1,
    physicalPartitions: [court(10), court(11), court(12, active: false)],
  );
  final inactive = ClubPartition(club_partition_id: 2, club_id: 1, club_type_id: 2, active: false);

  const preview = BulkPreview(
    matched: 3,
    affected: 2,
    excluded: BulkExcluded(booked: 1),
    rows: [],
    totalRows: 3,
  );

  setUpAll(() {
    registerFallbackValue(BulkPreviewView.all);
    registerFallbackValue(const BulkSessionAction(type: BulkActionType.delete));
    registerFallbackValue(BulkSessionFilters(
      from: now,
      to: now,
      daysOfWeek: const {1},
      startFrom: '00:00',
      startTo: '23:59',
      partitionPhysicalIds: const {1},
    ));
  });

  setUp(() {
    repository = _MockRepository();
    when(() => repository.preview(any(), any(), view: any(named: 'view'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Right(preview));
  });

  BulkEditCubit build() => BulkEditCubit(repository, now: () => now);

  test('arranca con los próximos 30 días y todos los días de la semana', () {
    final cubit = build();
    expect(cubit.state.from, DateTime(2026, 10, 4));
    expect(cubit.state.to, DateTime(2026, 11, 2));
    expect(cubit.state.daysOfWeek, {1, 2, 3, 4, 5, 6, 7});
    cubit.close();
  });

  blocTest<BulkEditCubit, BulkEditState>(
    'initPartitions elige la primera modalidad activa con sus canchas activas',
    build: build,
    act: (cubit) => cubit.initPartitions([inactive, padel]),
    verify: (cubit) {
      expect(cubit.state.clubPartitionIds, {1});
      expect(cubit.state.physicalIds, {10, 11});
    },
  );

  blocTest<BulkEditCubit, BulkEditState>(
    'no deja elegir modalidades ni canchas inactivas',
    build: build,
    act: (cubit) {
      cubit.toggleClubPartition(inactive);
      cubit.toggleCourt(court(12, active: false));
    },
    expect: () => const <BulkEditState>[],
  );

  blocTest<BulkEditCubit, BulkEditState>(
    '"Esta semana" va de hoy al domingo de esta semana',
    build: () => BulkEditCubit(repository, now: () => DateTime(2026, 10, 7)),
    act: (cubit) => cubit.setPreset(BulkPeriodPreset.thisWeek),
    verify: (cubit) {
      expect(cubit.state.from, DateTime(2026, 10, 7));
      expect(cubit.state.to, DateTime(2026, 10, 11));
    },
  );

  blocTest<BulkEditCubit, BulkEditState>(
    'precio fijo sin precio no pide vista previa; al completarlo sí (con debounce)',
    build: build,
    act: (cubit) async {
      cubit.initPartitions([padel]);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      cubit.setFixedPrice(12000);
      await Future<void>.delayed(const Duration(milliseconds: 450));
    },
    verify: (cubit) {
      final captured = verify(() => repository.preview(
            any(),
            captureAny(),
            view: any(named: 'view'),
            limit: any(named: 'limit'),
          )).captured;
      expect(captured, hasLength(1));
      final action = captured.single as BulkSessionAction;
      expect(action.type, BulkActionType.priceFixed);
      expect(action.price, 12000);
      expect(cubit.state.preview, preview);
      expect(cubit.state.canApply, isTrue);
    },
  );

  blocTest<BulkEditCubit, BulkEditState>(
    'eliminar se puede previsualizar sin parámetros y aplica con el resultado del backend',
    build: build,
    setUp: () {
      when(() => repository.apply(any(), any())).thenAnswer(
        (_) async => const Right(BulkApplyResult(affected: 2, excluded: BulkExcluded(booked: 1))),
      );
    },
    act: (cubit) async {
      cubit.initPartitions([padel]);
      cubit.setActionKind(BulkActionKind.delete);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      final result = await cubit.apply();
      expect(result?.affected, 2);
    },
    verify: (_) {
      final action = verify(() => repository.apply(any(), captureAny())).captured.single as BulkSessionAction;
      expect(action.type, BulkActionType.delete);
    },
  );

  blocTest<BulkEditCubit, BulkEditState>(
    'un error al aplicar queda en previewError y no devuelve resultado',
    build: build,
    setUp: () {
      when(() => repository.apply(any(), any()))
          .thenAnswer((_) async => Left(DomainError(message: 'Sin conexión', internalCode: 0, date: now)));
    },
    act: (cubit) async {
      cubit.initPartitions([padel]);
      cubit.setActionKind(BulkActionKind.delete);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      expect(await cubit.apply(), isNull);
    },
    verify: (cubit) => expect(cubit.state.previewError, 'Sin conexión'),
  );
}
