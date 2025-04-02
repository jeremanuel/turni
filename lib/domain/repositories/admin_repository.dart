import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../../core/utils/entities/range_date.dart';
import '../../core/utils/repository_response.dart';
import '../entities/client.dart';
import '../entities/generic_search_item.dart';
import '../entities/request/page_response.dart';

abstract class AdminRepository {
    Future<RepositoryResponse<PageResponse<Client>>> getClients(String search, [int? page, String? sortKey, bool? isAscending]);
    Future<List<GenericSearchItem>> genericSearch(String searchType, RangeDate rangeDate, int? clubPartitionId);
    Future<RepositoryResponse<Client>> createOrSaveClient(Map<String,dynamic> clientData);
}