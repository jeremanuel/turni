import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/config/router/app_routes.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/services/realtime/realtime_service.dart';
import 'package:turni/main.dart' as app;

/// Flujo e2e de anular cobros, contra el backend y la DB locales reales: anula
/// un cobro desde Pagos y, en el panel del turno, comprueba que un turno
/// cobrado no se elimina hasta anular el cobro. Lo comparten los dos runners:
///   - `integration_test/void_payment_flow_test.dart`: Chrome real.
///   - `test/e2e/void_payment_flow_test.dart`: VM de Dart.
///
/// Requiere `npm run seed:e2e` en turni_mono_be. Los valores salen de su salida:
///   --dart-define=DEV_ADMIN_TOKEN=$adminToken
///   --dart-define=E2E_VOID_SESSION_ID=$voidPanelSessionId
const devAdminToken = String.fromEnvironment('DEV_ADMIN_TOKEN');
const voidSessionId = int.fromEnvironment('E2E_VOID_SESSION_ID');

const _hasPaymentsMessage = 'Este turno tiene cobros';

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

/// Elige el motivo y confirma en el diálogo ya abierto.
Future<void> _confirmVoid(WidgetTester tester) async {
  final confirm = _inDialog(find.widgetWithText(FilledButton, 'Anular cobro'));
  expect(tester.widget<FilledButton>(confirm).onPressed, isNull, reason: 'Sin motivo no se puede anular');

  await tester.tap(_inDialog(find.text('Error de carga')));
  await _settle(tester);
  expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

  await tester.tap(confirm);
  await _wait(tester, () => !_visible(find.byType(AlertDialog)), 'que se cierre el diálogo');
  await _settle(tester);
}

Future<void> _tapDeleteSession(WidgetTester tester) async {
  // Los avisos de superposición de la agenda (turnos del seed) tapan el pie del panel.
  ScaffoldMessenger.of(tester.element(find.text('Eliminar turno'))).clearSnackBars();
  await _settle(tester);
  await tester.tap(find.text('Eliminar turno'));
  await _wait(tester, () => _visible(find.byType(AlertDialog)), 'la confirmación de eliminar');
  await _settle(tester);
  await tester.tap(_inDialog(find.widgetWithText(TextButton, 'Eliminar')));
}

Future<void> runVoidPaymentFlow(WidgetTester tester) async {
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
  expect(voidSessionId, isNonZero, reason: 'Corré con --dart-define=E2E_VOID_SESSION_ID=<voidPanelSessionId>');

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

  // 1. Desde Pagos, el cobro queda tachado y con la etiqueta "Anulado".
  router!.go(AppRoutes.PAYMENTS_LIST.path);
  await _wait(tester, () => _visible(find.textContaining('7.350')), 'el cobro en Pagos');
  await _settle(tester);
  expect(find.text('Anulado'), findsNothing);

  await tester.tap(find.byTooltip('Acciones').first);
  await _wait(tester, () => _visible(find.text('Anular cobro')), 'el menú del cobro');
  await _settle(tester);
  await tester.tap(find.text('Anular cobro'));
  await _wait(tester, () => _visible(find.byType(AlertDialog)), 'el diálogo de anular');
  await _settle(tester);
  expect(_inDialog(find.textContaining('7.350')), findsOneWidget, reason: 'Tiene que abrir el cobro de arriba de la lista');

  await _confirmVoid(tester);
  await _wait(tester, () => _visible(find.text('Anulado')), 'la etiqueta Anulado');
  final amount = tester.widget<Text>(find.textContaining('7.350').first);
  expect(amount.style?.decoration, TextDecoration.lineThrough);

  // 2. Un turno cobrado no se elimina: avisa y sigue abierto.
  router!.goNamed(AppRoutes.SESSION_MANAGER_RESERVE_ROUTE.name, pathParameters: {'idSession': '$voidSessionId'});
  await _wait(tester, () => _visible(find.text('Eliminar turno')), 'el panel del turno');
  await _wait(tester, () => _visible(find.byTooltip('Anular cobro')), 'el cobro en el panel');
  await _settle(tester);

  await _tapDeleteSession(tester);
  await _wait(tester, () => _visible(find.textContaining(_hasPaymentsMessage)), 'el aviso de que tiene cobros');
  await _wait(tester, () => !_visible(find.byType(AlertDialog)), 'que se cierre la confirmación');
  await _settle(tester);
  expect(find.text('Eliminar turno'), findsOneWidget, reason: 'El panel sigue abierto');
  ScaffoldMessenger.of(tester.element(find.textContaining(_hasPaymentsMessage))).hideCurrentSnackBar();
  await _settle(tester);

  // 3. Con el cobro anulado desde el panel, el turno ya se puede eliminar.
  await tester.tap(find.byTooltip('Anular cobro'));
  await _wait(tester, () => _visible(find.byType(AlertDialog)), 'el diálogo de anular en el panel');
  await _settle(tester);
  await _confirmVoid(tester);
  await _wait(tester, () => !_visible(find.byTooltip('Anular cobro')), 'que el cobro salga del panel');

  await _tapDeleteSession(tester);
  await _wait(
    tester,
    () => router!.routerDelegate.currentConfiguration.uri.path == AppRoutes.SESSION_MANAGER_ROUTE.path,
    'volver a la agenda con el turno eliminado',
  );
  expect(find.textContaining(_hasPaymentsMessage), findsNothing);
  await _settle(tester);
}
