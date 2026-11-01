// Historial de avisos de un turno o de un cliente
// (`GET /admin/sessions/:id/notifications`, `GET /admin/clients/:id/notifications`):
// qué se mandó, a quién y si llegó. Ver
// `turni_mono_be/docs/feature/NOTIFICATIONS.md`.

/// Estado de una entrega, como lo guarda el backend.
enum DeliveryStatus { pending, sent, partial, failed, skipped, unknown }

DeliveryStatus _status(String? value) => switch (value) {
      'PENDING' => DeliveryStatus.pending,
      'SENT' => DeliveryStatus.sent,
      'PARTIAL' => DeliveryStatus.partial,
      'FAILED' => DeliveryStatus.failed,
      'SKIPPED' => DeliveryStatus.skipped,
      _ => DeliveryStatus.unknown,
    };

DateTime? _date(Object? value) => value is String ? DateTime.parse(value).toLocal() : null;

/// Un intento de entrega por canal (push o email), después del último intento.
class NotificationDelivery {
  /// `PUSH` o `EMAIL`.
  final String channel;
  final DeliveryStatus status;
  final int attempts;

  /// Dispositivos (o direcciones) intentados en el último intento, y a cuántos llegó.
  final int targets;
  final int succeeded;
  final String? lastError;
  final DateTime? sentAt;

  /// Cuándo se reintenta; null si no se reintenta más.
  final DateTime? nextAttemptAt;

  const NotificationDelivery({
    required this.channel,
    required this.status,
    required this.attempts,
    required this.targets,
    required this.succeeded,
    this.lastError,
    this.sentAt,
    this.nextAttemptAt,
  });

  bool get isEmail => channel == 'EMAIL';

  factory NotificationDelivery.fromJson(Map<String, dynamic> json) => NotificationDelivery(
        channel: json['channel'] as String? ?? 'PUSH',
        status: _status(json['status'] as String?),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        targets: (json['targets'] as num?)?.toInt() ?? 0,
        succeeded: (json['succeeded'] as num?)?.toInt() ?? 0,
        lastError: json['last_error'] as String?,
        sentAt: _date(json['sent_at']),
        nextAttemptAt: _date(json['next_attempt_at']),
      );
}

/// Un aviso a un destinatario.
class NotificationHistoryEntry {
  /// Id del aviso. Es un BigInt en el backend: viaja como string.
  final String id;
  final String type;

  /// `SESSION`, `PAYMENT`, `TOURNAMENT`, `GYM` o `ACCOUNT`.
  final String category;
  final String title;
  final String body;
  final int? sessionId;

  /// El cliente en este club, para abrir su ficha. Null en los avisos a admins.
  final int? recipientClientId;
  final String? recipientName;

  /// `CLIENT` o `ADMIN`: en qué app lo recibió.
  final String recipientApp;

  /// Cuándo lo leyó en la bandeja de la app.
  final DateTime? readAt;
  final DateTime createdAt;

  /// Vacío si las entregas ya se borraron (el backend las guarda 30 días).
  final List<NotificationDelivery> deliveries;

  const NotificationHistoryEntry({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    required this.recipientApp,
    required this.createdAt,
    this.sessionId,
    this.recipientClientId,
    this.recipientName,
    this.readAt,
    this.deliveries = const [],
  });

  bool get isForAdmin => recipientApp == 'ADMIN';

  factory NotificationHistoryEntry.fromJson(Map<String, dynamic> json) {
    final recipient = json['recipient'] is Map ? json['recipient'] as Map<String, dynamic> : const <String, dynamic>{};
    return NotificationHistoryEntry(
      id: '${json['notification_id']}',
      type: json['type'] as String? ?? '',
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      sessionId: (json['session_id'] as num?)?.toInt(),
      recipientClientId: (recipient['client_id'] as num?)?.toInt(),
      recipientName: recipient['name'] as String?,
      recipientApp: recipient['app'] as String? ?? 'CLIENT',
      readAt: _date(json['read_at']),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      deliveries: (json['deliveries'] as List? ?? const [])
          .map((item) => NotificationDelivery.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

List<NotificationHistoryEntry> _entries(Object? list) =>
    (list as List? ?? const []).map((item) => NotificationHistoryEntry.fromJson(item as Map<String, dynamic>)).toList();

/// Una página del historial de un cliente. [nextCursor] es null en la última.
class ClientNotificationsPage {
  /// false si el cliente no tiene cuenta en la app: no le llegan avisos.
  final bool hasAppAccount;
  final List<NotificationHistoryEntry> notifications;
  final String? nextCursor;

  const ClientNotificationsPage({required this.hasAppAccount, required this.notifications, this.nextCursor});

  factory ClientNotificationsPage.fromJson(Map<String, dynamic> json) => ClientNotificationsPage(
        hasAppAccount: json['has_app_account'] as bool? ?? true,
        notifications: _entries(json['notifications']),
        nextCursor: json['next_cursor'] as String?,
      );
}

/// Los avisos de un turno.
List<NotificationHistoryEntry> sessionNotificationsFromJson(Map<String, dynamic> json) => _entries(json['notifications']);
