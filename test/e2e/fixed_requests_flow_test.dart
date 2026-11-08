import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turni/core/services/realtime/realtime_service.dart';

import '../../integration_test/fixed_requests_flow.dart';

/// e2e de los pedidos de turno fijo sobre la VM de Dart (sin navegador). El
/// flujo vive en `integration_test/fixed_requests_flow.dart`.
///
///   flutter test test/e2e/fixed_requests_flow_test.dart \
///     --dart-define=DEV_ADMIN_TOKEN=$adminToken \
///     --dart-define=E2E_CLIENT_TOKEN=$habitualToken
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

  testWidgets('los pedidos llegan solos y el admin los responde', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await runFixedRequestsFlow(tester);

    RealtimeService.instance.disconnect();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
