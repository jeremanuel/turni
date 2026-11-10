import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/config/router/app_routes.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/services/realtime/realtime_service.dart';
import 'package:turni/main.dart' as app;

/// Flujo e2e de devolver un cobro de Mercado Pago, contra el backend y la DB
/// locales reales: desde el panel del turno devuelve una parte y después el
/// resto, lo ve como "Devuelto" en Pagos y en la Conciliación de Caja. Lo
/// comparten los dos runners:
///   - `integration_test/refund_payment_flow_test.dart`: Chrome real.
///   - `test/e2e/refund_payment_flow_test.dart`: VM de Dart.
///
/// Requiere el backend con PAYMENT_PROVIDER_MOCK=true (la devolución la hace
/// el mock, sin red) y `npm run seed:e2e` en turni_mono_be. Los valores salen
/// de su salida:
///   --dart-define=DEV_ADMIN_TOKEN=$adminToken
///   --dart-define=E2E_REFUND_SESSION_ID=$refundSessionId
const devAdminToken = String.fromEnvironment('DEV_ADMIN_TOKEN');
const refundSessionId = int.fromEnvironment('E2E_REFUND_SESSION_ID');

Future<void> _wait(
  WidgetTester tester,
  bool Function() done,
  String what, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('Timeout esperando $what');
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Sin `pumpAndSettle`: la app real siempre tiene alguna animación en curso.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 150)));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

bool _visible(Finder finder) => finder.evaluate().isNotEmpty;

Finder _inDialog(Finder finder) => find.descendant(of: find.byType(AlertDialog), matching: finder);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _openRefundDialog(WidgetTester tester) async {
  // Los avisos de superposición de la agenda (turnos del seed) pueden tapar el panel.
  ScaffoldMessenger.of(tester.element(find.byTooltip('Devolver cobro'))).clearSnackBars();
  await _settle(tester);
  await _tap(tester, find.byTooltip('Devolver cobro'));
  await _wait(tester, () => _visible(_inDialog(find.text('Motivo'))), 'el diálogo de devolver');
  await _settle(tester);
}

Future<void> _confirm(WidgetTester tester, String label) async {
  final confirm = _inDialog(find.widgetWithText(FilledButton, label));
  await _wait(tester, () => _visible(confirm), 'el botón "$label"');
  await _tap(tester, confirm);
  await _wait(tester, () => !_visible(find.byType(AlertDialog)), 'que se cierre el diálogo');
  await _settle(tester);
}

Future<void> runRefundPaymentFlow(WidgetTester tester) async {
  final errors = <String>[];
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final where = RegExp(r'[\w/]+\.dart:\d+:\d+').firstMatch(details.toString())?.group(0);
    // Desborde conocido de la tabla de clientes, que queda montada en otra rama del shell.
    if (where != null && where.contains('clients_list_page.dart')) return;
    errors.add('${details.exceptionAsString().split('\n').first} @ $where');
  };
  try {
    await _runFlow(tester);
  } finally {
    FlutterError.onError = original;
  }
  expect(errors.toSet(), isEmpty, reason: 'Errores de Flutter durante el flujo');
}

Future<void> _runFlow(WidgetTester tester) async {
  expect(devAdminToken, isNotEmpty, reason: 'Corré con --dart-define=DEV_ADMIN_TOKEN=<adminToken>');
  expect(refundSessionId, isNonZero, reason: 'Corré con --dart-define=E2E_REFUND_SESSION_ID=<refundSessionId>');

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

  // 1. En el panel del turno, un cobro de Mercado Pago se devuelve (no se anula).
  router!.goNamed(AppRoutes.SESSION_MANAGER_RESERVE_ROUTE.name, pathParameters: {'idSession': '$refundSessionId'});
  await _wait(tester, () => _visible(find.byTooltip('Devolver cobro')), 'el cobro online en el panel');
  await _settle(tester);
  expect(find.byTooltip('Anular cobro'), findsNothing, reason: 'Un cobro online no se anula: se devuelve');

  // 2. Devuelve una parte: el cobro queda en el panel por lo que no se devolvió.
  await _openRefundDialog(tester);
  expect(_inDialog(find.text('Todo · \$ 6.400')), findsOneWidget);
  await _tap(tester, _inDialog(find.text('Una parte')));
  await tester.enterText(_inDialog(find.byType(TextFormField)).first, '2000');
  await _settle(tester);
  expect(tester.widget<FilledButton>(_inDialog(find.byType(FilledButton))).onPressed, isNull, reason: 'Sin motivo no se puede devolver');
  await _tap(tester, _inDialog(find.text('Lo pidió el cliente')));
  await _confirm(tester, 'Devolver \$ 2.000');
  await _wait(tester, () => _visible(find.textContaining('4.400')), 'el cobro neto en el panel');

  // 3. Devuelve el resto: el cobro sale del panel.
  await _openRefundDialog(tester);
  expect(_inDialog(find.text('Ya se devolvieron \$ 2.000')), findsOneWidget);
  expect(_inDialog(find.text('Todo · \$ 4.400')), findsOneWidget);
  await _tap(tester, _inDialog(find.text('Se suspendió el turno')));
  await _confirm(tester, 'Devolver \$ 4.400');
  await _wait(tester, () => !_visible(find.byTooltip('Devolver cobro')), 'que el cobro salga del panel');

  // 4. En Pagos queda tachado y "Devuelto".
  router!.go(AppRoutes.PAYMENTS_LIST.path);
  await _wait(tester, () => _visible(find.text('Devuelto')), 'la etiqueta Devuelto en Pagos');
  await _settle(tester);
  final amounts = tester.widgetList<Text>(find.textContaining('6.400')).toList();
  expect(amounts.any((t) => t.style?.decoration == TextDecoration.lineThrough), isTrue, reason: 'El cobro devuelto queda tachado');

  // 5. En Caja › Conciliación aparece el cobro, con lo devuelto.
  router!.go(AppRoutes.CASH_ROUTE.path);
  await _wait(tester, () => _visible(find.text('Conciliación')), 'la pestaña Conciliación');
  await _settle(tester);
  await _tap(tester, find.text('Conciliación'));
  await _wait(tester, () => _visible(find.text('Cobros con diferencias')), 'la conciliación');
  await _wait(tester, () => _visible(find.text('Cobrado')), 'la tabla de cobros');
  expect(find.textContaining('6.400'), findsWidgets);
  await _settle(tester);
}
