import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Versión del servidor para la que ya se recargó en esta pestaña. Si después
/// de recargar el CDN todavía sirve el build viejo, no se recarga de nuevo
/// (se reintenta la próxima vez que se abra la app).
const _reloadedForKey = 'turni_reloaded_for_version';

Future<void> ensureLatest(String current) async {
  try {
    final url = Uri.base.resolve('assets/.env.production').replace(
      queryParameters: {'v': DateTime.now().millisecondsSinceEpoch.toString()},
    );
    final response = await web.window
        .fetch(url.toString().toJS, web.RequestInit(cache: 'no-store'))
        .toDart;
    if (!response.ok) return;

    final server = _parseVersion((await response.text().toDart).toDart);
    final storage = web.window.sessionStorage;
    if (server == null || server == current) {
      storage.removeItem(_reloadedForKey);
      return;
    }
    if (storage.getItem(_reloadedForKey) == server) return;

    storage.setItem(_reloadedForKey, server);
    web.window.location.reload();
  } catch (error) {
    debugPrint('[version] No se pudo chequear la versión: $error');
  }
}

String? _parseVersion(String env) {
  for (final line in env.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('VERSION=')) {
      final value = trimmed.substring('VERSION='.length).replaceAll('"', '').trim();
      return value.isEmpty ? null : value;
    }
  }
  return null;
}
