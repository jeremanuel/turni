import 'package:dio/dio.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/domain/entities/request/google_user_request.dart';
import 'package:turni/domain/entities/user.dart';

class AuthProvider {
  final dioInstance = sl<Dio>();

  Future<User> login(GoogleUserRequest googleUserRequest) async {
    final data = {"google": googleUserRequest.toJson()};

    final response = await dioInstance.post("/user/signup", data: data);

    return User.fromJson(response.data);
  }

  Future<User?> validateToken(String token) async {
    final response = await dioInstance.post("/user/authenticate");

    return User.fromJson(response.data);
  }
}
