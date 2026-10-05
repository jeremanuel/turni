import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/config/router/app_routes.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/main.dart' as app;
import 'package:turni/presentation/admin/club_config/tabs/club_info_tab.dart';
import 'package:turni/presentation/admin/club_config/tabs/club_partitions_tab.dart';
import 'package:turni/presentation/admin/club_config/tabs/price_tariffs_tab.dart';
import 'package:turni/presentation/admin/club_config/tabs/products_tab.dart';
import 'package:turni/presentation/admin/club_config/tabs/session_request_settings_tab.dart';
import 'package:turni/presentation/admin/club_config/widgets/club_partition_card.dart';

/// Flujo e2e de toda la pantalla "Configuración" (admin), contra el backend y
/// la DB locales reales (no mocks). Lo comparten los dos runners:
///   - `integration_test/club_config_flow_test.dart`: Chrome real vía
///     `flutter drive` + chromedriver (se ve correr).
///   - `test/e2e/club_config_flow_test.dart`: VM de Dart con `flutter test`
///     (sin navegador; mockea los plugins nativos que la VM no tiene).
/// Cada runner solo prepara su entorno y llama a [runClubConfigFlow]: así no
/// se desincronizan (ya pasó: los arreglos de uno no llegaban al otro).
///
/// Como hace llamadas de red REALES, toda espera que dependa de ellas le da
/// tiempo real al event loop con `tester.runAsync(...)` -- en la VM `pump`
/// por sí solo no avanza el reloj real.
///
/// Requiere backend + Postgres locales y haber corrido `npm run seed:dev` en
/// turni_mono_be (deja a este admin dueño del club "Club Central" e imprime
/// el DEV_ADMIN_TOKEN). La DB de dev ACUMULA lo que crea cada corrida
/// (sectores "Tenis", productos de \$2.500...): el flujo está escrito para
/// tolerarlo.
const devAdminToken = String.fromEnvironment('DEV_ADMIN_TOKEN');

/// Deja correr tiempo real (para llamadas de red en curso) y después avanza
/// ~600ms de frames, suficiente para que terminen las transiciones de
/// tabs/diálogos/menús. No usa `pumpAndSettle`: con la app real siempre hay
/// alguna animación infinita en pantalla (spinners de carga) y nunca "se
/// asienta" -- el test moría con "pumpAndSettle timed out".
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future.delayed(const Duration(milliseconds: 150));
  });
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      fail('Timeout esperando ${finder.toString()}');
    }
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await _settle(tester);
}

/// `tap` que primero scrollea hasta el widget: la DB de dev acumula sectores
/// de corridas anteriores de este mismo e2e, así que formularios como "Alta
/// de nuevo deporte/sector" quedan fuera de pantalla y el tap no les llega.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder);
}

/// Como `find.text`, pero solo widgets `Text`: `find.text` también matchea el
/// `EditableText` del campo donde se tipeó ese mismo texto, así que esperar
/// "a que aparezca X en la lista" daba positivo al instante, antes de que el
/// backend respondiera (y el paso siguiente fallaba sin motivo aparente).
Finder _label(String text) => find.byWidgetPredicate((widget) => widget is Text && widget.data == text);

/// Busca un `TextField` por su `labelText`, dentro de `scope`. Sirve tanto
/// para un `TextField` suelto como para uno de adentro de un `TextFormField`
/// (incluye `PriceField`/`TimeField`/`DurationMinutesField`, que renderizan
/// un `TextField` real con la misma decoration) -- evita depender de un
/// índice frágil cuando hay varios campos en la misma pantalla.
Finder _fieldByLabel(Finder scope, String label) {
  return find.descendant(
    of: scope,
    matching: find.byWidgetPredicate((widget) => widget is TextField && widget.decoration?.labelText == label),
  );
}

Future<void> runClubConfigFlow(WidgetTester tester) async {
  expect(
    devAdminToken,
    isNotEmpty,
    reason: 'Corré con --dart-define=DEV_ADMIN_TOKEN=<token impreso por `npm run seed:dev`>',
  );

  final suffix = DateTime.now().millisecondsSinceEpoch.toString();
  final sectorName = 'Cancha E2E $suffix';
  final courtDescription = 'Cancha E2E $suffix (cancha)';
  final tariffName = 'Tarifa E2E $suffix';
  final categoryName = 'Categoria E2E $suffix';
  final productName = 'Producto E2E $suffix';

  app.main();

  // Espera a que el service locator esté listo antes de tocar nada. Dio y
  // GoRouter se registran durante la cadena async de main()/MyApp.initState
  // (dotenv, Firebase) -- necesitan tiempo REAL, no solo pumps.
  Dio? dio;
  GoRouter? router;
  for (var i = 0; i < 200 && (dio == null || router == null); i++) {
    try {
      dio ??= sl<Dio>();
    } catch (_) {}
    try {
      router ??= sl<GoRouter>();
    } catch (_) {}
    if (dio == null || router == null) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  expect(dio, isNotNull, reason: 'Dio nunca quedó registrado en el service locator');
  expect(router, isNotNull, reason: 'GoRouter nunca quedó registrado en el service locator');

  // El DEV_ADMIN_TOKEN ya se precarga en LocalStorage dentro de main() antes
  // de runApp (ver lib/main.dart) -- deja tiempo real para que
  // checkAuthStatus() lo lea y el router navegue a Home.
  await _settle(tester);

  // Navega directo a /admin/settings con el mismo mecanismo que usa el
  // botón "Ajustes" del NavigationRail (context.push), sin depender de que
  // el layout desktop/mobile esté visible según el tamaño de la ventana.
  router!.push(AppRoutes.ADMIN_SETTINGS_ROUTE.path);
  await _pumpUntilFound(tester, find.text('Configuración'));

  for (final tabLabel in const [
    'Información del club',
    'Deportes y canchas',
    'Tarifas por horario',
    'Productos',
    'Solicitudes de turno',
  ]) {
    expect(find.text(tabLabel), findsWidgets, reason: 'Falta la tab "$tabLabel"');
  }

  // ------------------------------------------------------------------
  // Tab 1: Información del club -- edita y revierte la dirección.
  // ------------------------------------------------------------------
  final infoScope = find.byType(ClubInfoTab);
  await _pumpUntilFound(tester, find.descendant(of: infoScope, matching: find.text('Club Central')));

  final addressField = _fieldByLabel(infoScope, 'Dirección');
  expect(
    tester.widget<TextField>(addressField).controller?.text,
    'Av. Siempre Viva 123',
    reason: 'Dato sembrado por seed-dev.ts para el club 800001',
  );

  await tester.enterText(addressField, 'Av. Siempre Viva 123 (e2e)');
  await _tap(tester, find.widgetWithText(FilledButton, 'Guardar cambios'));
  await _pumpUntilFound(tester, find.text('Datos del club guardados.'));

  await tester.enterText(addressField, 'Av. Siempre Viva 123');
  await _tap(tester, find.widgetWithText(FilledButton, 'Guardar cambios'));
  await _pumpUntilFound(tester, find.text('Datos del club guardados.'));

  // ------------------------------------------------------------------
  // Tab 2: Deportes y canchas -- crea un sector nuevo y una cancha adentro.
  // ------------------------------------------------------------------
  await _tap(tester, find.text('Deportes y canchas'));
  await _settle(tester);

  final partitionsScope = find.byType(ClubPartitionsTab);
  await _pumpUntilFound(
    tester,
    find.descendant(of: partitionsScope, matching: find.text('Alta de nuevo deporte/sector')),
  );

  await _tap(tester, find.descendant(of: partitionsScope, matching: find.byType(DropdownButtonFormField<int>)));
  await _settle(tester);
  await _tap(tester, find.text('Tenis').last);
  await _settle(tester);

  await tester.enterText(_fieldByLabel(partitionsScope, 'Nombre de la partición física'), sectorName);
  await _tap(tester, find.descendant(of: partitionsScope, matching: find.widgetWithText(FilledButton, 'Crear sector')));
  // Buscado DENTRO de una ClubPartitionCard: `find.text` también matchea el
  // EditableText del propio campo "Nombre de la partición física", así que
  // sin acotar daba por creado el sector antes de que el backend respondiera.
  final newSectorCard = find.ancestor(of: _label(sectorName), matching: find.byType(ClubPartitionCard));
  await _pumpUntilFound(tester, newSectorCard);

  // Toggle de "Activo" del sector recién creado: apaga y prende, confirma
  // en ambos casos que el Switch (controlado) refleja lo que devolvió el
  // backend, no solo que no explotó.
  final sectorSwitch = find.descendant(of: newSectorCard, matching: find.byType(Switch)).first;

  await _tap(tester, sectorSwitch);
  var end = DateTime.now().add(const Duration(seconds: 15));
  while (tester.widget<Switch>(sectorSwitch).value != false) {
    if (DateTime.now().isAfter(end)) fail('Timeout esperando que se desactive el switch del sector');
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }

  await _tap(tester, sectorSwitch);
  end = DateTime.now().add(const Duration(seconds: 15));
  while (tester.widget<Switch>(sectorSwitch).value != true) {
    if (DateTime.now().isAfter(end)) fail('Timeout esperando que se reactive el switch del sector');
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }

  // Agregar una cancha adentro del sector nuevo, vía el diálogo (no inline).
  await _tap(
    tester,
    find.descendant(of: newSectorCard, matching: find.widgetWithText(OutlinedButton, 'Agregar cancha')),
  );
  await _settle(tester);

  final courtDialog = find.byType(AlertDialog);
  await _pumpUntilFound(tester, find.descendant(of: courtDialog, matching: find.text('Nueva cancha')));
  await tester.enterText(_fieldByLabel(courtDialog, 'Descripción'), courtDescription);
  await _tap(tester, find.descendant(of: courtDialog, matching: find.widgetWithText(FilledButton, 'Crear')));
  await _pumpUntilFound(tester, find.descendant(of: partitionsScope, matching: _label(courtDescription)));

  // ------------------------------------------------------------------
  // Tab 3: Tarifas por horario -- nueva tarifa, agrega la cancha recién
  // creada como miembro, agrega una franja y confirma el solapamiento.
  // ------------------------------------------------------------------
  await _tap(tester, find.text('Tarifas por horario'));
  await _settle(tester);

  final tariffsScope = find.byType(PriceTariffsTab);
  await _pumpUntilFound(tester, find.descendant(of: tariffsScope, matching: find.text('Tenis')));
  // Cada corrida de este e2e crea un sector "Tenis" nuevo y la DB de dev los
  // acumula; los chips vienen ordenados por id, así que el recién creado es
  // el último.
  await _tap(tester, find.descendant(of: tariffsScope, matching: find.text('Tenis')).last);
  await _settle(tester);

  await _tap(tester, find.descendant(of: tariffsScope, matching: find.widgetWithText(TextButton, 'Nueva tarifa')));
  await _settle(tester);

  final tariffDialog = find.byType(AlertDialog);
  await _pumpUntilFound(tester, find.descendant(of: tariffDialog, matching: find.text('Nueva tarifa')));
  await tester.enterText(_fieldByLabel(tariffDialog, 'Nombre de la tarifa'), tariffName);
  await _tap(tester, find.descendant(of: tariffDialog, matching: find.widgetWithText(FilledButton, 'Crear')));
  await _pumpUntilFound(tester, find.descendant(of: tariffsScope, matching: _label(tariffName)));

  // Agregar la cancha del sector nuevo como miembro de esta tarifa.
  await _tap(tester, find.descendant(of: tariffsScope, matching: find.widgetWithText(Chip, 'Agregar cancha')));
  await _settle(tester);
  await _tap(tester, _label(courtDescription).last);
  await _pumpUntilFound(
    tester,
    find.descendant(
      of: find.ancestor(of: find.text('Canchas incluidas'), matching: find.byType(Card)).first,
      matching: _label(courtDescription),
    ),
  );

  // Primera franja: toda la semana, 00:00-23:59.
  await tester.enterText(_fieldByLabel(tariffsScope, 'Precio'), '15000');
  await _tap(
    tester,
    find.descendant(of: tariffsScope, matching: find.widgetWithText(OutlinedButton, 'Agregar franja')),
  );
  await _pumpUntilFound(tester, find.descendant(of: tariffsScope, matching: find.text('00:00 – 23:59')));
  expect(find.descendant(of: tariffsScope, matching: find.text('\$15.000')), findsOneWidget);

  // Segunda franja: se solapa por completo con la anterior -> el backend
  // la rechaza (409) y el front tiene que mostrar el error (bug ya
  // arreglado: el SnackBar de error salía fuera de pantalla).
  await tester.enterText(_fieldByLabel(tariffsScope, 'Precio'), '5000');
  await _tap(
    tester,
    find.descendant(of: tariffsScope, matching: find.widgetWithText(OutlinedButton, 'Agregar franja')),
  );
  await _pumpUntilFound(tester, find.textContaining('solap'));

  // ------------------------------------------------------------------
  // Tab 4: Productos -- nueva categoría y nuevo producto.
  // ------------------------------------------------------------------
  await _tap(tester, find.text('Productos'));
  await _settle(tester);

  final productsScope = find.byType(ProductsTab);
  await _pumpUntilFound(tester, find.descendant(of: productsScope, matching: find.text('Categorías')));

  await tester.enterText(_fieldByLabel(productsScope, 'Nueva categoría'), categoryName);
  await _tap(
    tester,
    find.descendant(of: productsScope, matching: find.widgetWithText(OutlinedButton, 'Crear categoría')),
  );
  await _pumpUntilFound(tester, find.descendant(of: productsScope, matching: _label(categoryName)));

  await tester.enterText(_fieldByLabel(productsScope, 'Nombre'), productName);
  await _tap(tester, find.descendant(of: productsScope, matching: find.byType(DropdownButtonFormField<int?>)));
  await _settle(tester);
  await _tap(tester, _label(categoryName).last);
  await _settle(tester);
  await tester.enterText(_fieldByLabel(productsScope, 'Precio'), '2500');
  await _tap(
    tester,
    find.descendant(of: productsScope, matching: find.widgetWithText(OutlinedButton, 'Agregar producto')),
  );
  await _pumpUntilFound(tester, find.descendant(of: productsScope, matching: _label(productName)));
  // El precio tiene que estar en la MISMA fila que el producto creado (la
  // DB de dev acumula productos de $2.500 de corridas anteriores).
  final productRowY = tester.getCenter(find.descendant(of: productsScope, matching: _label(productName))).dy;
  final pricesInRow = find
      .descendant(of: productsScope, matching: _label('\$2.500'))
      .evaluate()
      .where((element) => (tester.getCenter(find.byWidget(element.widget)).dy - productRowY).abs() < 2);
  expect(pricesInRow, hasLength(1), reason: 'No se ve \$2.500 en la fila de "$productName"');

  // ------------------------------------------------------------------
  // Tab 5: Solicitudes de turno -- guarda el mismo valor (sembrado en 60).
  // ------------------------------------------------------------------
  await _tap(tester, find.text('Solicitudes de turno'));
  await _settle(tester);

  final requestsScope = find.byType(SessionRequestSettingsTab);
  final ttlField = _fieldByLabel(requestsScope, 'Minutos para expirar');
  await _pumpUntilFound(tester, ttlField);
  expect(tester.widget<TextField>(ttlField).controller?.text, '60');

  await _tap(tester, find.descendant(of: requestsScope, matching: find.widgetWithText(FilledButton, 'Guardar')));
  await _pumpUntilFound(tester, find.text('Configuración guardada.'));

  // Deja vencer el timer de 3s del SnackBar: si queda pendiente al
  // desmontar, flutter_test falla con "A Timer is still pending".
  await tester.pump(const Duration(seconds: 4));
  await _settle(tester);
}
