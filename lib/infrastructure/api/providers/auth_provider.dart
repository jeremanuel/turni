import 'package:dio/dio.dart';
import '../../../core/config/service_locator.dart';
import '../../../domain/entities/request/google_user_request.dart';
import '../../../domain/entities/user.dart';

class AuthProvider {
  final dioInstance = sl<Dio>();

  Future<User> login(GoogleUserRequest googleUserRequest) async {
    final data = {"google": googleUserRequest.toJson()};

    final response = await dioInstance.post("/user/signup", data: data);

    return User.fromJson(response.data);
  }

  Future<User?> validateToken(String token) async {
    try {
      final response = await dioInstance.post("/user/authenticate");

      return User.fromJson(response.data);
    } catch (error) {
      return null;
    }
  }

  Future<bool> registerDeviceToken(String token, String platform) async {
    try {
      await dioInstance.post(
        "/user/device-token",
        data: {"token": token, "platform": platform},
      );

      return true;
    } catch (error) {
      print('error registrando device token: $error');
      return false;
    }
  }

  Future<bool> unregisterDeviceToken(String token) async {
    try {
      await dioInstance.delete(
        "/user/device-token",
        data: {"token": token},
      );

      return true;
    } catch (error) {
      print('error dando de baja device token: $error');
      return false;
    }
  }
}
