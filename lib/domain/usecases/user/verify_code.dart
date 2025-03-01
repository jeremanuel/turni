import '../../repositories/user_repository.dart';

class VerifyCode {
  final UserRepository userRepository;

  VerifyCode(this.userRepository);

  Future<bool> excute(String code) async {
    bool verified = await userRepository.verifyCode(code);

    return verified;
  }
}
