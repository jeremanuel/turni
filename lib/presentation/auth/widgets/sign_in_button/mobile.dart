import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import '../../../../core/config/service_locator.dart';
import '../../../core/cubit/auth/auth_cubit.dart';
import 'package:google_sign_in/google_sign_in.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(
  serverClientId:
      "745922452650-kerr7drlkptsnmq46ua55dngi3jnb6r0.apps.googleusercontent.com",
);

void initializeState() async {}

void handleLogin() async {
  print("hello");
  try {
    GoogleSignInAccount? signIn = await _googleSignIn.signIn();
    print("suiccs");
  } catch (error) {
    print("error");
    print(error);
  }

  _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
    print("listen");
    sl<AuthCubit>().googleCallback(GoogleSignInUserData(
        id: account!.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl));
  });
}

Widget buildButton() {
  const whiteColor = Color.fromRGBO(249, 247, 254, 1);

  return MaterialButton(
      elevation: 0,
      color: whiteColor,
      height: 50,
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          color: whiteColor,
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      onPressed: handleLogin,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Iniciar sesión",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Color.fromRGBO(159, 121, 242, 1),
            ),
          ),
        ],
      ));
}
