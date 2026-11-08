import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'fixed_requests_flow.dart';

/// e2e de los pedidos de turno fijo en un Chrome real. El flujo vive en
/// `fixed_requests_flow.dart`, compartido con el runner de VM.
///
///   chromedriver --port=4444
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/fixed_requests_flow_test.dart -d web-server --browser-name=chrome \
///     --dart-define=DEV_ADMIN_TOKEN=$adminToken \
///     --dart-define=E2E_CLIENT_TOKEN=$habitualToken
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('los pedidos llegan solos y el admin los responde', (tester) async {
    await runFixedRequestsFlow(tester);
  });
}
