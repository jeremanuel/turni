import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/notification_history.dart';
import '../../../domain/repositories/notification_history_repository.dart';
import 'base/base_repository.dart';

class NotificationHistoryRepositoryImpl extends BaseRepository implements NotificationHistoryRepository {
  final dioInstance = sl<Dio>();

  @override
  Future<RepositoryResponse<List<NotificationHistoryEntry>>> getSessionNotifications(int sessionId) {
    return safeCall(() async {
      final response = await dioInstance.get('/admin/sessions/$sessionId/notifications');
      return sessionNotificationsFromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<ClientNotificationsPage>> getClientNotifications(int clientId, {String? cursor}) {
    return safeCall(() async {
      final response = await dioInstance.get(
        '/admin/clients/$clientId/notifications',
        queryParameters: {if (cursor != null) 'cursor': cursor},
      );
      return ClientNotificationsPage.fromJson(response.data as Map<String, dynamic>);
    });
  }
}
