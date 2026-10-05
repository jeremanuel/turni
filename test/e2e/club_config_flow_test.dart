import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../integration_test/club_config_flow.dart';

/// e2e de "Configuración" corrido sobre la VM de Dart (sin navegador). El
/// flujo en sí vive en `integration_test/club_config_flow.dart`, compartido
/// con el runner de Chrome.
///
/// Correr con:
///   flutter test test/e2e/club_config_flow_test.dart \
///     --dart-define=DEV_ADMIN_TOKEN=<token del seed:dev>
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // `flutter test` corre en la VM sin plugins nativos: sin esto,
    // LocalStorage (flutter_secure_storage) y FlutterLocalization
    // (shared_preferences) tiran MissingPluginException en main().
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    // google_fonts (app_theme.dart) cachea las fuentes en disco vía
    // path_provider, que tampoco tiene implementación en la VM.
    final fontsCache = Directory.systemTemp.createTempSync('turni_e2e_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => fontsCache.path,
    );

    // El binding de test reemplaza HttpClient por uno falso que responde 400
    // a todo: este e2e necesita pegarle de verdad a la API local.
    HttpOverrides.global = null;
  });

  testWidgets('recorre toda la pantalla de Configuración de punta a punta', (tester) async {
    // La superficie de test por default es 800x600: el layout desktop del
    // admin se desborda y deja botones (ej. "Guardar cambios") fuera de
    // pantalla, donde los tap() no llegan.
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await runClubConfigFlow(tester);
  });
}
