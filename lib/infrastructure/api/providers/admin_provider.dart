import 'package:dio/dio.dart';
import '../../../core/config/service_locator.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/request/google_user_request.dart';
import '../../../domain/entities/user.dart';

class AdminProvider {
  final dioInstance = sl<Dio>();

  Future<List<Client>> getClients(String search) async {

    try{
      final response = await dioInstance.get("/admin/clients", queryParameters: {"search":search});

      final values = response.data.map<Client>((el) => Client.fromJson(el)).toList();

      print(values);

      return values;

    }catch(e){
      print(e);
      return [];
    }

  }


}
