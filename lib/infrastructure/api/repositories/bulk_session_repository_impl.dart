import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/bulk_sessions.dart';
import '../../../domain/repositories/bulk_session_repository.dart';
import 'base/base_repository.dart';

class BulkSessionRepositoryImpl extends BaseRepository implements BulkSessionRepository {
  final dioInstance = sl<Dio>();

  @override
  Future<RepositoryResponse<BulkPreview>> preview(
    BulkSessionFilters filters,
    BulkSessionAction action, {
    BulkPreviewView view = BulkPreviewView.all,
    int? limit,
  }) {
    return safeCall(() async {
      final response = await dioInstance.post(
        '/admin/sessions/bulk/preview',
        data: {
          'filters': filters.toJson(),
          'action': action.toJson(),
          'view': view.name,
          if (limit != null) 'limit': limit,
        },
      );
      return BulkPreview.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<BulkApplyResult>> apply(
    BulkSessionFilters filters,
    BulkSessionAction action,
  ) {
    return safeCall(() async {
      final response = await dioInstance.post(
        '/admin/sessions/bulk/apply',
        data: {'filters': filters.toJson(), 'action': action.toJson()},
      );
      return BulkApplyResult.fromJson(response.data as Map<String, dynamic>);
    });
  }
}
