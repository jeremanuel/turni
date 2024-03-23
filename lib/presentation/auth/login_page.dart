import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'widgets/web/google_button_web.dart';
import '../../core/config/service_locator.dart';
import '../core/cubit/auth/auth_cubit.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final authCubit = sl<AuthCubit>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(50),
        decoration: backgroundColor,
        child: Center(
          child: Column(
            children: [
              buildHeader(),
              const SizedBox(height: 20),
              buildBackgroundImage(),
              const Spacer(),
              buildGoogleButton()
            ],
          ),
        ),
      ),
    );
  }

  final BoxDecoration backgroundColor = const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color.fromRGBO(189, 163, 246, 1),
        Color.fromRGBO(103, 43, 234, 1)
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  Widget buildHeader() {
    const String logotype = 'assets/img/logotype_white.svg';

    return SvgPicture.asset(
      logotype,
      semanticsLabel: 'Logo de la app de Turni',
      width: 138,
      height: 46,
    );
  }

  Widget buildBackgroundImage() {
    const String backgroundIsotype = 'assets/img/isotype_login.svg';

    return SizedBox(
        height: 100,
        width: 100,
        child: OverflowBox(
          maxWidth: 600,
          maxHeight: 600,
          alignment: Alignment.topCenter,
          child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color.fromRGBO(
                    205, 185, 248, 0.18), // Establece la opacidad aquí
                BlendMode.srcIn,
              ),
              child: SvgPicture.asset(
                backgroundIsotype,
                excludeFromSemantics: true,
                height: 1200,
                width: 1200,
              )),
        ));
  }

  Widget buildGoogleButtonMobile() {
    const whiteColor = Color.fromRGBO(249, 247, 254, 1);

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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Iniciar sesión",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Color.fromRGBO(159, 121, 242, 1),
            ),
          ),
        ],
      ),
      onPressed: () async {
        await authCubit.signInGoogle();
      },
    );
  }

  Widget buildGoogleButtonWeb() {
    return const GoogleButtonWeb();
  }

  Widget buildGoogleButton() {
    return Container(
        margin: const EdgeInsets.only(bottom: 70),
        child: kIsWeb ? buildGoogleButtonWeb() : buildGoogleButtonMobile());
  }
}
