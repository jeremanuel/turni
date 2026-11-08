import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../../core/utils/entities/range_date.dart';
import '../../core/utils/repository_response.dart';
import '../entities/client.dart';
import '../entities/generic_search_item.dart';
import '../entities/payment/payment_method.dart';
import '../entities/request/page_response.dart';
import '../entities/session_request_settings.dart';

abstract class AdminRepository {
    Future<RepositoryResponse<PageResponse<Client>>> getClients(String search, [int? page, String? sortKey, bool? isAscending]);

    Future<RepositoryResponse<Client>> getClientById(int id);
    Future<List<GenericSearchItem>> genericSearch(String searchType, RangeDate rangeDate, int? clubPartitionId);
    Future<RepositoryResponse<Client>> createOrSaveClient(Map<String,dynamic> clientData);

    /// Reglas de las solicitudes del club del admin autenticado: cuánto
    /// espera una solicitud de turno y desde cuándo se puede pedir uno fijo.
    Future<Either<DomainError, SessionRequestSettings>> getSessionRequestSettings();

    Future<Either<DomainError, SessionRequestSettings>> updateSessionRequestSettings(SessionRequestSettings settings);

    /// Medios de pago para cobrar un turno (efectivo, transferencia, ...).
    Future<RepositoryResponse<List<PaymentMethod>>> getPaymentMethods();

    /// Guarda la nota libre del turno; vacía o null la borra. Devuelve la nota guardada.
    Future<RepositoryResponse<String?>> updateSessionObservation(int sessionId, String? observation);
}