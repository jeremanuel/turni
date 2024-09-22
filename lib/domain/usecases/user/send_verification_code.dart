import '../../repositories/user_repository.dart';

class SendVerificationCode {
  final UserRepository userRepository;

  SendVerificationCode(this.userRepository);

  Future<bool> excute(String numberPhone) async {
    bool sended = await userRepository.sendVerificationCode(numberPhone);

    return sended;
  }
}
