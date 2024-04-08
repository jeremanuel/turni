import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/config/service_locator.dart';
import '../../core/cubit/auth/auth_cubit.dart';

class GoogleButton extends StatefulWidget {
  const GoogleButton({super.key});

  @override
  State<GoogleButton> createState() => _GoogleRenderButtonState();
}

class _GoogleRenderButtonState extends State<GoogleButton> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
      clientId:
          "458036544256-k5tqgq5mahdlcildhipsilshvs8cebcq.apps.googleusercontent.com");

  @override
  void initState() {
    super.initState();
  }

  void handleLogin() async {
    try {
      GoogleSignInAccount? signIn = await _googleSignIn.signIn();
      sl<AuthCubit>().googleCallback(GoogleSignInUserData(
          id: signIn!.id,
          email: signIn.email,
          displayName: signIn.displayName,
          photoUrl: signIn.photoUrl));
    } catch (error) {
      sl<AuthCubit>().emitError(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
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
}
