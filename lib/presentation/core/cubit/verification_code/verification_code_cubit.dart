import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/usecases/user/send_verification_code.dart';
import '../../../../domain/usecases/user/verify_code.dart';
import '../../../../infrastructure/api/repositories/user/user_repository_impl.dart';

part 'verification_code_state.dart';

class VerificationCodeCubit extends Cubit<VerificationCodeState> {
  final sendVerificationCodeUseCase =
      SendVerificationCode(UserRepositoryImpl());
  final verifyCodeUseCase = VerifyCode(UserRepositoryImpl());
  VerificationCodeCubit() : super(VerificationCodeInitial(phoneNumber: ''));

  void updateCode(String inputCode) async {
    state.code.add(inputCode);

    if (state.code.length == state.lengthCode) {
      await verifyCode();
      state.code.clear();
    }
  }

  Future<bool> sendCode() async {
    bool sendOK = false;

    return sendOK;
  }

  Future<bool> verifyCode() async {
    final valid = await verifyCodeUseCase.excute(state.code.join());

    print(valid);

    return valid;
  }

  Future<bool> resendVerificationCode() async {
    bool sendOk = false;

    return sendOk;
  }
}
