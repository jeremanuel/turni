import 'package:flutter/material.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import '../../../../core/config/service_locator.dart';
import '../../../core/cubit/auth/auth_cubit.dart';

class GoogleButtonWeb extends StatefulWidget {
  const GoogleButtonWeb({super.key});

  @override
  State<GoogleButtonWeb> createState() => _GoogleRenderButtonState();
}

class _GoogleRenderButtonState extends State<GoogleButtonWeb> {
  final GoogleSignInPlugin _plugin =
      GoogleSignInPlatform.instance as GoogleSignInPlugin;

  @override
  void initState() {
    initializePlugin();
    super.initState();
  }

  initializePlugin() async {
    await _plugin.initWithParams(const SignInInitParameters(
      clientId:
          "745922452650-o1l0r76oaasjjhm60rjqj47gg64o9c82.apps.googleusercontent.com",
    ));

    _plugin.userDataEvents?.listen((GoogleSignInUserData? userData) {
      if (userData == null) return;

      sl<AuthCubit>().googleCallback(userData);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          minimumWidth: 250),
    ));
  }
}
