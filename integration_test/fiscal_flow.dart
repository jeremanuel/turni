import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/config/router/app_routes.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/presentation/components/onboarding/tour_anchor.dart';
import 'package:turni/core/services/fiscal_status.dart';
import 'package:turni/core/services/realtime/realtime_service.dart';
import 'package:turni/main.dart' as app;

/// Flujo e2e de la facturación con el simulador de ARCA, contra el backend y
/// la DB locales reales: carga los datos fiscales del club, lo conecta y
/// prende la facturación; cobra un turno a nombre de un CUIT que el simulador
/// rechaza, lo corrige desde Caja › Comprobantes y lo ve autorizado con su
/// CAE. Al final apaga la facturación. Lo comparten:
///   - `integration_test/fiscal_flow_test.dart`: Chrome real.
///   - `test/e2e/fiscal_flow_test.dart`: VM de Dart.
///
/// Requiere el backend con FISCAL_PROVIDER_MOCK=true y `npm run seed:e2e` en
/// turni_mono_be. Los valores salen de su salida:
///   --dart-define=DEV_ADMIN_TOKEN=$adminToken
///   --dart-define=E2E_FISCAL_SESSION_ID=$fiscalSessionId
const devAdminToken = String.fromEnvironment('DEV_ADMIN_TOKEN');
const fiscalSessionId = int.fromEnvironment('E2E_FISCAL_SESSION_ID');

/// El simulador rechaza este CUIT (MOCK_REJECTED_CUIT del back).
const _rejectedCuit = '20-11111111-2';
const _validCuit = '30-71234567-1';

/// Errores de Flutter de la corrida: se muestran también si el flujo corta por un timeout.
final _errors = <String>[];

Future<void> _wait(
  WidgetTester tester,
  bool Function() done,
  String what, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) {
      final errors = _errors.isEmpty ? '' : '\nErrores de Flutter:\n${_errors.toSet().join('\n')}';
      fail('Timeout esperando $what$errors');
    }
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

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder);
  await _settle(tester);
}

/// Si el finder es un botón (o está dentro de uno), si está habilitado.
bool _enabled(Finder finder) {
  final buttons = find.ancestor(of: finder, matching: find.byWidgetPredicate((w) => w is ButtonStyleButton), matchRoot: true);
  final found = buttons.evaluate();
  return found.isEmpty || found.any((e) => (e.widget as ButtonStyleButton).onPressed != null);
}

/// Toca un botón cuando se habilita (mientras guarda o carga queda apagado).
Future<void> _press(WidgetTester tester, Finder finder, String what) async {
  await _wait(tester, () => _visible(finder) && _enabled(finder.first), what);
  _clearSnackBars(tester);
  await _tap(tester, finder.first);
}

/// La agenda avisa con un SnackBar si hay turnos superpuestos (la base de e2e
/// los acumula de corridas anteriores) y el aviso tapa el pie del panel.
void _clearSnackBars(WidgetTester tester) {
  for (final messenger in tester.stateList<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))) {
    messenger.removeCurrentSnackBar();
    messenger.clearSnackBars();
  }
}

Future<void> _enter(WidgetTester tester, Finder finder, String text) async {
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await _settle(tester);
}

/// Elige la condición frente al IVA en el diálogo del receptor.
Future<void> _pickCondition(WidgetTester tester, String label) async {
  await _tap(tester, _key('fiscal.receiver.condition'));
  await _tap(tester, find.text(label).last);
}

Future<void> _dialogClosed(WidgetTester tester, String what) async {
  await _wait(tester, () => !_visible(find.byType(AlertDialog)), what);
  await _settle(tester);
}

/// El texto del estado de la conexión, en la etiqueta de la tarjeta.
String? _connectionLabel(WidgetTester tester) {
  final tag = _key('fiscal.config.connectionStatus');
  if (!_visible(tag)) return null;
  return tester.widgetList<Text>(find.descendant(of: tag, matching: find.byType(Text))).first.data;
}

Future<void> _openFiscalConfig(WidgetTester tester, GoRouter router) async {
  router.go(AppRoutes.ADMIN_SETTINGS_ROUTE.path);
  await _wait(tester, () => _visible(find.text('Facturación')), 'la sección Facturación');
  await _settle(tester);
  await tester.tap(find.text('Facturación').first);
  await _wait(tester, () => _visible(_key('fiscal.config.cuit')), 'la configuración de facturación');
  await _settle(tester);
}

Future<void> runFiscalFlow(WidgetTester tester) async {
  final errors = _errors..clear();
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
  expect(fiscalSessionId, isNonZero, reason: 'Corré con --dart-define=E2E_FISCAL_SESSION_ID=<fiscalSessionId>');

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

  // 1. Datos fiscales de un club Responsable Inscripto, con emisión automática.
  await _openFiscalConfig(tester, router!);
  expect(_key('fiscal.config.simulated'), findsOneWidget, reason: 'El back tiene que correr con FISCAL_PROVIDER_MOCK=true');
  await _tap(tester, _key('fiscal.config.regime.RESPONSABLE_INSCRIPTO'));
  await _enter(tester, _key('fiscal.config.cuit'), '30-50001091-2');
  await _enter(tester, _key('fiscal.config.legalName'), 'Club E2E SA');
  await _enter(tester, _key('fiscal.config.address'), 'Calle 1 123');
  await _enter(tester, _key('fiscal.config.pointOfSale'), '1');
  await _tap(tester, _key('fiscal.config.mode.AUTOMATIC'));
  await _tap(tester, _key('fiscal.config.save'));
  await _wait(tester, () => _connectionLabel(tester) == 'Sin conectar', 'que se guarden los datos');

  // 2. Delega, verifica contra el simulador y prende la facturación.
  await _press(tester, _key('fiscal.config.delegated'), 'el botón Ya lo hice');
  await _wait(tester, () => _connectionLabel(tester) == 'Verificando', 'la conexión en verificación');
  await _press(tester, _key('fiscal.config.verify'), 'el botón Verificar ahora');
  await _wait(tester, () => _connectionLabel(tester) == 'Conectada', 'la conexión verificada');
  await _tap(tester, _key('fiscal.config.enabled'));
  await _press(tester, _key('fiscal.config.save'), 'el botón Guardar');
  await _wait(tester, () => FiscalStatus.enabled.value, 'que se prenda la facturación');
  await _wait(tester, () => _visible(_cashMenu), 'el menú Comprobantes');

  // 3. En Cobrar se ve qué comprobante sale; a nombre de un CUIT pasa a Factura A.
  router!.goNamed(AppRoutes.SESSION_MANAGER_RESERVE_ROUTE.name, pathParameters: {'idSession': '$fiscalSessionId'});
  await _wait(tester, () => _visible(find.text('Cobrar')), 'el panel del turno');
  await _settle(tester);
  await tester.tap(find.text('Cobrar').first);
  await _wait(tester, () => _visible(find.textContaining('Factura B · Consumidor final')), 'la fila Comprobante');
  await _settle(tester);

  await _tap(tester, _key('fiscal.receipt.change'));
  await _wait(tester, () => _visible(_key('fiscal.receiver.mode.cuit')), 'el diálogo del receptor');
  await _tap(tester, _key('fiscal.receiver.mode.cuit'));
  await _enter(tester, _key('fiscal.receiver.number'), _rejectedCuit);
  await _pickCondition(tester, 'Monotributo');
  await _enter(tester, _key('fiscal.receiver.name'), 'Rechazo SA');
  await _tap(tester, _key('fiscal.receiver.save'));
  await _dialogClosed(tester, 'que se guarden los datos del cliente');
  await _wait(tester, () => _visible(find.textContaining('Factura A ·')), 'la Factura A en la fila');

  await _press(tester, find.textContaining('Cobrar \$'), 'el botón Cobrar');
  await _wait(tester, () => !_visible(_key('fiscal.receipt.title')), 'volver al panel después de cobrar');
  await _settle(tester);

  // 4. ARCA (el simulador) la rechaza: se corrige y se reintenta.
  router!.go('${AppRoutes.CASH_ROUTE.path}?tab=comprobantes');
  await _wait(tester, () => _visible(find.text('Rechazado')), 'el comprobante rechazado', timeout: const Duration(seconds: 60));
  await _settle(tester);
  await _press(tester, find.text('Corregir y reintentar'), 'el botón Corregir y reintentar');
  await _wait(tester, () => _visible(_inDialog(find.text('ARCA lo rechazó'))), 'el diálogo de corregir');
  await _enter(tester, _key('fiscal.receiver.number'), _validCuit);
  await _pickCondition(tester, 'Responsable Inscripto');
  await _enter(tester, _key('fiscal.receiver.name'), 'Acme SA');
  await _tap(tester, _key('fiscal.receiver.save'));
  await _dialogClosed(tester, 'que se mande de nuevo');

  // 5. Sale autorizada, con su CAE.
  await _wait(tester, () => _visible(find.text('Autorizado')), 'el comprobante autorizado', timeout: const Duration(seconds: 60));
  await _settle(tester);
  await _tap(tester, find.text('Ver').first);
  await _wait(tester, () => _visible(_inDialog(find.text('CAE'))), 'el detalle con el CAE');
  expect(_inDialog(find.textContaining('Acme SA')), findsWidgets);
  await _tap(tester, _inDialog(find.text('Cerrar')));
  await _dialogClosed(tester, 'que se cierre el detalle');

  // 6. Apaga la facturación para no cambiarles el comportamiento a los demás e2e.
  await _openFiscalConfig(tester, router!);
  await _tap(tester, _key('fiscal.config.enabled'));
  await _tap(tester, _key('fiscal.config.save'));
  await _wait(tester, () => !FiscalStatus.enabled.value, 'que se apague la facturación');
  await _wait(tester, () => !_visible(_cashMenu), 'que se vaya el menú Comprobantes');
}
