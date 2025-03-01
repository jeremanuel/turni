import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/service_locator.dart';
import '../cubit/verification_code/verification_code_cubit.dart';

class VerificationCode extends StatelessWidget {
  late final VerificationCodeCubit verificationCodeCubit;

  VerificationCode({super.key}) {
    verificationCodeCubit = sl<VerificationCodeCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VerificationCodeCubit, VerificationCodeState>(
        bloc: verificationCodeCubit,
        builder: (context, state) {
          return Scaffold(
            body: Container(
              padding: const EdgeInsets.all(50),
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(189, 163, 246, 1),
                  Color.fromRGBO(103, 43, 234, 1)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height / 3 - 40.0,
                        bottom: 40.0),
                    child: const Column(
                      children: [
                        Text(
                          "Código de verificación",
                          style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Hemos enviado un código a tu celular.",
                          style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 14.0,
                              fontWeight: FontWeight.normal),
                        ),
                        Text(
                          "Necesario para validar tu identidad",
                          style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 1),
                              fontSize: 14.0,
                              fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  Form(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InputOneChar(),
                        InputOneChar(),
                        InputOneChar(),
                        InputOneChar(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  const Text(
                    true ? "Código invalido" : "",
                    style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontSize: 18.0,
                        fontWeight: FontWeight.normal),
                  )
                ],
              ),
            ),
          );
        });
  }
}

class InputOneChar extends StatelessWidget {
  late final VerificationCodeCubit verificationCodeCubit;

  InputOneChar({super.key}) {
    verificationCodeCubit = sl<VerificationCodeCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VerificationCodeCubit, VerificationCodeState>(
      bloc: verificationCodeCubit,
      builder: (context, state) {
        return SizedBox(
          height: 68,
          width: 64,
          child: TextFormField(
            autofocus: true,
            showCursor: false,
            onSaved: (value) {},
            onChanged: (value) {
              if (value.length == 1) {
                verificationCodeCubit.updateCode(value.characters.toString());
                FocusScope.of(context).nextFocus();
              } else {
                FocusScope.of(context).previousFocus();
              }
            },
            decoration: InputDecoration(
              counter: const Offstage(),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  width: 2,
                  color: Color.fromRGBO(189, 163, 246, 1),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  width: 2,
                  color: Color.fromRGBO(123, 66, 247, 1),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        );
      },
    );
  }
}
