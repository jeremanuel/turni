import 'package:dio/dio.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/domain/entities/user.dart';

class AuthProvider {
   
  Future login(User user) async {


    final dioInstance = sl<Dio>();

    final response = await dioInstance.get("/client/save");

    return response.data;

  }
}