import 'package:dio/dio.dart';
import '../../../core/config/service_locator.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/request/page_response.dart';

class AdminProvider {
  final dioInstance = sl<Dio>();

  Future<PageResponse<Client>> getClients(String search, [int? page]) async {

    final response = await dioInstance.get("/admin/clients", queryParameters: {"search":search, "page":page});

    final clients = response.data['data'].map<Client>((el) => Client.fromJson(el)).toList();

    return PageResponse(response.data['total'], clients);

  }


}
