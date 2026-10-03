import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/config/service_locator.dart';
import '../../core/cubit/auth/auth_cubit.dart';

Widget buildGoogleSignInButton() => const _GoogleMobileButton();

class _GoogleMobileButton extends StatefulWidget {
  const _GoogleMobileButton();

  @override
  State<_GoogleMobileButton> createState() => _GoogleMobileButtonState();
}

class _GoogleMobileButtonState extends State<_GoogleMobileButton> {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  late final Future<void> _initializeGoogleSignIn;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    final clientId = Environment.googleClientId.trim();
    _initializeGoogleSignIn = _googleSignIn.initialize(
      clientId: clientId.isEmpty || clientId.startsWith('KEY ')
          ? null
          : clientId,
    );
  }

  Future<void> handleLogin() async {
    if (_isSigningIn) {
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      await _initializeGoogleSignIn;
      final GoogleSignInAccount signIn = await _googleSignIn.authenticate();

      if (!mounted) {
        return;
      }

      sl<AuthCubit>().googleCallback(
        GoogleSignInUserData(
          id: signIn.id,
          email: signIn.email,
          displayName: signIn.displayName,
          photoUrl: signIn.photoUrl,
        ),
      );
    } on GoogleSignInException catch (error) {
      sl<AuthCubit>().emitError(error.description ?? error.toString());
    } catch (error) {
      sl<AuthCubit>().emitError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const whiteColor = Color.fromRGBO(249, 247, 254, 1);
    const String googleLogo = 'assets/img/google_logo.svg';

    return MaterialButton(
      elevation: 0,
      color: whiteColor,
      height: 50,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: whiteColor),
        borderRadius: BorderRadius.circular(40),
      ),
      onPressed: _isSigningIn ? null : handleLogin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            googleLogo,
            semanticsLabel: 'Logo de Google',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 10),
          const Text(
            'Iniciar sesión',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color.fromRGBO(159, 121, 242, 1),
            ),
          ),
        ],
      ),
    );
  }
}
