import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:turni/core/utils/either.dart';
import 'package:turni/core/utils/repository_response.dart';
import 'package:turni/domain/entities/bulk_sessions.dart';
import 'package:turni/domain/entities/club_partition.dart';
import 'package:turni/domain/entities/club_type.dart';
import 'package:turni/domain/entities/physical_partition.dart';
import 'package:turni/domain/repositories/bulk_session_repository.dart';
import 'package:turni/presentation/admin/bulk_sessions/bulk_edit_tab.dart';
import 'package:turni/presentation/admin/session_manager_screen/bloc/session_manager_bloc.dart';
import 'package:turni/presentation/admin/session_manager_screen/bloc/session_manager_event.dart';
import 'package:turni/presentation/admin/session_manager_screen/bloc/session_manager_state.dart';

class _MockSessionManagerBloc extends MockBloc<SessionManagerEvent, SessionManagerState>
    implements SessionManagerBloc {}

class _FakeRepository implements BulkSessionRepository {
  final List<BulkSessionAction> previews = [];

  @override
  Future<RepositoryResponse<BulkPreview>> preview(
    BulkSessionFilters filters,
    BulkSessionAction action, {
    BulkPreviewView view = BulkPreviewView.all,
    int? limit,
  }) async {
    previews.add(action);
    return Right(BulkPreview(
      matched: 96,
      affected: 84,
      excluded: const BulkExcluded(booked: 9, pending: 3),
      totalRows: 96,
      rows: [
        BulkPreviewRow(
          sessionId: 1,
          partitionPhysicalId: 10,
          startTime: DateTime(2026, 10, 5, 18),
          duration: 60,
          price: 10000,
          newPrice: action.type == BulkActionType.priceTariff ? 12500 : null,
          result: BulkRowResult.ok,
        ),
        BulkPreviewRow(
          sessionId: 2,
          partitionPhysicalId: 10,
          startTime: DateTime(2026, 10, 5, 19),
          duration: 60,
          price: 10000,
          result: BulkRowResult.booked,
        ),
      ],
    ));
  }

  @override
  Future<RepositoryResponse<BulkApplyResult>> apply(BulkSessionFilters filters, BulkSessionAction action) async =>
      const Right(BulkApplyResult(affected: 84, excluded: BulkExcluded(booked: 9, pending: 3)));
}

void main() {
  late _MockSessionManagerBloc managerBloc;
  late _FakeRepository repository;

  final padel = ClubPartition(
    club_partition_id: 1,
    club_id: 1,
    club_type_id: 1,
    clubType: ClubType(clubTypeId: 1, name: 'Pádel'),
    physicalPartitionName: 'Cancha',
    physicalPartitions: [
      PhysicalPartition(
        partitionPhysicalId: 10,
        clubPartitionId: 1,
        minPlayers: 2,
        maxPlayers: 4,
        physicalIdentifier: 1,
        isCover: '0',
        description: null,
      ),
    ],
  );
  final tenis = ClubPartition(
    club_partition_id: 2,
    club_id: 1,
    club_type_id: 2,
    clubType: ClubType(clubTypeId: 2, name: 'Tenis'),
    active: false,
  );

  setUp(() {
    managerBloc = _MockSessionManagerBloc();
    repository = _FakeRepository();
    when(() => managerBloc.state).thenReturn(SessionManagerState(
      currentDate: DateTime(2026, 10, 4),
      sessions: const [],
      clubPartitions: [padel, tenis],
    ));
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff672bea), brightness: Brightness.dark),
      ),
      home: Scaffold(
        body: BlocProvider<SessionManagerBloc>.value(
          value: managerBloc,
          child: BulkEditTab(repository: repository),
        ),
      ),
    ));
  }

  Future<void> waitPreview(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
  }

  testWidgets('muestra reglas, acción y vista previa con los totales del backend', (tester) async {
    await pump(tester);

    expect(find.text('1. ¿Qué turnos?'), findsOneWidget);
    expect(find.text('2. ¿Qué hacer con ellos?'), findsOneWidget);
    expect(find.text('3. Vista previa'), findsOneWidget);
    expect(find.text('Pádel'), findsOneWidget);
    expect(find.text('Tenis'), findsOneWidget);

    // Precio fijo vacío: todavía no se pide vista previa.
    expect(find.text('Completá el precio nuevo para ver la vista previa.'), findsOneWidget);

    await tester.tap(find.text('Recalcular por tarifa'));
    await waitPreview(tester);

    expect(repository.previews.last.type, BulkActionType.priceTariff);
    expect(find.text('Se modifica'), findsOneWidget);
    expect(find.text('Reservado · excluido'), findsOneWidget);
    expect(find.text('Lun 05/10'), findsNWidgets(2));
    expect(find.text('Pádel · Cancha 1'), findsNWidgets(2));
    expect(find.text('Se van a modificar 84 turnos. 12 quedan como están.'), findsOneWidget);
    expect(find.text('Aplicar a 84 turnos'), findsOneWidget);
  });

  testWidgets('eliminar pide confirmación explícita antes de borrar', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Eliminar'));
    await waitPreview(tester);

    expect(find.text('Se elimina'), findsOneWidget);
    await tester.tap(find.text('Eliminar 84 turnos'));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar 84 turnos?'), findsOneWidget);
    expect(find.text('Lunes a viernes'), findsNothing);
    expect(find.text('Todos los días'), findsOneWidget);
    final confirm = find.widgetWithText(FilledButton, 'Eliminar 84 turnos').last;
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.text('Turnos eliminados'), findsOneWidget);
    expect(find.text('Reservados por un cliente'), findsOneWidget);
    expect(find.text('Solicitud pendiente de aprobación'), findsOneWidget);
  });
}
