import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../core/cubit/auth/auth_cubit.dart';

void initializeState() async {}

Widget buildButton() {
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
        await sl<AuthCubit>().signInGoogle();
      });
}
