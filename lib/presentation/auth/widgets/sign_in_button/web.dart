import 'package:flutter/material.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import '../../../../core/config/service_locator.dart';
import '../../../core/cubit/auth/auth_cubit.dart';

final GoogleSignInPlugin _plugin =
    GoogleSignInPlatform.instance as GoogleSignInPlugin;

void initializeState() async {
  await _plugin.initWithParams(const SignInInitParameters(
    clientId:
        "745922452650-o1l0r76oaasjjhm60rjqj47gg64o9c82.apps.googleusercontent.com",
  ));

  _plugin.userDataEvents?.listen((GoogleSignInUserData? userData) {
    if (userData == null) return;

    sl<AuthCubit>().googleCallback(userData);
  });
}

Widget buildButton() {
  return Container(
    child: _plugin.renderButton(
      configuration: GSIButtonConfiguration(
        locale: "es",
        text: GSIButtonText.signin,
        size: GSIButtonSize.large,
        shape: GSIButtonShape.pill,
        theme: GSIButtonTheme.outline,
        type: GSIButtonType.standard,
        logoAlignment: GSIButtonLogoAlignment.center,
        minimumWidth: 250,
      ),
    ),
  );
}
