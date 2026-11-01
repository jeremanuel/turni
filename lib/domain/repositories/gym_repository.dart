import '../../core/utils/repository_response.dart';
import '../entities/gym/gym.dart';
import '../entities/gym/gym_progress.dart';

/// Rutinas de gimnasio de los clientes (`/gym/admin`).
abstract class GymRepository {
  /// Rutinas del cliente, la activa primero.
  Future<RepositoryResponse<List<Routine>>> routines(int clientId);

  /// Las últimas que armó el admin, para copiar a otro cliente.
  Future<RepositoryResponse<List<Routine>>> recentRoutines();

  /// Catálogo del club; con [clientId], cada ejercicio trae lo último que se le planificó.
  Future<RepositoryResponse<ExerciseCatalog>> catalog({int? clientId});

  /// Ejercicio nuevo en el catálogo del club (o el que ya existe con ese nombre).
  Future<RepositoryResponse<CatalogExercise>> createExercise(String name, List<int> muscleIds);

  /// Rutina nueva: la activa del cliente pasa a anteriores. [body]: `{start_date, groups}`.
  Future<RepositoryResponse<Routine>> createRoutine(int clientId, Map<String, dynamic> body);

  /// Edita una rutina (grupos y ejercicios con id se conservan con su historial).
  Future<RepositoryResponse<Routine>> updateRoutine(String routineId, Map<String, dynamic> body);

  /// Micro-progresos: cada cambio de series, reps o peso de cada ejercicio, con fecha y quién.
  Future<RepositoryResponse<RoutineProgress>> progress(String routineId);

  /// Card de rutina de la ficha del cliente.
  Future<RepositoryResponse<ClientGymSummary>> summary(int clientId);

  /// Marca como vistas las notas del cliente para el profe.
  Future<RepositoryResponse<void>> markFeedbackSeen(int clientId);
}
