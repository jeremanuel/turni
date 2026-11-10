import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'refund_payment_flow.dart';

/// e2e de devolver un cobro de Mercado Pago en un Chrome real. El flujo vive
/// en `refund_payment_flow.dart`, compartido con el runner de VM. Necesita el
/// backend con PAYMENT_PROVIDER_MOCK=true.
///
///   chromedriver --port=4444
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/refund_payment_flow_test.dart -d web-server --browser-name=chrome \
///     --dart-define=DEV_ADMIN_TOKEN=$adminToken \
///     --dart-define=E2E_REFUND_SESSION_ID=$refundSessionId
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('devolver un cobro de Mercado Pago en dos partes', (tester) async {
    await runRefundPaymentFlow(tester);
  });
}
