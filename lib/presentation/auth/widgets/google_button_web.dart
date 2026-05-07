import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/web_only.dart' as web_sign_in;

import '../../../../core/config/environment.dart';
import '../../../../core/config/service_locator.dart';
import '../../core/cubit/auth/auth_cubit.dart';

Widget buildGoogleSignInButton() => const _GoogleWebButton();

class _GoogleWebButton extends StatefulWidget {
  const _GoogleWebButton();

  @override
  State<_GoogleWebButton> createState() => _GoogleWebButtonState();
}

class _GoogleWebButtonState extends State<_GoogleWebButton> {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  late final Future<void> _initializeGoogleSignIn;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final clientId = Environment.googleClientId.trim();
    _initializeGoogleSignIn = _googleSignIn.initialize(
      clientId: clientId.isEmpty || clientId.startsWith('KEY ')
          ? null
          : clientId,
    );

    _initializeGoogleSignIn.then((_) {
      _authSubscription = _googleSignIn.authenticationEvents.listen(
        _handleAuthenticationEvent,
        onError: (Object error, StackTrace stackTrace) {
          if (!mounted) {
            return;
          }
          sl<AuthCubit>().emitError(error.toString());
        },
      );
    });
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    if (!mounted) {
      return;
    }

    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(:final user):
        sl<AuthCubit>().googleCallback(
          GoogleSignInUserData(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoUrl,
          ),
        );
      case GoogleSignInAuthenticationEventSignOut():
        break;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeGoogleSignIn,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return web_sign_in.renderButton();
      },
    );
  }
}
