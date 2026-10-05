import '../../core/utils/repository_response.dart';
import '../entities/club_map/club_map.dart';
import '../entities/club_map/court_usage.dart';

/// Plano del club del admin autenticado. Ver `turni_mono_be`,
/// `GET`/`PUT /admin/club-map`.
abstract class ClubMapRepository {
  Future<RepositoryResponse<ClubMapView>> getClubMap();

  /// Reemplaza el plano: las canchas que no vengan quedan sin ubicar. Si el
  /// plano no es válido, el error trae el motivo para mostrarle al admin.
  Future<RepositoryResponse<ClubMapView>> saveClubMap(ClubMapLayout layout);

  /// Uso de cada cancha en los últimos [days] días, hoy incluido
  /// (`GET /admin/club-map/usage`).
  Future<RepositoryResponse<CourtUsageView>> getCourtUsage({required int days});
}
