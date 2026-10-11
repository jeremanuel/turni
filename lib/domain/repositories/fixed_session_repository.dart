import '../../core/utils/repository_response.dart';
import '../entities/client_summary.dart';
import '../entities/fixed_session.dart';

/// Turnos fijos (`/admin/fixed-sessions`).
abstract class FixedSessionRepository {
  /// Del club; con [clientId], solo los de ese cliente (titular o integrante).
  Future<RepositoryResponse<List<FixedSession>>> list({int? clientId});

  Future<RepositoryResponse<List<FixedSessionOccurrence>>> preview(FixedSessionDraft draft);

  Future<RepositoryResponse<FixedSessionCreated>> create(FixedSessionDraft draft);

  Future<RepositoryResponse<FixedSession>> updateParticipants(int id, List<int> participantIds);

  /// Cancela un día ("YYYY-MM-DD"): ese horario queda libre y el fijo sigue.
  Future<RepositoryResponse<void>> cancelDay(int id, String date);

  /// Baja para siempre.
  Future<RepositoryResponse<void>> end(int id);

  /// Resumen de la ficha del cliente (indicadores, próximos turnos, actividad).
  Future<RepositoryResponse<ClientSummary>> clientSummary(int clientId);
}
