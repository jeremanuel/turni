import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/repositories/platform_repository.dart';

class PlatformRepositoryImpl implements PlatformRepository {
  final dioInstance = sl<Dio>();

  @override
  Future<RepositoryResponse<CreatedClub>> createClub({
    required String clubName,
    required String name,
    String lastName = '',
    required String email,
  }) async {
    try {
      final response = await dioInstance.post('/platform/clubs', data: {
        'club_name': clubName,
        'name': name,
        'last_name': lastName,
        'email': email,
      });
      return Either.right(CreatedClub.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (err) {
      final response = err.response?.data;
      if (response == null) return Either.left(DomainError.unknownError());
      return Either.left(DomainError.fromErrorResponse(response));
    }
  }
}
