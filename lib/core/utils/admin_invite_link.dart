import 'package:flutter/foundation.dart';

import '../config/environment.dart';

/// URL pública del panel, terminada en `/`. Sale de `ADMIN_WEB_URL`; en web,
/// si falta, se usa la URL actual.
String adminWebBaseUrl() {
  final configured = Environment.adminWebUrl;
  final base = configured ?? (kIsWeb ? '${Uri.base.origin}${Uri.base.path}' : '');
  return base.endsWith('/') ? base : '$base/';
}

/// Link que se comparte para sumar un admin. La app usa el hash como ruta
/// (`/#/invite/<token>`), así que el token va después del `#`.
String adminInviteLink(String token) => '${adminWebBaseUrl()}#/invite/$token';
