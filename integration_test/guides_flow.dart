import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/config/router/app_router.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/presentation/components/onboarding/onboarding_tour.dart';
import 'package:turni/core/utils/admin_vocabulary.dart';
import 'package:turni/main.dart' as app;
import 'package:turni/presentation/admin/guides/admin_guides.dart';
import 'package:turni/presentation/admin/guides/guide.dart';

/// Flujo e2e de las guías del signo de pregunta: corre cada guía que el
/// admin puede ver, tocando "Siguiente" hasta "Listo", y verifica que no
/// falte ningún paso obligatorio (su anchor no apareció en pantalla). Lo
/// comparten los dos runners, igual que `club_config_flow.dart`:
///   - `integration_test/guides_flow_test.dart`: Chrome real.
///   - `test/e2e/guides_flow_test.dart`: VM de Dart.
///
/// Requiere backend + Postgres locales con `npm run seed:dev` (deja turnos
/// libres, reservados y solicitudes alrededor de hoy, clientes, torneos y
/// abonos) y el DEV_ADMIN_TOKEN que imprime.
///
/// Opcional: `--dart-define=GUIDE=<id>,<id>` corre solo esas guías.
const devAdminToken = String.fromEnvironment('DEV_ADMIN_TOKEN');
const onlyGuide = String.fromEnvironment('GUIDE');

/// Como en `club_config_flow.dart`, tiempo real para la red y después
/// frames, pero el mismo tiempo de cada uno: el recorrido espera a cada
/// target con el reloj de los frames, y si corre más rápido que la red
/// saltea pasos de pantallas que todavía están cargando.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future.delayed(const Duration(milliseconds: 300));
  });
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Un botón de la card del recorrido (la app también tiene sus propios
/// "Siguiente", ej. el asistente para agregar turnos).
final _overlay = find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_OnboardingOverlay');

Finder _tourButton(String label) => find.descendant(of: _overlay, matching: find.widgetWithText(FilledButton, label));

Future<void> runGuidesFlow(WidgetTester tester) async {
  expect(
    devAdminToken,
    isNotEmpty,
    reason: 'Corré con --dart-define=DEV_ADMIN_TOKEN=<token impreso por `npm run seed:dev`>',
  );

  app.main();

  // Los overflows de layout no son de las guías: se anotan y se informan al
  // final en vez de cortar la corrida en la primera pantalla que se pase.
  final overflows = <String>{};
  final onError = FlutterError.onError;
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (message.contains('overflowed')) {
      overflows.add('$message (${details.context?.toDescription() ?? ''})');
      return;
    }
    onError?.call(details);
  };

  GoRouter? router;
  for (var i = 0; i < 200 && router == null; i++) {
    try {
      router = sl<GoRouter>();
    } catch (_) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  expect(router, isNotNull, reason: 'GoRouter nunca quedó registrado en el service locator');
  // Que checkAuthStatus() lea el token y cargue el admin (permisos, servicios).
  for (var i = 0; i < 10; i++) {
    await _settle(tester);
  }

  final only = onlyGuide.split(',').where((id) => id.isNotEmpty).toSet();
  final guides = AdminGuides.all.where((g) => g.isVisible && (only.isEmpty || only.contains(g.id))).toList();
  expect(guides, isNotEmpty, reason: 'El admin no ve ninguna guía');

  final failures = <String>[];
  try {
    await _runAll(tester, guides, failures);
  } finally {
    FlutterError.onError = onError;
  }
  for (final overflow in overflows) {
    debugPrint('Overflow: $overflow');
  }

  // Que no queden timers de las pantallas (el binding de test los rechaza).
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 10));

  expect(failures, isEmpty, reason: failures.join('\n'));
}

Future<void> _runAll(WidgetTester tester, List<Guide> guides, List<String> failures) async {
  for (final guide in guides) {
    // Cada guía arranca limpia: sin diálogos ni pantallas apiladas de la anterior.
    final navigator = rootNavigatorKey.currentState!;
    while (navigator.canPop()) {
      navigator.pop();
      await _settle(tester);
    }

    final steps = guide.steps(adminVocabulary());
    OnboardingResult? result;
    guide.run().then((r) => result = r);

    final end = DateTime.now().add(const Duration(minutes: 2));
    while (result == null) {
      if (DateTime.now().isAfter(end)) {
        final texts = find.descendant(of: _overlay, matching: find.byType(Text)).evaluate().map((e) => (e.widget as Text).data).whereType<String>();
        failures.add('${guide.id}: no terminó en 2 minutos (en pantalla: ${texts.join(' | ')})');
        // Cerrarla para que la siguiente pueda arrancar.
        for (final label in ['Saltear', 'Salir', 'Listo']) {
          final close = find.descendant(of: _overlay, matching: find.text(label));
          if (close.evaluate().isNotEmpty) await tester.tap(close.first);
        }
        await _settle(tester);
        break;
      }
      final done = _tourButton('Listo');
      final next = _tourButton('Siguiente');
      if (done.evaluate().isNotEmpty) {
        await tester.tap(done);
      } else if (next.evaluate().isNotEmpty) {
        await tester.tap(next);
      }
      await _settle(tester);
    }

    final finished = result;
    if (finished == null) continue;
    final skipped = [for (final i in finished.skipped) steps[i].title];
    debugPrint('Guía ${guide.id}: ${finished.shown.length} pasos'
        '${skipped.isEmpty ? '' : ' · salteados: ${skipped.join(', ')}'}');
    final missing = finished.missing(steps);
    if (!finished.completed) failures.add('${guide.id}: no llegó a "Listo"');
    if (missing.isNotEmpty) {
      failures.add('${guide.id}: faltan ${missing.map((i) => '"${steps[i].title}" (${steps[i].anchor})').join(', ')}');
    }
  }
}
