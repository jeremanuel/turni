import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/client_summary.dart';
import '../../../domain/entities/fixed_session.dart';
import '../../../domain/repositories/fixed_session_repository.dart';

class FixedSessionRepositoryImpl implements FixedSessionRepository {
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

  @override
  Future<RepositoryResponse<List<FixedSession>>> list({int? clientId}) {
    return _safeCall(() async {
      final response = await dioInstance.get(
        '/admin/fixed-sessions',
        queryParameters: {if (clientId != null) 'client_id': clientId},
      );
      return (response.data as List).map((row) => FixedSession.fromJson(row as Map<String, dynamic>)).toList();
    });
  }

  @override
  Future<RepositoryResponse<List<FixedSessionOccurrence>>> preview(FixedSessionDraft draft) {
    return _safeCall(() async {
      final response = await dioInstance.post('/admin/fixed-sessions/preview', data: draft.toJson());
      return ((response.data as Map<String, dynamic>)['occurrences'] as List)
          .map((row) => FixedSessionOccurrence.fromJson(row as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<RepositoryResponse<FixedSessionCreated>> create(FixedSessionDraft draft) {
    return _safeCall(() async {
      final response = await dioInstance.post('/admin/fixed-sessions', data: draft.toJson());
      return FixedSessionCreated.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<FixedSession>> updateParticipants(int id, List<int> participantIds) {
    return _safeCall(() async {
      final response = await dioInstance.put(
        '/admin/fixed-sessions/$id/participants',
        data: {'participant_ids': participantIds},
      );
      return FixedSession.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<void>> cancelDay(int id, String date) {
    return _safeCall(() async {
      await dioInstance.post('/admin/fixed-sessions/$id/cancel-day', data: {'date': date});
    });
  }

  @override
  Future<RepositoryResponse<void>> end(int id) {
    return _safeCall(() async {
      await dioInstance.delete('/admin/fixed-sessions/$id');
    });
  }

  @override
  Future<RepositoryResponse<ClientSummary>> clientSummary(int clientId) {
    return _safeCall(() async {
      final response = await dioInstance.get('/admin/clients/$clientId/summary');
      return ClientSummary.fromJson(response.data as Map<String, dynamic>);
    });
  }
}
