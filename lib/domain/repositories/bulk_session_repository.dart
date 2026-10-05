import '../../core/utils/repository_response.dart';
import '../entities/bulk_sessions.dart';

/// Vista previa de la vista de turnos que [BulkSessionRepository.preview] devuelve.
enum BulkPreviewView { all, excluded }

abstract class BulkSessionRepository {
  /// [limit] null = todas las filas.
  Future<RepositoryResponse<BulkPreview>> preview(
    BulkSessionFilters filters,
    BulkSessionAction action, {
    BulkPreviewView view = BulkPreviewView.all,
    int? limit,
  });

  Future<RepositoryResponse<BulkApplyResult>> apply(
    BulkSessionFilters filters,
    BulkSessionAction action,
  );
}
