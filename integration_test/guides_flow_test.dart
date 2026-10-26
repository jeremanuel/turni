import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'guides_flow.dart';

/// e2e de las guías en un Chrome real. El flujo vive en `guides_flow.dart`,
/// compartido con el runner de VM (`test/e2e/guides_flow_test.dart`). Cómo
/// correrlo (chromedriver en :4444 + `flutter drive`): ver
/// `club_config_flow_test.dart`.
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/guides_flow_test.dart -d chrome \
///     --dart-define=DEV_ADMIN_TOKEN=<token del seed:dev>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cada guía recorre todos sus pasos', (tester) async {
    await runGuidesFlow(tester);
  }, timeout: const Timeout(Duration(minutes: 30)));
}
