import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'club_config_flow.dart';

/// e2e de "Configuración" en un Chrome real y visible. El flujo en sí vive
/// en `club_config_flow.dart`, compartido con el runner de VM
/// (`test/e2e/club_config_flow_test.dart`).
///
/// En web NO se puede usar `flutter test -d chrome` ("Web devices are not
/// supported for integration tests yet"): va por `flutter drive`, que
/// necesita chromedriver (de la MISMA versión que Chrome, bajado de
/// https://googlechromelabs.github.io/chrome-for-testing/) escuchando en el
/// puerto 4444. Sin él, `flutter drive` queda colgado sin dar error.
///
///   chromedriver --port=4444
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/club_config_flow_test.dart -d chrome \
///     --dart-define=DEV_ADMIN_TOKEN=<token del seed:dev>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('recorre toda la pantalla de Configuración de punta a punta', (tester) async {
    await runClubConfigFlow(tester);
  });
}
