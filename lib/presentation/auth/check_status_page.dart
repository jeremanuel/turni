
import 'package:flutter/material.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';

class AuthCheck extends StatelessWidget {

   final authCubit = sl<AuthCubit>();
   
  AuthCheck({super.key}){
    WidgetsBinding.instance.addPostFrameCallback((timeStamp){
      authCubit.checkAuthStatus();
    },);
  }
 

  @override
  Widget build(BuildContext context) {
    return Center(
            child: TextButton(onPressed: () {
              authCubit.checkAuthStatus();
            }, child:  Text("data")),
        );
  }
}