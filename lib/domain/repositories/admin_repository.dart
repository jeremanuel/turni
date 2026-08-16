import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../../core/utils/entities/range_date.dart';
import '../entities/client.dart';
import '../entities/generic_search_item.dart';

abstract class AdminRepository {
    Future<List<Client>> getClients(String search);
    Future<List<GenericSearchItem>> genericSearch(String searchType, RangeDate rangeDate, int? clubPartitionId);

    /// Minutos configurados en `club.pending_request_ttl_minutes` (TTL de
    /// las solicitudes de turno pendientes) del club del admin autenticado.
    Future<Either<DomainError, int>> getPendingRequestTtlMinutes();

    Future<Either<DomainError, int>> updatePendingRequestTtlMinutes(int minutes);
}