import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/gym/gym.dart';
import '../../../domain/entities/gym/gym_progress.dart';
import '../../../domain/repositories/gym_repository.dart';

class GymRepositoryImpl implements GymRepository {
  final dioInstance = sl<Dio>();

  Future<RepositoryResponse<T>> _safeCall<T>(Future<T> Function() fn) async {
    try {
      return Either.right(await fn());
    } on DioException catch (err) {
      final response = err.response?.data;
      if (response == null) return Either.left(DomainError.unknownError());
      return Either.left(DomainError.fromErrorResponse(response));
    }
  }

  List<Routine> _routines(dynamic data) =>
      (data as List).map((row) => Routine.fromJson(row as Map<String, dynamic>)).toList();

  @override
  Future<RepositoryResponse<List<Routine>>> routines(int clientId) =>
      _safeCall(() async => _routines((await dioInstance.get('/gym/admin/clients/$clientId/routines')).data));

  @override
  Future<RepositoryResponse<List<Routine>>> recentRoutines() =>
      _safeCall(() async => _routines((await dioInstance.get('/gym/admin/recent-routines')).data));

  @override
  Future<RepositoryResponse<ExerciseCatalog>> catalog({int? clientId}) => _safeCall(() async {
        final response = await dioInstance.get(
          '/gym/admin/exercises',
          queryParameters: {if (clientId != null) 'client_id': clientId},
        );
        return ExerciseCatalog.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<RepositoryResponse<CatalogExercise>> createExercise(String name, List<int> muscleIds) => _safeCall(() async {
        final response = await dioInstance.post('/gym/admin/exercises', data: {'name': name, 'muscle_ids': muscleIds});
        return CatalogExercise.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<RepositoryResponse<Routine>> createRoutine(int clientId, Map<String, dynamic> body) => _safeCall(() async {
        final response = await dioInstance.post('/gym/admin/clients/$clientId/routines', data: body);
        return Routine.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<RepositoryResponse<Routine>> updateRoutine(String routineId, Map<String, dynamic> body) => _safeCall(() async {
        final response = await dioInstance.put('/gym/admin/routines/$routineId', data: body);
        return Routine.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<RepositoryResponse<RoutineProgress>> progress(String routineId) => _safeCall(() async {
        final response = await dioInstance.get('/gym/admin/routines/$routineId/progress');
        return RoutineProgress.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<RepositoryResponse<ClientGymSummary>> summary(int clientId) => _safeCall(() async {
        final response = await dioInstance.get('/gym/admin/clients/$clientId/summary');
        return ClientGymSummary.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<RepositoryResponse<void>> markFeedbackSeen(int clientId) =>
      _safeCall(() async {
        await dioInstance.post('/gym/admin/clients/$clientId/feedback/seen');
      });
}
