import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;

/// Botón nativo de Google para Web (FedCM/GIS) -- Google no permite
/// restylear este botón más allá de las opciones que expone su SDK.
Widget renderButton() {
  return SizedBox(
    height: 48,
    width: double.infinity,
    child: web_only.renderButton(
      configuration: web_only.GSIButtonConfiguration(
        type: web_only.GSIButtonType.standard,
        theme: web_only.GSIButtonTheme.outline,
        shape: web_only.GSIButtonShape.pill,
        text: web_only.GSIButtonText.continueWith,
        size: web_only.GSIButtonSize.large,
        logoAlignment: web_only.GSIButtonLogoAlignment.left,
        locale: 'es',
        minimumWidth: 320,
      ),
    ),
  );
}
