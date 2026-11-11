import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'fiscal_flow.dart';

/// e2e de la facturación con el simulador de ARCA en un Chrome real. El flujo
/// vive en `fiscal_flow.dart`, compartido con el runner de VM. Necesita el
/// backend con FISCAL_PROVIDER_MOCK=true.
///
///   chromedriver --port=4444
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/fiscal_flow_test.dart -d web-server --browser-name=chrome \
///     --dart-define=DEV_ADMIN_TOKEN=$adminToken \
///     --dart-define=E2E_FISCAL_SESSION_ID=$fiscalSessionId
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('facturar un cobro, corregir el rechazado y verlo autorizado', (tester) async {
    await runFiscalFlow(tester);
  });
}
