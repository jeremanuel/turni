import 'package:flutter/material.dart';

import 'sign_in_button.dart';

class GoogleButton extends StatefulWidget {
  const GoogleButton({super.key});

  @override
  State<GoogleButton> createState() => _GoogleRenderButtonState();
}

class _GoogleRenderButtonState extends State<GoogleButton> {

  @override
  void initState() {
    initializeState();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => buildButton();
}
