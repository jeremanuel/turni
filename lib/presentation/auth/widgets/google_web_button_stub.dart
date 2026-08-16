import 'package:flutter/material.dart';

/// Stub para plataformas no-web: `renderButton()` real vive en
/// `google_web_button_web.dart` (google_sign_in_web), que no compila fuera
/// de web. Nunca se llama en la práctica -- `GoogleButton` solo lo invoca
/// dentro de una rama `kIsWeb`.
Widget renderButton() {
  throw StateError('renderButton() solo debería llamarse en web');
}
