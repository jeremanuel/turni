import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turni/core/config/environment.dart';
import 'package:turni/core/config/router/app_routes.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/services/realtime/realtime_service.dart';
import 'package:turni/domain/entities/session.dart';
import 'package:turni/main.dart' as app;
import 'package:turni/presentation/admin/session_manager_screen/bloc/session_manager_bloc.dart';
import 'package:turni/presentation/admin/session_manager_screen/bloc/session_manager_event.dart';
import 'package:turni/presentation/admin/session_manager_screen/sessions_manager_desktop.dart';
import 'package:turni/presentation/admin/session_manager_screen/widgets/agenda_container.dart';

/// e2e del canal en tiempo real en el admin (socket.io, ver
/// turni_mono_be/docs/feature/REALTIME.md), en la VM contra el backend y la
/// DB locales reales: un cliente pide un turno por la API y la agenda lo
/// muestra sola, sin recargar.
///
/// Requiere `npm run seed:dev` en turni_mono_be (imprime los dos tokens):
///   flutter test test/e2e/realtime_flow_test.dart \
///     --dart-define=DEV_ADMIN_TOKEN=<token del admin> \
///     --dart-define=DEV_CLIENT_TOKEN=<token del cliente de test>
const _clientToken = String.fromEnvironment('DEV_CLIENT_TOKEN');

Future<void> _wait(WidgetTester tester, bool Function() done, String what, {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('Timeout esperando $what (canal: ${RealtimeService.instance.status.value})');
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Igual que club_config_flow_test.dart: sin plugins nativos en la VM y
    // con HTTP real contra la API local.
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final fontsCache = Directory.systemTemp.createTempSync('turni_e2e_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => fontsCache.path,
    );
    HttpOverrides.global = null;
  });

  testWidgets('la agenda muestra sola el turno que pide un cliente', (tester) async {
    expect(_clientToken, isNotEmpty, reason: 'Corré con --dart-define=DEV_CLIENT_TOKEN=<token del seed:dev>');
    // Igual que club_config_flow_test.dart: en 800x600 el layout de
    // escritorio del admin se desborda.
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Este e2e prueba el tiempo real: tolera solo los desbordes de layout ya
    // conocidos (la columna de acciones de la tabla de clientes, arreglada
    // aparte). Cualquier otro error de Flutter hace fallar el test.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    app.main();

    GoRouter? router;
    await _wait(tester, () {
      try {
        router ??= sl<GoRouter>();
      } catch (_) {}
      return router != null;
    }, 'que arranque la app');

    // 1. Con la sesión del admin, el canal en tiempo real se conecta solo.
    await _wait(tester, () => RealtimeService.instance.isConnected, 'que el canal en tiempo real se conecte');

    // 2. La agenda.
    router!.go(AppRoutes.SESSION_MANAGER_ROUTE.path);
    // Escritorio (SessionManagerDesktop) o celular/tablet (AgendaContainer).
    final agenda = find.byWidgetPredicate((w) => w is SessionManagerDesktop || w is AgendaContainer);
    await _wait(tester, () => agenda.evaluate().isNotEmpty, 'la agenda');
    final bloc = tester.element(agenda.first).read<SessionManagerBloc>();
    await _wait(tester, () => !bloc.state.isFirstLoad && !bloc.state.isLoadingSessions, 'que cargue la agenda');

    // 3. Un turno libre a futuro (si hoy no queda ninguno, en los días siguientes).
    Session? free;
    final now = DateTime.now();
    for (var day = 0; day < 7 && free == null; day++) {
      if (day > 0) {
        final target = DateTime(now.year, now.month, now.day).add(Duration(days: day));
        bloc.add(SessionChangeDateEvent(target));
        await _wait(tester, () => bloc.state.currentDate == target && !bloc.state.isLoadingSessions, 'los turnos del día +$day');
      }
      for (final s in bloc.state.sessions) {
        if (s.clientId == null && s.status == null && s.startTime.isAfter(now.add(const Duration(hours: 1)))) {
          free = s;
          break;
        }
      }
    }
    expect(free, isNotNull, reason: 'El seed:dev debería dejar turnos libres en la próxima semana');
    final sessionId = free!.sessionId;

    // 4. Un cliente lo pide desde la app (otra sesión, por la API).
    final client = Dio(BaseOptions(
      baseUrl: Environment.apiUrl,
      contentType: 'application/json',
      headers: {'Authorization': 'Bearer $_clientToken'},
    ));
    final reserved = await tester.runAsync(() => client.post('/session/$sessionId/reserve'));
    expect(reserved?.data['status'], 'PENDING');

    // 5. La agenda lo muestra pedido sin que nadie recargue.
    await _wait(
      tester,
      () => bloc.state.sessions.any((s) => s.sessionId == sessionId && s.clientId != null),
      'que la agenda muestre el turno pedido sin recargar',
      timeout: const Duration(seconds: 10),
    );

    // Cierre: sin canal ni app, y que venzan los timers de keep-alive de las
    // conexiones HTTP (si no, el binding falla por timers pendientes).
    RealtimeService.instance.disconnect();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
