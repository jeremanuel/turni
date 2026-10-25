import '../../core/utils/repository_response.dart';
import '../entities/notification_history.dart';

/// Historial de avisos para soporte: qué se le mandó a quién y si llegó.
abstract class NotificationHistoryRepository {
  /// Todos los avisos del turno (a jugadores y a admins), los más nuevos primero.
  Future<RepositoryResponse<List<NotificationHistoryEntry>>> getSessionNotifications(int sessionId);

  /// Los avisos que recibió el cliente por este club. [cursor] es el
  /// `nextCursor` de la página anterior.
  Future<RepositoryResponse<ClientNotificationsPage>> getClientNotifications(int clientId, {String? cursor});
}
