import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/config/environment.dart';
import 'package:turni/core/config/router/app_routes.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/services/realtime/realtime_service.dart';
import 'package:turni/main.dart' as app;

/// Flujo e2e de los pedidos de turno fijo, contra el backend y la DB locales
/// reales: los pedidos llegan solos por el canal en tiempo real y el admin
/// rechaza uno y acepta otro. Lo comparten los dos runners:
///   - `integration_test/fixed_requests_flow_test.dart`: Chrome real.
///   - `test/e2e/fixed_requests_flow_test.dart`: VM de Dart.
///
/// Requiere `npm run seed:e2e` en turni_mono_be, que deja los dos horarios
/// para pedir. Los tokens salen de su salida (`adminToken` y `habitualToken`):
///   --dart-define=DEV_ADMIN_TOKEN=$adminToken
///   --dart-define=E2E_CLIENT_TOKEN=$habitualToken
const devAdminToken = String.fromEnvironment('DEV_ADMIN_TOKEN');
const e2eClientToken = String.fromEnvironment('E2E_CLIENT_TOKEN');

const _pendingBanner = 'por revisar';
const _panelTitle = 'Pedidos de turno fijo';

Future<void> _wait(
  WidgetTester tester,
  bool Function() done,
  String what, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('Timeout esperando $what');
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Deja terminar las transiciones. Sin `pumpAndSettle`: la app real siempre
/// tiene alguna animación en curso.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 150)));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

bool _visible(Finder finder) => finder.evaluate().isNotEmpty;

Future<void> runFixedRequestsFlow(WidgetTester tester) async {
  expect(devAdminToken, isNotEmpty, reason: 'Corré con --dart-define=DEV_ADMIN_TOKEN=<adminToken>');
  expect(e2eClientToken, isNotEmpty, reason: 'Corré con --dart-define=E2E_CLIENT_TOKEN=<habitualToken>');

  app.main();

  GoRouter? router;
  await _wait(tester, () {
    try {
      router ??= sl<GoRouter>();
    } catch (_) {}
    return router != null;
  }, 'el router');
  await _settle(tester);
  await _wait(tester, () => RealtimeService.instance.isConnected, 'el canal en tiempo real');

  router!.push('${AppRoutes.BULK_SESSIONS_ROUTE.path}?tab=fixed');
  await _wait(tester, () => _visible(find.text('Nuevo turno fijo')), 'la pestaña de turnos fijos');
  await _settle(tester);
  expect(find.textContaining(_pendingBanner), findsNothing, reason: 'El seed no deja pedidos pendientes');

  final client = Dio(BaseOptions(
    baseUrl: Environment.apiUrl,
    contentType: 'application/json',
    headers: {'Authorization': 'Bearer $e2eClientToken'},
  ));
  Future<List<dynamic>> options() async {
    final response = await tester.runAsync(() => client.get('/session/fixed/request-options'));
    return response!.data as List<dynamic>;
  }

  Future<void> requestAt(List<dynamic> all, String time) async {
    final option = all.firstWhere((o) => o['start_time'] == time);
    await tester.runAsync(() => client.post('/session/fixed/requests', data: {'session_id': option['session_id']}));
  }

  // 1. Los pedidos del cliente aparecen solos, sin recargar.
  final all = await options();
  await requestAt(all, '10:00');
  await _wait(tester, () => _visible(find.text('1 pedido de turno fijo $_pendingBanner')), 'el primer pedido sin recargar');
  await requestAt(all, '11:30');
  await _wait(tester, () => _visible(find.text('2 pedidos de turno fijo $_pendingBanner')), 'el segundo pedido sin recargar');

  // 2. El panel muestra los dos, del más viejo al más nuevo.
  await tester.tap(find.widgetWithText(FilledButton, 'Revisar'));
  await _wait(tester, () => _visible(find.text(_panelTitle)), 'el panel de pedidos');
  final rejectButtons = find.widgetWithText(TextButton, 'Rechazar');
  await _wait(tester, () => rejectButtons.evaluate().length == 2, 'los dos pedidos en el panel');
  await _settle(tester);

  // 3. Rechazar pide confirmación y deja el otro pedido.
  await tester.tap(rejectButtons.first);
  await _wait(tester, () => _visible(find.text('¿Rechazar el pedido?')), 'la confirmación');
  await _settle(tester);
  await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Rechazar')));
  await _wait(tester, () => rejectButtons.evaluate().length == 1, 'que quede un pedido');
  await _settle(tester);

  // 4. Al aceptar el último, el panel se cierra y el banner desaparece.
  await tester.tap(find.widgetWithText(FilledButton, 'Aceptar'));
  await _wait(tester, () {
    final conflicts = find.widgetWithText(FilledButton, 'Entendido');
    if (_visible(conflicts)) tester.tap(conflicts);
    return !_visible(find.text(_panelTitle));
  }, 'que se cierre el panel');
  await _wait(tester, () => !_visible(find.textContaining(_pendingBanner)), 'que desaparezca el banner');

  // 5. Quedó lo que el admin decidió.
  final after = await options();
  expect(after.firstWhere((o) => o['start_time'] == '10:00')['request']['status'], 'REJECTED');
  expect(after.where((o) => o['start_time'] == '11:30'), isEmpty, reason: 'El aceptado ya es un turno fijo');
  final mine = await tester.runAsync(() => client.get('/session/fixed/mine'));
  expect((mine!.data as List).where((f) => f['start_time'] == '11:30'), hasLength(1));

  // Deja vencer el timer del SnackBar antes de desmontar.
  await tester.pump(const Duration(seconds: 5));
  await _settle(tester);
}
