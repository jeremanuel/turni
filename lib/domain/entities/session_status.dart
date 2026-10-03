/// Estados posibles de una [Session] en el flujo de solicitud/aprobación de
/// turno (ver `PLAN_SOLICITUD_TURNO.md`, Fase 0). `null` en el campo
/// `status` de `Session` significa "libre, nunca tuvo una solicitud" — los
/// estados terminales (`rejected`/`cancelled`/`expired`) se conservan como
/// historial aunque el backend ya haya liberado `client_id`.
enum SessionStatus {
  pending,
  confirmed,
  rejected,
  cancelled,
  expired;

  /// Valor tal cual lo devuelve/espera el backend (enum `session_status` de
  /// Prisma), ej. `"PENDING"`.
  String get apiValue {
    switch (this) {
      case SessionStatus.pending:
        return 'PENDING';
      case SessionStatus.confirmed:
        return 'CONFIRMED';
      case SessionStatus.rejected:
        return 'REJECTED';
      case SessionStatus.cancelled:
        return 'CANCELLED';
      case SessionStatus.expired:
        return 'EXPIRED';
    }
  }

  static SessionStatus? fromApiValue(dynamic value) {
    if (value == null) return null;

    switch (value.toString()) {
      case 'PENDING':
        return SessionStatus.pending;
      case 'CONFIRMED':
        return SessionStatus.confirmed;
      case 'REJECTED':
        return SessionStatus.rejected;
      case 'CANCELLED':
        return SessionStatus.cancelled;
      case 'EXPIRED':
        return SessionStatus.expired;
      default:
        return null;
    }
  }
}

/// Funciones estáticas para usar con `@JsonKey(fromJson:, toJson:)` sobre el
/// campo `status` de [Session] — mismo patrón que `ValueTransformers`
/// (`lib/core/utils/value_transformers.dart`).
class SessionStatusTransformers {
  static SessionStatus? fromJson(dynamic value) =>
      SessionStatus.fromApiValue(value);

  static String? toJson(SessionStatus? status) => status?.apiValue;
}
