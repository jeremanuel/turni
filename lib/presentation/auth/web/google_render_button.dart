import 'package:flutter/material.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

class GoogleRenderButton extends StatefulWidget {
  const GoogleRenderButton({super.key});

  @override
  State<GoogleRenderButton> createState() => _GoogleRenderButtonState();
}

class _GoogleRenderButtonState extends State<GoogleRenderButton> {
  final GoogleSignInPlugin _plugin =
      GoogleSignInPlatform.instance as GoogleSignInPlugin;
  GoogleSignInUserData? _userData; // sign-in information?

  @override
  void initState() {
    initializePlugin();
    super.initState();
  }

  initializePlugin() async {
    await _plugin.initWithParams(const SignInInitParameters(
      clientId:
          '745922452650-o1l0r76oaasjjhm60rjqj47gg64o9c82.apps.googleusercontent.com', // TODO: env var.
    ));
    _plugin.userDataEvents?.listen((GoogleSignInUserData? userData) {
      print(userData);
      setState(() {
        _userData = userData;
      });
    });
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        _plugin.renderButton(),
        if(_userData != null) Text(_userData!.email)
        
      ],
    );
  }
}
