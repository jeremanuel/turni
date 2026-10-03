import 'package:flutter/material.dart';
import 'google_button_mobile.dart'
    if (dart.library.html) 'google_button_web.dart';

class GoogleButton extends StatefulWidget {
  const GoogleButton({super.key});

  @override
  State<GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<GoogleButton> {
  @override
  Widget build(BuildContext context) {
    return buildGoogleSignInButton();
  }
}
