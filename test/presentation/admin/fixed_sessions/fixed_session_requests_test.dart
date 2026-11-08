import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/utils/domain_error.dart';
import 'package:turni/core/utils/either.dart';
import 'package:turni/core/utils/permissions.dart';
import 'package:turni/core/utils/repository_response.dart';
import 'package:turni/domain/entities/fixed_session.dart';
import 'package:turni/domain/entities/session_request_settings.dart';
import 'package:turni/domain/repositories/admin_repository.dart';
import 'package:turni/domain/repositories/fixed_session_repository.dart';
import 'package:turni/presentation/admin/club_config/tabs/session_request_settings_tab.dart';
import 'package:turni/presentation/admin/fixed_sessions/widgets/fixed_session_requests_panel.dart';
import 'package:turni/presentation/admin/fixed_sessions/widgets/fixed_session_texts.dart';
import 'package:turni/presentation/admin/notifications/notifications_cubit.dart';

import '../../../helpers/logged_admin.dart';

Map<String, dynamic> _requestJson({int id = 7, String name = 'Ana'}) => {
      'fixed_session_request_id': id,
      'status': 'PENDING',
      'created_at': '2026-11-06T20:00:00.000Z',
      'resolved_at': null,
      'client': {'client_id': 3, 'name': name, 'last_name': 'López'},
      'club_id': 1,
      'club_name': 'Sierra Alta',
      'club_partition_id': 2,
      'sport': 'Pádel',
      'partition_physical_id': 9,
      'court_name': 'Cancha 2',
      'day_of_week': 6,
      'start_time': '20:00',
      'duration': 90,
      'plays': 5,
      'client_subscription_id': null,
    };

FixedSessionOccurrence _day(String date, FixedSessionOccurrenceStatus status) =>
    FixedSessionOccurrence(date: date, status: status);

class _FakeRepository extends Fake implements FixedSessionRepository {
  _FakeRepository(this.pending);

  List<FixedSessionRequest> pending;
  RepositoryResponse<FixedSessionCreated>? acceptResult;
  final accepted = <int>[];
  final rejected = <int>[];

  @override
  Future<RepositoryResponse<List<FixedSessionRequest>>> pendingRequests() async => Either.right(pending);

  @override
  Future<RepositoryResponse<List<FixedSessionOccurrence>>> preview(FixedSessionDraft draft) async => Either.right([
        _day('2026-11-14', FixedSessionOccurrenceStatus.created),
        _day('2026-11-21', FixedSessionOccurrenceStatus.freeSession),
      ]);

  @override
  Future<RepositoryResponse<FixedSessionCreated>> acceptRequest(int id) async {
    final result = acceptResult;
    if (result != null) return result;
    accepted.add(id);
    pending = pending.where((r) => r.id != id).toList();
    return Either.right(FixedSessionCreated.fromJson({
      'fixed_session': {
        'client_subscription_id': 1,
        'client': {'client_id': 3, 'name': 'Ana', 'last_name': 'López'},
        'partition_physical_id': 9,
        'court_name': 'Cancha 2',
        'club_partition_id': 2,
        'day_of_week': 6,
        'start_time': '20:00',
        'duration': 90,
        'start_date': '2026-11-14',
      },
      'generation': {'created': 8, 'assigned': 0, 'conflicts': []},
    }));
  }

  @override
  Future<RepositoryResponse<void>> rejectRequest(int id) async {
    rejected.add(id);
    pending = pending.where((r) => r.id != id).toList();
    return const Either.right(null);
  }
}

class _FakeAdminRepository extends Fake implements AdminRepository {
  _FakeAdminRepository(this.settings);

  SessionRequestSettings settings;
  SessionRequestSettings? saved;

  @override
  Future<Either<DomainError, SessionRequestSettings>> getSessionRequestSettings() async => Either.right(settings);

  @override
  Future<Either<DomainError, SessionRequestSettings>> updateSessionRequestSettings(SessionRequestSettings value) async {
    saved = value;
    return Either.right(value);
  }
}

Future<_FakeAdminRepository> _openSettings(WidgetTester tester, SessionRequestSettings settings) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = _FakeAdminRepository(settings);
  if (sl.isRegistered<AdminRepository>()) sl.unregister<AdminRepository>();
  sl.registerSingleton<AdminRepository>(repository);
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SessionRequestSettingsTab())));
  await tester.pumpAndSettle();
  return repository;
}

_FakeRepository _useRepository(List<Map<String, dynamic>> requests) {
  final repository = _FakeRepository(requests.map(FixedSessionRequest.fromJson).toList());
  if (sl.isRegistered<FixedSessionRepository>()) sl.unregister<FixedSessionRepository>();
  sl.registerSingleton<FixedSessionRepository>(repository);
  return repository;
}

Future<void> _openPanel(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => openFixedSessionRequests(context),
          child: const Text('abrir'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  setUp(registerLoggedAdmin);

  test('un aviso de pedido lleva a la pestaña de turnos fijos', () {
    expect(adminNotificationLocation({'fixed_session_request_id': '7'}), '/bulk_sessions?tab=fixed');
  });

  test('el pedido arma el mismo borrador que la carga manual', () {
    final draft = FixedSessionRequest.fromJson(_requestJson()).draft.toJson();
    expect(draft['client_id'], 3);
    expect(draft['partition_physical_id'], 9);
    expect(draft['day_of_week'], 6);
    expect(draft['start_time'], '20:00');
    expect(draft['duration'], 90);
  });

  test('la vista previa nombra los días en plural y los ocupados', () {
    final free = [_day('2026-11-14', FixedSessionOccurrenceStatus.created), _day('2026-11-21', FixedSessionOccurrenceStatus.created)];
    expect(FixedSessionTexts.previewSummary(free, 'sábado'), 'Los 2 sábados están libres.');
    expect(FixedSessionTexts.previewSummary(free, 'martes'), 'Los 2 martes están libres.');

    final busy = [...free, _day('2026-11-28', FixedSessionOccurrenceStatus.booked)];
    final text = FixedSessionTexts.previewSummary(busy, 'sábado');
    expect(text, startsWith('2 de 3 sábados disponibles.'));
    expect(text, endsWith('ya está ocupado: esos días no se tocan.'));
  });

  test('sin pedidos, la configuración viaja en null para apagarlos', () {
    const settings = SessionRequestSettings(ttlMinutes: 30);
    expect(settings.toJson(), containsPair('fixed_session_request_min_plays', null));
    expect(
      SessionRequestSettings.fromJson({'pending_request_ttl_minutes': 30, 'fixed_session_request_min_plays': 4}).fixedRequestMinPlays,
      4,
    );
  });

  testWidgets('muestra el pedido con las semanas libres y, al aceptar el último, se cierra', (tester) async {
    final repository = _useRepository([_requestJson()]);
    await _openPanel(tester);

    expect(find.text('Ana López'), findsOneWidget);
    expect(find.text('Sábado 20:00 · 90 min'), findsOneWidget);
    expect(find.text('Vino 5 veces a este horario'), findsOneWidget);
    expect(find.text('Los 2 sábados están libres.'), findsOneWidget);

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(repository.accepted, [7]);
    expect(find.text('Pedidos de turno fijo'), findsNothing);
  });

  testWidgets('rechazar pide confirmación', (tester) async {
    final repository = _useRepository([_requestJson(), _requestJson(id: 8, name: 'Bruno')]);
    await _openPanel(tester);

    await tester.tap(find.text('Rechazar').first);
    await tester.pumpAndSettle();
    expect(repository.rejected, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Rechazar'));
    await tester.pumpAndSettle();

    expect(repository.rejected, [7]);
    expect(find.text('Ana López'), findsNothing);
    expect(find.text('Bruno López'), findsOneWidget);
  });

  testWidgets('si no se pudo aceptar, el pedido sigue con el motivo', (tester) async {
    final repository = _useRepository([_requestJson()]);
    repository.acceptResult = Either.left(DomainError.fromErrorResponse({'error': 'El horario ya está fijo con otro cliente.'}));
    await _openPanel(tester);

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(find.text('El horario ya está fijo con otro cliente.'), findsOneWidget);
    expect(find.text('Ana López'), findsOneWidget);
  });

  testWidgets('el club prende los pedidos con la cantidad de veces', (tester) async {
    final repository = await _openSettings(tester, const SessionRequestSettings(ttlMinutes: 30));
    expect(find.text('Veces que tiene que haber venido'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Veces que tiene que haber venido'), '53');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repository.saved, isNull);
    expect(find.text('Ingresá un número entero entre 1 y 52.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Veces que tiene que haber venido'), '6');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repository.saved?.ttlMinutes, 30);
    expect(repository.saved?.fixedRequestMinPlays, 6);
  });

  testWidgets('apagarlos guarda sin cantidad', (tester) async {
    final repository = await _openSettings(tester, const SessionRequestSettings(ttlMinutes: 30, fixedRequestMinPlays: 4));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repository.saved?.fixedRequestMinPlays, isNull);
  });

  testWidgets('quien solo puede ver no tiene las acciones', (tester) async {
    registerLoggedAdmin(permissions: const [Permissions.TURNOS_FIJOS_VER]);
    _useRepository([_requestJson()]);
    await _openPanel(tester);

    expect(find.text('Ana López'), findsOneWidget);
    expect(find.text('Aceptar'), findsNothing);
    expect(find.text('Rechazar'), findsNothing);
  });
}
