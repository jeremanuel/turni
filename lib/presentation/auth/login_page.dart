import 'package:flutter/material.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';
import 'package:turni/presentation/core/input/custom_outlined_button.dart';
import 'package:turni/presentation/auth/widgets/web/google_button_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final authCubit = sl<AuthCubit>();

  final String logotype = 'assets/img/isotipo.png';
  final String backgroundIsotype = 'assets/img/test.svg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            color: const Color.fromRGBO(33, 150, 243, 0.1),
            child: Center(
                child: Column(children: [
              SvgPicture.asset(
                logotype,
                semanticsLabel: '',
                width: 500,
                height: 500,
              ),
              SvgPicture.asset(
                backgroundIsotype,
                semanticsLabel: '',
                width: 50,
                height: 50,
              ),
              buildGoogleButton(context)
            ]))));
  }

  Widget buildGoogleButton(context) {
    if (kIsWeb) {
      return const GoogleButtonWeb();
    }

    return CustomOutlinedButton(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 30,
            width: 30,
            child: Image.network(
                'http://pngimg.com/uploads/google/google_PNG19635.png',
                fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
          const Text("Entra con Google",
              style: TextStyle(color: Colors.black87)),
        ],
      ),
      onPressed: () async {
        await authCubit.signInGoogle();
      },
    );
  }
}
