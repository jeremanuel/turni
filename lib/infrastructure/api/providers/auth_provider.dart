import 'package:dio/dio.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/domain/entities/request/google_user_request.dart';
import 'package:turni/domain/entities/user.dart';

class AuthProvider {
   
  Future login(GoogleUserRequest googleUserRequest) async {


    final dioInstance = sl<Dio>();

    final data = {
      "google": googleUserRequest.toJson()
    };

    final response = await dioInstance.post("/user/signup", data: data);
    return response.data;

  }
}