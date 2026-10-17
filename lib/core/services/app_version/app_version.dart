import 'package:flutter/foundation.dart';

import 'app_version_check_stub.dart'
    if (dart.library.js_interop) 'app_version_check_web.dart' as platform;

/// Versión del build, para forzar la actualización de la app web.
///
/// El build de Render genera un número nuevo en cada deploy (fecha y hora,
/// `AAAAMMDDhhmmss`) y lo deja en dos lugares:
/// - compilado en la app con `--dart-define=VERSION=...` ([current]);
/// - en `assets/.env.production` (clave `VERSION`), el archivo que sirve el
///   servidor.
///
/// Al abrir la app se comparan los dos: si el servidor tiene otro número, la
/// app que está corriendo es un build viejo (caché del navegador o del CDN) y
/// se recarga. El número tiene que venir compilado y no del `.env`: ese
/// archivo puede llegar nuevo aunque el código cacheado sea el viejo.
class AppVersion {
  AppVersion._();

  static const String current = String.fromEnvironment('VERSION');

  /// Lo que se muestra en la app. "dev" en builds locales (sin `VERSION`).
  /// En web, con el compilador a la derecha: W = WebAssembly, J = JavaScript.
  static String get label {
    final version = current.isEmpty ? 'dev' : current;
    if (!kIsWeb) return version;
    return '$version ${kIsWasm ? 'W' : 'J'}';
  }

  /// Recarga la app si el servidor tiene una versión más nueva. No-op fuera
  /// de web o sin versión compilada. Nunca tira.
  static Future<void> ensureLatest() async {
    if (current.isEmpty) return;
    await platform.ensureLatest(current);
  }
}
