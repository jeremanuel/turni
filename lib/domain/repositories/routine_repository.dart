import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../../core/utils/repository_response.dart';
import '../entities/routine/routine.dart';

abstract class RoutineRepository {
  /// Obtiene todas las rutinas de un usuario específico
  Future<RepositoryResponse> getClientRoutines(int clientId);

  /// Obtiene las últimas rutinas creadas (limitadas por quantity)
  Future<RepositoryResponse> getLastRoutines({int quantity = 10});
}