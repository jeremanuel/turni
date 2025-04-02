import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/entities/range_date.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/generic_search_item.dart';
import '../../../domain/entities/request/page_response.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../providers/admin_provider.dart';
import 'base/base_repository.dart';

class AdminrepositroyImpl extends BaseRepository implements AdminRepository {

  final dioInstance = sl<Dio>();
  final AdminProvider adminProvider;

  AdminrepositroyImpl({required this.adminProvider});

  @override

  Future<Either<DomainError, PageResponse<Client>>> getClients(String search, [int? page, String? sortKey, bool? isAscending]) async {

    return safeCall(() => adminProvider.getClients(search, page));

  }

  @override
  Future<List<GenericSearchItem>> genericSearch(String searchType, RangeDate rangeDate, int? clubPartitionId) async {

    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

    final queryParameters = {
      "searchType":searchType, 
      "to":dateFormat.format(rangeDate.to!,), 
      "from": dateFormat.format(rangeDate.from!),
      "club_partition_id":clubPartitionId
    };

    final result = await dioInstance.get("/admin/search", queryParameters:queryParameters);

    List rawClients = result.data['clients'];

    List rawSessions = result.data['sessions'];
    
    final clientsResult = rawClients.map((rawClient) => GenericSearchItem.client(Client.fromJson(rawClient)),);
    final sessionsResult = rawSessions.map((rawSession) => GenericSearchItem.session(Session.fromJson(rawSession)),);

    
    return [...clientsResult, ...sessionsResult];

  }
  
  @override
  Future<RepositoryResponse<Client>> createOrSaveClient(Map<String, dynamic> clientData) {
    return safeCall(() async {
      final result = await dioInstance.post("/admin/saveClient", data: {"clientData": clientData});

      return Client.fromJson(result.data['client']);

    });

  }
}