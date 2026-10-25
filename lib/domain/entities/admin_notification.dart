/// Un aviso de la bandeja del admin (`GET /notifications?app=admin`): lo
/// mismo que llegó (o habría llegado) por push, guardado en el backend. Solo
/// los de su club (ver `turni_mono_be/docs/feature/NOTIFICATIONS.md`).
class AdminNotification {
  /// Id del aviso. Es un BigInt en el backend: viaja como string.
  final String id;

  /// Tipo del catálogo del backend (`SESSION_REQUESTED`, `SESSION_DEPOSIT_PAID`...).
  final String type;

  /// `SESSION`, `PAYMENT`, `TOURNAMENT` o `GYM`.
  final String category;
  final String title;
  final String body;

  /// Los ids de lo que cambió, como en el `data` del push.
  final Map<String, String> data;
  final DateTime? readAt;
  final DateTime createdAt;

  const AdminNotification({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AdminNotification(
      id: '${json['notification_id']}',
      type: json['type'] as String? ?? '',
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: data is Map ? data.map((key, value) => MapEntry('$key', '$value')) : const {},
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String).toLocal() : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  AdminNotification markedRead(DateTime at) => AdminNotification(
        id: id,
        type: type,
        category: category,
        title: title,
        body: body,
        data: data,
        readAt: readAt ?? at,
        createdAt: createdAt,
      );
}

/// Una página de la bandeja. [nextCursor] es null en la última.
class AdminNotificationPage {
  final List<AdminNotification> notifications;
  final String? nextCursor;

  const AdminNotificationPage({required this.notifications, this.nextCursor});

  factory AdminNotificationPage.fromJson(Map<String, dynamic> json) => AdminNotificationPage(
        notifications: (json['notifications'] as List? ?? const [])
            .map((item) => AdminNotification.fromJson(item as Map<String, dynamic>))
            .toList(),
        nextCursor: json['next_cursor'] as String?,
      );
}
