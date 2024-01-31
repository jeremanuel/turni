import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/cubit/auth/auth_cubit.dart';
import 'package:turni/core/presentation/input/custom_outlined_button.dart';
import 'package:turni/presentation/auth/web/google_render_button.dart';

class AuthLogin extends StatelessWidget {

  AuthLogin({super.key});

  final authCubit = sl<AuthCubit>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Image.asset("assets/img/logo1.png"),
          const SizedBox(
            height: 50,
          ),
          const  Center(child: Text("Bienvenido", style: TextStyle(fontSize: 25))),
          const SizedBox(
            height: 50,
          ),
         const GoogleRenderButton()
          //buildGoogleButton(context),
        
        ],
      ),
    );
  }

  CustomOutlinedButton buildGoogleButton(context) {

    return CustomOutlinedButton(
      child: Row(
            
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 30,
                width: 30,
                child: Image.network('http://pngimg.com/uploads/google/google_PNG19635.png', fit: BoxFit.cover),
              ),
              const SizedBox(width: 15),
              const Text("Entra con Google", style: TextStyle(color: Colors.black87)),                          
            ],
          ),
      onPressed:() async {
            await authCubit.signInGoogle();
          },
    );

  }
}


