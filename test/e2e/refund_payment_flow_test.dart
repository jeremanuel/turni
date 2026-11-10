import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turni/core/services/realtime/realtime_service.dart';

import '../../integration_test/refund_payment_flow.dart';

/// e2e de devolver un cobro de Mercado Pago sobre la VM de Dart (sin
/// navegador). El flujo vive en `integration_test/refund_payment_flow.dart`.
/// Necesita el backend con PAYMENT_PROVIDER_MOCK=true.
///
///   flutter test test/e2e/refund_payment_flow_test.dart \
///     --dart-define=DEV_ADMIN_TOKEN=$adminToken \
///     --dart-define=E2E_REFUND_SESSION_ID=$refundSessionId
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

  testWidgets('devolver un cobro de Mercado Pago en dos partes', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // La fuente de prueba de la VM es mucho más ancha que la real: sin esto,
    // el pie del panel se sale de la pantalla.
    tester.platformDispatcher.textScaleFactorTestValue = 0.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await runRefundPaymentFlow(tester);

    RealtimeService.instance.disconnect();
    await tester.pumpWidget(const SizedBox());
    // Vencen los keep-alive de las conexiones HTTP (hasta 15 s).
    await tester.pump(const Duration(seconds: 20));
  });
}
