import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/entities/range_date.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/generic_search_item.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../providers/admin_provider.dart';

class AdminrepositroyImpl extends AdminRepository {

  final dioInstance = sl<Dio>();
  final AdminProvider adminProvider;

  AdminrepositroyImpl({required this.adminProvider});
  Future<List<Client>> getClients(String search) async {

    return adminProvider.getClients(search);

  }

  @override
  Future<List<GenericSearchItem>> genericSearch(String searchType, RangeDate rangeDate) async {

    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");


    final result = await dioInstance.get("/admin/search", queryParameters: {"searchType":searchType, "to":dateFormat.format(rangeDate.to!), "from": dateFormat.format(rangeDate.from!)});

    List rawClients = result.data['clients'];

    List rawSessions = result.data['sessions'];
    
    final clientsResult = rawClients.map((rawClient) => GenericSearchItem.client(Client.fromJson(rawClient)),);
    final sessionsResult = rawSessions.map((rawSession) => GenericSearchItem.session(Session.fromJson(rawSession)),);

    
    return [...clientsResult, ...sessionsResult];

  }
}