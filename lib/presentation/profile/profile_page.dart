import 'package:flutter/material.dart';

import '../../core/config/service_locator.dart';
import '../core/cubit/auth/auth_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const whiteColor = Color.fromRGBO(249, 247, 254, 1);

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: MaterialButton(
            elevation: 0,
            color: whiteColor,
            height: 50,
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                color: whiteColor,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            onPressed: handleLogout,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Cerrar sesión",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Color.fromRGBO(159, 121, 242, 1),
                  ),
                ),
              ],
            )),
      ),
    );
  }

  void handleLogout() async {
    try {
      sl<AuthCubit>().signOutGoogle();
    } catch (error) {
      sl<AuthCubit>().emitError(error.toString());
    }
  }
}
