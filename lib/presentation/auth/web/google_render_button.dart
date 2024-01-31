import 'package:flutter/material.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/cubit/auth/auth_cubit.dart';

class GoogleRenderButton extends StatefulWidget {
  const GoogleRenderButton({super.key});

  @override
  State<GoogleRenderButton> createState() => _GoogleRenderButtonState();
}

class _GoogleRenderButtonState extends State<GoogleRenderButton> {
  final GoogleSignInPlugin _plugin = GoogleSignInPlatform.instance as GoogleSignInPlugin;

  @override
  void initState() {
    initializePlugin();
    super.initState();
  }

  initializePlugin() async {
    await _plugin.initWithParams(const SignInInitParameters(
      clientId:'745922452650-o1l0r76oaasjjhm60rjqj47gg64o9c82.apps.googleusercontent.com', // TODO: env var.
    ));

    _plugin.userDataEvents?.listen((GoogleSignInUserData? userData) {
      
      if(userData == null) return;
      
      sl<AuthCubit>().googleCallback(userData);


    });
  }



  @override
  Widget build(BuildContext context) {
    return _plugin.renderButton(
      configuration: GSIButtonConfiguration(
        locale: "es"
      )
    );
  }
}
