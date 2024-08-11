import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/utils/dio_init.dart';
import 'package:turni/domain/entities/user.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:turni/domain/usercases/auth_user_cases.dart';
import 'package:turni/infrastructure/localstorage/provider/local_storage.dart';

import '../../../../core/utils/entities/coordinate.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> with ChangeNotifier {
  final AuthUserCases authUserCases;
  String? initialRoute;

  AuthCubit(this.authUserCases) : super(const AuthInitial());

  Future<Position> getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      Future.error('Permisos no aceptados');
    }

    return Geolocator.getCurrentPosition();
  }

  void checkAuthStatus() async {
    final String? token = await LocalStorage.read(LocalStorage.TOKEN_KEY);

    if (token != null) {
      await DioInit.addTokenToInterceptor(sl<Dio>(), token);

      emit(const AuthIsLoading());

      final user = await authUserCases.validateToken(token);

      if (user != null) {
        Position position = await getCurrentPosition();
        Coordinate location = Coordinate(
          latitud: position.latitude,
          longitud: position.longitude,
        );

        user.location = location;

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
    await authUserCases.logout();
    notifyListeners();
  }

  /// Funcion donde recibimos los datos de google de un usuario luego de logearse.
  void googleCallback(GoogleSignInUserData userData) async {
    final user = User.fromGoogleSignInUserData(userData);

    final completeUser = await authUserCases.login(user);

    emit(AuthLogged(userCredential: completeUser));

    notifyListeners();
  }

  void emitError(String error) async {
    emit(AuthError(error: error));
    notifyListeners();
  }

  bool getLoadingStatus() {
    return state.loadingAuthentication;
  }

  bool isAdmin() {
    return state.userCredential?.isAdmin ?? false;
  }

/*   void setInitialRoute(String? route){
    state.initialRoute = route;
  } */
}
