import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../integration_test/guides_flow.dart';

/// e2e de las guías corrido sobre la VM de Dart (sin navegador). El flujo
/// vive en `integration_test/guides_flow.dart`, compartido con el runner de
/// Chrome. El entorno es el mismo que `club_config_flow_test.dart`.
///
/// Correr con:
///   flutter test test/e2e/guides_flow_test.dart \
///     --dart-define=DEV_ADMIN_TOKEN=<token del seed:dev> [--dart-define=GUIDE=<id>]
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final fontsCache = Directory.systemTemp.createTempSync('turni_e2e_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => fontsCache.path,
    );
    HttpOverrides.global = null;
  });

  testWidgets('cada guía recorre todos sus pasos', (tester) async {
    // Layout de escritorio, como en club_config_flow_test.dart.
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await runGuidesFlow(tester);
  }, timeout: const Timeout(Duration(minutes: 30)));
}
