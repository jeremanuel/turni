import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'cash_flow.dart';

/// e2e de la caja en un Chrome real. El flujo vive en `cash_flow.dart`,
/// compartido con el runner de VM (`test/e2e/cash_flow_test.dart`).
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/cash_flow_test.dart -d chrome \
///     --dart-define=DEV_ADMIN_TOKEN=$adminToken \
///     --dart-define=E2E_CASH_SESSION_ID=$cashSessionId \
///     --dart-define=E2E_CASH_SPACE_ID=$cashSpaceId
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('configurar puestos, abrir, cobrar, anular y cerrar con diferencia', (tester) async {
    await runCashFlow(tester);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
