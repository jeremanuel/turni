import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:turni/core/config/app_theme.dart';
import 'package:turni/core/utils/domain_error.dart';
import 'package:turni/core/utils/either.dart';
import 'package:turni/core/utils/repository_response.dart';
import 'package:turni/domain/entities/notification_history.dart';
import 'package:turni/domain/repositories/notification_history_repository.dart';
import 'package:turni/presentation/admin/client_page/widgets/client_notifications_card.dart';
import 'package:turni/presentation/admin/notifications/notification_history_list.dart';
import 'package:turni/presentation/admin/notifications/session_notifications_section.dart';

final _now = DateTime(2026, 10, 24, 18, 30);

Map<String, dynamic> _delivery(String status, {int targets = 1, int succeeded = 1, String? error, String? next}) => {
      'channel': 'PUSH',
      'status': status,
      'attempts': 1,
      'targets': targets,
      'succeeded': succeeded,
      'last_error': error,
      'sent_at': null,
      'next_attempt_at': next,
      'updated_at': '2026-10-24T20:00:00.000Z',
    };

NotificationHistoryEntry _entry(
  int id, {
  String title = 'Turno confirmado',
  String app = 'CLIENT',
  String? name = 'Ana Pérez',
  int? clientId = 7,
  List<Map<String, dynamic>>? deliveries,
  String? readAt,
}) =>
    NotificationHistoryEntry.fromJson({
      'notification_id': '$id',
      'type': 'SESSION_ACCEPTED',
      'category': 'SESSION',
      'title': title,
      'body': 'Tu solicitud de turno fue aceptada.',
      'session_id': 48,
      'tournament_id': null,
      'recipient': {'user_id': 42, 'client_id': clientId, 'name': name, 'app': app},
      'read_at': readAt,
      'created_at': '2026-10-24T20:00:00.000Z',
      'deliveries': deliveries ?? [_delivery('SENT')],
    });

class _FakeRepository implements NotificationHistoryRepository {
  _FakeRepository({this.session = const [], this.client = const [], this.hasAppAccount = true, this.fail = false});

  final List<NotificationHistoryEntry> session;
  final List<NotificationHistoryEntry> client;
  final int pageSize = 2;
  final bool hasAppAccount;
  final bool fail;
  int sessionCalls = 0;
  final List<String?> cursors = [];

  @override
  Future<RepositoryResponse<List<NotificationHistoryEntry>>> getSessionNotifications(int sessionId) async {
    sessionCalls++;
    if (fail) return Either.left(DomainError(message: 'No se pudo cargar', internalCode: 1100, date: _now));
    return Either.right(session);
  }

  @override
  Future<RepositoryResponse<ClientNotificationsPage>> getClientNotifications(int clientId, {String? cursor}) async {
    cursors.add(cursor);
    if (!hasAppAccount) return const Either.right(ClientNotificationsPage(hasAppAccount: false, notifications: []));
    final start = cursor == null ? 0 : client.indexWhere((n) => n.id == cursor) + 1;
    final page = client.skip(start).take(pageSize).toList();
    final more = start + pageSize < client.length;
    return Either.right(ClientNotificationsPage(hasAppAccount: true, notifications: page, nextCursor: more ? page.last.id : null));
  }
}

Future<void> _pump(WidgetTester tester, Widget child, {double width = 1200}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child))),
    GoRoute(
      name: 'SESSION_MANAGER_RESERVE',
      path: '/session_manager/reserve/:idSession',
      builder: (_, state) => Text('turno ${state.pathParameters['idSession']}'),
    ),
    GoRoute(name: 'CLIENT', path: '/client/:clientId', builder: (_, state) => Text('ficha ${state.pathParameters['clientId']}')),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('deliverySummaries', () {
    String label(Map<String, dynamic> delivery) => deliverySummaries(_entry(1, deliveries: [delivery]), _now).single.label;

    test('cómo salió cada entrega', () {
      expect(label(_delivery('SENT')), 'Entregado');
      expect(label(_delivery('SENT', targets: 2, succeeded: 2)), 'Entregado en 2 dispositivos');
      expect(label(_delivery('PARTIAL', targets: 3)), 'Entregado en 1 de 3 dispositivos');
      expect(label(_delivery('SKIPPED', targets: 0, succeeded: 0)), 'Sin dispositivos con la app');
      expect(label(_delivery('PENDING')), 'Enviando…');
      expect(label(_delivery('FAILED', error: 'messaging/internal')), 'No salió el push');
    });

    test('un fallo con reintento dice cuándo, sin confundirlo con algo que ya pasó', () {
      final local = DateTime(2026, 10, 24, 21, 15);
      expect(label(_delivery('FAILED', next: local.toUtc().toIso8601String())), 'No salió el push · reintenta a las 21:15');
      expect(retryTimeLabel(DateTime(2026, 10, 25, 9, 5), _now), 'mañana a las 09:05');
      expect(retryTimeLabel(DateTime(2026, 10, 28, 9, 5), _now), 'el 28/10 a las 09:05');
      final past = DateTime(2026, 10, 24, 18).toUtc().toIso8601String();
      expect(label(_delivery('FAILED', next: past)), 'No salió el push · reintento pendiente');
    });

    test('el motivo técnico queda para el tooltip', () {
      final summary = deliverySummaries(_entry(1, deliveries: [_delivery('FAILED', error: 'messaging/mismatched-credential')]), _now).single;
      expect(summary.detail, 'messaging/mismatched-credential');
      expect(summary.tone, DeliveryTone.error);
    });

    test('sin entregas (ya se borraron) lo dice', () {
      expect(deliverySummaries(_entry(1, deliveries: []), _now).single.label, 'Sin datos de entrega');
    });
  });

  test('fromJson lee el destinatario y las entregas', () {
    final entry = _entry(5, app: 'ADMIN', clientId: null, name: 'Dev Admin', readAt: '2026-10-24T21:00:00.000Z');
    expect(entry.id, '5');
    expect(entry.isForAdmin, isTrue);
    expect(entry.recipientClientId, isNull);
    expect(entry.readAt, isNotNull);
    expect(entry.deliveries.single.status, DeliveryStatus.sent);
  });

  group('SessionNotificationsSection', () {
    testWidgets('arranca cerrada, carga al abrirla y muestra a quién fue cada aviso', (tester) async {
      final repo = _FakeRepository(session: [
        _entry(2),
        _entry(1, title: 'Seña acreditada', app: 'ADMIN', clientId: null, name: 'Dev Admin'),
      ]);
      await _pump(tester, SessionNotificationsSection(sessionId: 48, repository: repo));
      expect(repo.sessionCalls, 0);

      await tester.tap(find.text('Avisos'));
      await tester.pumpAndSettle();

      expect(repo.sessionCalls, 1);
      expect(find.text('Turno confirmado'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text(' · app de administración'), findsOneWidget);

      await tester.tap(find.text('Ana Pérez'));
      await tester.pumpAndSettle();
      expect(find.text('ficha 7'), findsOneWidget);
    });

    testWidgets('sin avisos lo dice', (tester) async {
      await _pump(tester, SessionNotificationsSection(sessionId: 48, repository: _FakeRepository()));
      await tester.tap(find.text('Avisos'));
      await tester.pumpAndSettle();
      expect(find.text('No salió ningún aviso por este turno.'), findsOneWidget);
    });

    testWidgets('un error muestra el mensaje y Reintentar', (tester) async {
      final repo = _FakeRepository(fail: true);
      await _pump(tester, SessionNotificationsSection(sessionId: 48, repository: repo));
      await tester.tap(find.text('Avisos'));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo cargar'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(repo.sessionCalls, 2);
    });
  });

  group('ClientNotificationsCard', () {
    testWidgets('pagina con Ver más y abre el turno del aviso', (tester) async {
      final repo = _FakeRepository(client: [_entry(3), _entry(2), _entry(1)]);
      await _pump(tester, ClientNotificationsCard(clientId: 7, repository: repo));

      expect(find.text('Turno confirmado'), findsNWidgets(2));
      await tester.tap(find.text('Ver más'));
      await tester.pumpAndSettle();
      expect(find.text('Turno confirmado'), findsNWidgets(3));
      expect(repo.cursors, [null, '2']);
      expect(find.text('Ver más'), findsNothing);

      await tester.tap(find.text('Ver turno').first);
      await tester.pumpAndSettle();
      expect(find.text('turno 48'), findsOneWidget);
    });

    testWidgets('un cliente sin cuenta en la app', (tester) async {
      await _pump(tester, ClientNotificationsCard(clientId: 7, repository: _FakeRepository(hasAppAccount: false)));
      expect(find.text('No tiene cuenta en la app: los avisos no le llegan.'), findsOneWidget);
    });

    testWidgets('a 360 px no desborda', (tester) async {
      final long = _entry(
        1,
        title: 'Recordatorio del partido de la final de la Copa Primavera Mixta Categoría Libre',
        deliveries: [_delivery('FAILED', error: 'x', next: DateTime(2026, 10, 30, 9).toUtc().toIso8601String())],
        readAt: '2026-10-24T21:00:00.000Z',
      );
      await _pump(tester, ClientNotificationsCard(clientId: 7, repository: _FakeRepository(client: [long])), width: 360);
      expect(tester.takeException(), isNull);
    });
  });
}
