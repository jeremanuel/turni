import 'package:flutter/foundation.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/repositories/admin_repository.dart';

/// Minutos que tiene el admin para aprobar una solicitud de turno antes de
/// que venza (config del club). Se pide una sola vez y lo comparten todas las
/// cards "pendiente" de la agenda; null mientras no se sabe (la card muestra
/// "Solicitud pendiente" sin el "vence en…").
class PendingRequestTtl {
  PendingRequestTtl._();

  static final ValueNotifier<int?> minutes = ValueNotifier<int?>(null);
  static bool _requested = false;

  static void ensureLoaded() {
    if (_requested || !sl.isRegistered<AdminRepository>()) return;
    _requested = true;
    sl<AdminRepository>().getPendingRequestTtlMinutes().then((result) {
      if (result case Right(:final value)) minutes.value = value;
    });
  }

  /// "vence en 42 min", "vence en 1 h 5 min", "vencida".
  static String? expiresLabel(DateTime createdAt, {DateTime? now}) {
    final ttl = minutes.value;
    if (ttl == null) return null;
    final left = createdAt.add(Duration(minutes: ttl)).difference(now ?? DateTime.now()).inMinutes;
    if (left <= 0) return 'vencida';
    if (left < 60) return 'vence en $left min';
    final hours = left ~/ 60;
    final rest = left % 60;
    return rest == 0 ? 'vence en $hours h' : 'vence en $hours h $rest min';
  }
}
