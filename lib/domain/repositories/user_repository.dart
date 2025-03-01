abstract class UserRepository {
  Future<bool> sendVerificationCode(String numberPhone);
  Future<bool> verifyCode(String code);
  Future<bool> resendVerificationCode(String numberPhone);
}
