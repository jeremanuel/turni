import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/admin_notification.dart';
import '../../../domain/repositories/notification_repository.dart';
import 'base/base_repository.dart';

/// Siempre con `app=admin`: la bandeja del cliente es de la otra app.
class NotificationRepositoryImpl extends BaseRepository implements NotificationRepository {
  final dioInstance = sl<Dio>();

  static const _path = '/notifications';
  static const _app = {'app': 'admin'};

  @override
  Future<RepositoryResponse<AdminNotificationPage>> getNotifications({String? cursor}) {
    return safeCall(() async {
      final response = await dioInstance.get(_path, queryParameters: {..._app, if (cursor != null) 'cursor': cursor});
      return AdminNotificationPage.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<int>> getUnreadCount() {
    return safeCall(() async {
      final response = await dioInstance.get('$_path/unread-count', queryParameters: _app);
      return (response.data['unread'] as num?)?.toInt() ?? 0;
    });
  }

  @override
  Future<RepositoryResponse<bool>> markRead(String notificationId) {
    return safeCall(() async {
      await dioInstance.post('$_path/$notificationId/read', queryParameters: _app);
      return true;
    });
  }

  @override
  Future<RepositoryResponse<int>> markAllRead() {
    return safeCall(() async {
      final response = await dioInstance.post('$_path/read-all', queryParameters: _app);
      return (response.data['updated'] as num?)?.toInt() ?? 0;
    });
  }
}
