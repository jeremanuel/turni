part of 'verification_code_cubit.dart';

sealed class VerificationCodeState {
  List<String> code = List.of([]);
  final int lengthCode = 4;
  final int retrytime = 60;
  final String phoneNumber;
  bool loading = true;
  bool invalid = false;

  VerificationCodeState({required this.phoneNumber});
}

final class VerificationCodeInitial extends VerificationCodeState {
  VerificationCodeInitial({loading = true, required phoneNumber})
      : super(phoneNumber: '');
}
