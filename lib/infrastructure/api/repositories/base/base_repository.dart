import 'package:dio/dio.dart';

import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/repository_response.dart';

class BaseRepository {
  Future<RepositoryResponse<T>> safeCall<T>(Future<T> Function() getDataFunction) async {

    try {
      final data = await getDataFunction();

      return Either.right(data);

    } on DioException catch (err) {
      final errorResponse = err.response?.data;

      if(errorResponse == null){
        return Either.left(DomainError.unknownError());
      }

      return Either.left(DomainError.fromErrorResponse(errorResponse));
    }

      
  
  }
}