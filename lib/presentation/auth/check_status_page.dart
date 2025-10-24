
import 'package:flutter/material.dart';
import '../../core/config/service_locator.dart';
import '../core/cubit/auth/auth_cubit.dart';

class AuthCheck extends StatelessWidget {

   final authCubit = sl<AuthCubit>();
   
  AuthCheck({super.key}){
    WidgetsBinding.instance.addPostFrameCallback((timeStamp){
      authCubit.checkAuthStatus();
    },);
  }
 

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
              child: CircularProgressIndicator(),
          ),
    );
  }
}