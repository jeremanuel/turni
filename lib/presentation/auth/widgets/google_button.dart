import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/config/service_locator.dart';
import '../../core/cubit/auth/auth_cubit.dart';
import 'google_web_button.dart' as web_button;

class GoogleButton extends StatefulWidget {
  const GoogleButton({super.key});

  @override
  State<GoogleButton> createState() => _GoogleRenderButtonState();
}

class _GoogleRenderButtonState extends State<GoogleButton> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize(
        clientId: Environment.googleClientId,
        // El plugin de Google para Web rechaza serverClientId (ver
        // google_sign_in_web GoogleSignInPlugin.init: "serverClientId is
        // not supported on Web").
        serverClientId: kIsWeb ? null : Environment.googleClientId,
      );
      // En web, GoogleSignIn.instance.authenticate() no está implementado
      // (Google exige su propio botón vía renderButton -- ver
      // google_web_button.dart) y el resultado del login solo llega por este
      // stream, nunca como valor de retorno de un método. En mobile también
      // se escucha acá (en vez de leer el resultado de `authenticate()`
      // directo) para tener un único camino de manejo de sesión en ambas
      // plataformas, igual que recomienda el ejemplo oficial del paquete.
      GoogleSignIn.instance.authenticationEvents
          .listen(_handleAuthenticationEvent)
          .onError(_handleAuthenticationError);
      setState(() {
        _isInitialized = true;
      });
    } catch (error) {
      sl<AuthCubit>().emitError(
          'Error al inicializar Google Sign-In: ${error.toString()}');
    }
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      final account = event.user;
      sl<AuthCubit>().googleCallback(GoogleSignInUserData(
          id: account.id,
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl));
    }
  }

  void _handleAuthenticationError(Object error) {
    sl<AuthCubit>().emitError(error.toString());
  }

  void handleLogin() async {
    if (!_isInitialized) {
      sl<AuthCubit>().emitError('Google Sign-In no está inicializado');
      return;
    }

    try {
      // El resultado se procesa en _handleAuthenticationEvent (stream).
      await GoogleSignIn.instance.authenticate(
        scopeHint: [
          "https://www.googleapis.com/auth/user.phonenumbers.read",
          "https://www.googleapis.com/auth/userinfo.email"
        ],
      );
    } catch (error) {
      sl<AuthCubit>().emitError(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    const whiteColor = Color.fromRGBO(249, 247, 254, 1);
    const String googleLogo = 'assets/img/google_logo.svg';

    // Web no soporta el flujo imperativo de authenticate(): hay que usar el
    // botón que renderiza el propio SDK de Google (popup/FedCM), y el login
    // llega por el stream de authenticationEvents ya suscripto arriba.
    // supportsAuthenticate() no puede llamarse hasta que initialize() haya
    // resuelto -- si no, el plugin lanza un Bad state.
    if (_isInitialized && !GoogleSignIn.instance.supportsAuthenticate()) {
      if (kIsWeb) {
        return web_button.renderButton();
      }
      return const Text('Este dispositivo no soporta iniciar sesión con Google');
    }

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
        onPressed: _isInitialized ? handleLogin : null,
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
            Text(
              _isInitialized ? "Iniciar sesión" : "Cargando...",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(159, 121, 242, 1),
              ),
            ),
          ],
        ));
  }
}
