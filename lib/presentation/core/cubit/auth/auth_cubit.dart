import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/utils/dio_init.dart';
import 'package:turni/domain/entities/user.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:turni/domain/usercases/auth_user_cases.dart';
import 'package:turni/infrastructure/localstorage/provider/local_storage.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> with ChangeNotifier {

  final AuthUserCases authUserCases;

  AuthCubit(this.authUserCases) : super(const AuthInitial());

  void checkAuthStatus() async {

    final String? token = await LocalStorage.read(LocalStorage.TOKEN_KEY);

    if (token != null) {

      await DioInit.addTokenToInterceptor(sl<Dio>(), token);
      
      emit(const AuthIsLoading());
      
      final user = await authUserCases.validateToken(token);

      if( user != null ){

        authUserCases.login(user);
        emit(AuthLogged(userCredential: user));

      } else {

        authUserCases.logout();
        emit(const AuthNotLogged());

      }

    } else {
      
      authUserCases.logout();
      emit(const AuthNotLogged());
      
    }

    notifyListeners();

  }

  Future signInGoogle() async {
    emit(const AuthLogged());
    notifyListeners();
  }

  void signOutGoogle() async {

    emit(const AuthNotLogged());
    notifyListeners();
  }

  /// Funcion donde recibimos los datos de google de un usuario luego de logearse.
  void googleCallback(GoogleSignInUserData userData) async {

    final user = User.fromGoogleSignInUserData(userData);

    // await authUserCases.login(user);

    emit(AuthLogged(userCredential: user));

    notifyListeners();

  }

  bool getLoadingStatus() {
    return state.loadingAuthentication;
  }

  bool isAdmin(){
    return /* state.userCredential?.isAdmin() ?? */ false;
  }
}


/* 
Scrollbar(
              thumbVisibility: true,
              controller: horizontalController,
              child: SingleChildScrollView(
                controller: horizontalController,
                physics: const AlwaysScrollableScrollPhysics(),
              
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: widget.columnWidth.toDouble() * widget.physicalPartitions.length,                   
                   child: Stack(
                    children: [
                      linesList(),                      
                      cardsLists(context),
                    ],
                  ), 
                ),
              ),
            ),
 */
