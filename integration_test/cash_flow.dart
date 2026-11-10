import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/config/router/app_routes.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/presentation/components/onboarding/tour_anchor.dart';
import 'package:turni/core/services/cash_status.dart';
import 'package:turni/core/services/realtime/realtime_service.dart';
import 'package:turni/main.dart' as app;
import 'package:turni/presentation/admin/payments_list/payments_list_page.dart';

/// Flujo e2e de la caja, contra el backend y la DB locales reales: prende la
/// caja, crea un puesto con un espacio, cobra un turno (que se frena hasta
/// abrir la caja), anula el cobro y cierra con diferencia. Al final apaga la
/// caja para no cambiarles el comportamiento a los demás e2e. Lo comparten:
///   - `integration_test/cash_flow_test.dart`: Chrome real.
///   - `test/e2e/cash_flow_test.dart`: VM de Dart.
///
/// Requiere `npm run seed:e2e` en turni_mono_be. Los valores salen de su salida:
///   --dart-define=DEV_ADMIN_TOKEN=$adminToken
///   --dart-define=E2E_CASH_SESSION_ID=$cashSessionId
///   --dart-define=E2E_CASH_SPACE_ID=$cashSpaceId
const devAdminToken = String.fromEnvironment('DEV_ADMIN_TOKEN');
const cashSessionId = int.fromEnvironment('E2E_CASH_SESSION_ID');
const cashSpaceId = int.fromEnvironment('E2E_CASH_SPACE_ID');

/// El monto del turno del seed, como se ve en pantalla.
const _sessionPrice = '6.400';

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

/// El menú cerrado muestra solo íconos: se busca el destino, no su texto.
final _cashMenu = find.byWidgetPredicate((widget) => widget is TourAnchor && widget.id == 'nav.caja');

Finder _inDialog(Finder finder) => find.descendant(of: find.byType(AlertDialog), matching: finder);

Future<void> _dialogClosed(WidgetTester tester, String what) async {
  await _wait(tester, () => !_visible(find.byType(AlertDialog)), what);
  await _settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _openConfigTab(WidgetTester tester, GoRouter router) async {
  router.go(AppRoutes.ADMIN_SETTINGS_ROUTE.path);
  await _wait(tester, () => _visible(find.text('Cajas')), 'la sección Cajas');
  await _settle(tester);
  await tester.tap(find.text('Cajas').first);
  await _wait(tester, () => _visible(find.byKey(const ValueKey('cash.config.enabled'))), 'la configuración de caja');
  await _settle(tester);
}

Future<void> _setCashEnabled(WidgetTester tester, bool enabled) async {
  // Con la pestaña ya usada, el interruptor puede haber quedado scrolleado.
  await _tap(tester, find.byKey(const ValueKey('cash.config.enabled')));
  await _tap(tester, find.byKey(const ValueKey('cash.config.save')));
  await _wait(tester, () => CashStatus.enabled.value == enabled, 'que se guarde la configuración');
  await _settle(tester);
}

Future<void> runCashFlow(WidgetTester tester) async {
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
  expect(cashSessionId, isNonZero, reason: 'Corré con --dart-define=E2E_CASH_SESSION_ID=<cashSessionId>');
  expect(cashSpaceId, isNonZero, reason: 'Corré con --dart-define=E2E_CASH_SPACE_ID=<cashSpaceId>');

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

  // El nombre cambia en cada corrida: la base de e2e acumula puestos.
  final pointName = 'Quincho ${DateTime.now().millisecondsSinceEpoch % 100000}';

  // 1. Prende la caja: aparece el menú y el puesto principal.
  await _openConfigTab(tester, router!);
  await _setCashEnabled(tester, true);
  await _wait(tester, () => _visible(_cashMenu), 'el menú Caja');

  // 2. Crea un puesto que gestiona el espacio del turno.
  await _tap(tester, find.byKey(const ValueKey('cash.config.newPoint')));
  await _wait(tester, () => _visible(find.byKey(const ValueKey('cash.point.name'))), 'el diálogo del puesto');
  await tester.enterText(find.byKey(const ValueKey('cash.point.name')), pointName);
  await _settle(tester);
  await _tap(tester, find.byKey(const ValueKey('cash.point.space.$cashSpaceId')));
  await _tap(tester, find.byKey(const ValueKey('cash.point.save')));
  await _dialogClosed(tester, 'que se guarde el puesto');
  await _wait(tester, () => _visible(find.text(pointName)), 'el puesto en la tabla');

  // 3. Con la caja cerrada, el efectivo no se cobra hasta abrirla.
  router!.goNamed(AppRoutes.SESSION_MANAGER_RESERVE_ROUTE.name, pathParameters: {'idSession': '$cashSessionId'});
  await _wait(tester, () => _visible(find.text('Cobrar')), 'el panel del turno');
  await _settle(tester);
  await tester.tap(find.text('Cobrar').first);
  await _wait(tester, () => _visible(find.byKey(const ValueKey('cash.entry.closed'))), 'el aviso de caja cerrada');
  await _settle(tester);
  expect(find.text('$pointName está cerrada'), findsOneWidget);

  await _tap(tester, find.text('Abrir $pointName'));
  await _wait(tester, () => _visible(find.byType(AlertDialog)), 'el diálogo de abrir caja');
  await tester.enterText(_inDialog(find.byType(TextFormField)), '1000');
  await _settle(tester);
  await _tap(tester, _inDialog(find.widgetWithText(FilledButton, 'Abrir caja')));
  await _dialogClosed(tester, 'que se abra la caja');

  // 4. Abierta, cobra y el pago entra en ese puesto.
  await _wait(tester, () => _visible(find.byKey(const ValueKey('cash.entry.title'))), 'la fila Entra en');
  expect(find.widgetWithText(Column, pointName), findsWidgets);
  await _tap(tester, find.textContaining('Cobrar \$'));
  await _wait(tester, () => !_visible(find.byKey(const ValueKey('cash.entry.title'))), 'volver al panel después de cobrar');
  await _settle(tester);

  // 5. En Pagos se ve la caja y, anulado, el cobro sale de ella.
  router!.go(AppRoutes.PAYMENTS_LIST.path);
  // El panel del turno sigue montado en su rama: se busca dentro de Pagos.
  final payments = find.byType(PaymentsRegisteredView);
  await _wait(tester, () => _visible(find.descendant(of: payments, matching: find.textContaining(_sessionPrice))), 'el cobro en Pagos');
  await _settle(tester);
  expect(find.descendant(of: payments, matching: find.text(pointName)), findsWidgets, reason: 'La columna Caja muestra el puesto');

  await tester.tap(find.descendant(of: payments, matching: find.byTooltip('Acciones')).first);
  await _wait(tester, () => _visible(find.text('Anular cobro')), 'el menú del cobro');
  await _settle(tester);
  await tester.tap(find.text('Anular cobro'));
  await _wait(tester, () => _visible(find.byType(AlertDialog)), 'el diálogo de anular');
  await _settle(tester);
  expect(_inDialog(find.textContaining(_sessionPrice)), findsOneWidget, reason: 'Tiene que abrir el cobro recién hecho');
  await tester.tap(_inDialog(find.text('Error de carga')));
  await _settle(tester);
  await tester.tap(_inDialog(find.widgetWithText(FilledButton, 'Anular cobro')));
  await _dialogClosed(tester, 'que se anule el cobro');
  await _wait(tester, () => _visible(find.descendant(of: payments, matching: find.text('Anulado'))), 'la etiqueta Anulado');

  // 6. Cierra contando de menos: la diferencia pide una explicación.
  router!.go(AppRoutes.CASH_ROUTE.path);
  final card = find.byKey(ValueKey('cash.point.$pointName'));
  await _wait(tester, () => _visible(card), 'el puesto en Caja');
  await _settle(tester);
  await _tap(tester, find.descendant(of: card, matching: find.text('Cerrar caja')));
  await _wait(tester, () => _visible(_inDialog(find.text('Ingresar solo el total'))), 'el conteo');
  await _tap(tester, _inDialog(find.text('Ingresar solo el total')));
  await tester.enterText(_inDialog(find.byType(TextFormField)), '900');
  await _settle(tester);
  await _tap(tester, _inDialog(find.text('Ver resultado')));
  await _wait(tester, () => _visible(_inDialog(find.text('Faltante'))), 'el resultado con faltante');

  await _tap(tester, _inDialog(find.text('Confirmar cierre')));
  expect(_inDialog(find.text('Contá qué pasó con la diferencia.')), findsOneWidget);
  await tester.enterText(find.byKey(const ValueKey('cash.close.note')), 'Vuelto mal dado');
  await _settle(tester);
  await _tap(tester, _inDialog(find.text('Confirmar cierre')));
  await _dialogClosed(tester, 'que se cierre la caja');

  // 7. El cierre queda para revisar.
  await tester.tap(find.text('Cierres'));
  await _wait(tester, () => _visible(find.text('Revisar')), 'el cierre para revisar');
  await _settle(tester);
  expect(find.text(pointName), findsWidgets);

  // 8. Apaga la caja: el menú se va.
  await _openConfigTab(tester, router!);
  await _setCashEnabled(tester, false);
  await _wait(tester, () => !_visible(_cashMenu), 'que se vaya el menú Caja');
}
