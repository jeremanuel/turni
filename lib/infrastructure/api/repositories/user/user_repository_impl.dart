import 'package:dio/dio.dart';
import '../../../../core/config/service_locator.dart';
import '../../../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final dioInstance = sl<Dio>();

  @override
  Future<bool> resendVerificationCode(String numberPhone) {
    throw UnimplementedError();
  }

  @override
  Future<bool> sendVerificationCode(String numberPhone) async {
    try {
      final data = {"phone": numberPhone};
      final response = await dioInstance.post("/user/sendCode", data: data);

      print(response.toString());

      return response.data;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> verifyCode(String code) async {
    try {
      final data = {"code": code};
      final response = await dioInstance.post("/user/verify_code", data: data);

      print(response.toString());

      return response.data;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
