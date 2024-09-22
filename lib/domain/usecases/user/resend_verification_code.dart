import '../../repositories/user_repository.dart';

class ResendVerificationCode {
  final UserRepository userRepository;

  ResendVerificationCode(this.userRepository);

  Future<bool> excute(String numberPhone) async {
    bool sended = await userRepository.resendVerificationCode(numberPhone);

    return sended;
  }
}
