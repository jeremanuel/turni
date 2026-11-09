import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'void_payment_flow.dart';

/// e2e de anular cobros en un Chrome real. El flujo vive en
/// `void_payment_flow.dart`, compartido con el runner de VM.
///
///   chromedriver --port=4444
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/void_payment_flow_test.dart -d web-server --browser-name=chrome \
///     --dart-define=DEV_ADMIN_TOKEN=$adminToken \
///     --dart-define=E2E_VOID_SESSION_ID=$voidPanelSessionId
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('anular un cobro y eliminar un turno cobrado', (tester) async {
    await runVoidPaymentFlow(tester);
  });
}
