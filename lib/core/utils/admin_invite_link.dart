import 'package:flutter/foundation.dart';

import '../config/environment.dart';

/// Link que se comparte para sumar un admin. La app usa el hash como ruta
/// (`/#/invite/<token>`), así que el token va después del `#`.
String adminInviteLink(String token) {
  final configured = Environment.adminWebUrl;
  final base = configured ?? (kIsWeb ? '${Uri.base.origin}${Uri.base.path}' : '');
  final normalized = base.endsWith('/') ? base : '$base/';
  return '$normalized#/invite/$token';
}
