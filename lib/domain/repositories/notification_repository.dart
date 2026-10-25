import '../../core/utils/repository_response.dart';
import '../entities/admin_notification.dart';

/// Bandeja de avisos del admin, de su club activo (`/notifications?app=admin`).
abstract class NotificationRepository {
  /// Los más nuevos primero. [cursor] es el `nextCursor` de la página anterior.
  Future<RepositoryResponse<AdminNotificationPage>> getNotifications({String? cursor});

  Future<RepositoryResponse<int>> getUnreadCount();

  Future<RepositoryResponse<bool>> markRead(String notificationId);

  Future<RepositoryResponse<int>> markAllRead();
}
