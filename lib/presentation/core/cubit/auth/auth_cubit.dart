import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/dio_init.dart';
import '../../../../domain/entities/user.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import '../../../../domain/usercases/auth_user_cases.dart';
import '../../../../infrastructure/localstorage/provider/local_storage.dart';

import '../../../admin/states/global_data/global_data_cubit.dart';

import '../../../../core/services/push_notification_service.dart';
import '../../../../core/utils/entities/coordinate.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> with ChangeNotifier {
  final AuthUserCases authUserCases;
  String? initialRoute;

  AuthCubit(this.authUserCases) : super(const AuthInitial());

  /// Coordenada de referencia usada cuando no se puede obtener una
  /// ubicación real (permiso denegado, timeout, sin soporte del navegador).
  /// Sin esto, un admin que no otorga el permiso de geolocalización (o cuyo
  /// entorno nunca resuelve el prompt, como un emulador/navegador sin
  /// interacción) queda trabado indefinidamente en el login. Mismo valor
  /// que el fallback de `turni_client` (Tandil, Buenos Aires) — si se
  /// cambia acá, cambiar allá también.
  static final _fallbackPosition = Position(
    latitude: -37.3217,
    longitude: -59.1332,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  /// Notifica a los listeners (incluye el `refreshListenable` de GoRouter)
  /// y además fuerza un refresh explícito del router — mismo fix que
  /// `turni_client`: el cambio de estado a veces viene de un callback
  /// externo (stream de Google Sign-In) y `notifyListeners()` solo no
  /// siempre alcanza para que GoRouter reevalúe su `redirect` a tiempo.
  void _notifyRouter() {
    notifyListeners();
    if (sl.isRegistered<GoRouter>()) {
      sl<GoRouter>().refresh();
    }
  }

  Future<Position> getCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 5));

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 8));
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallbackPosition;
      }

      return await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      return _fallbackPosition;
    }
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

        sl<GlobalDataCubit>();

        _registerPushToken();
      } else {
        authUserCases.logout();
        emit(const AuthNotLogged());
      }
    } else {
      authUserCases.logout();
      emit(const AuthNotLogged());
    }

    _notifyRouter();
  }

  Future signInGoogle() async {
    emit(const AuthLogged());
    sl<GlobalDataCubit>();
    _notifyRouter();
  }

  void signOutGoogle() async {
    await _unregisterPushToken();
    await GoogleSignIn.instance.signOut();

    emit(const AuthNotLogged());
    await authUserCases.logout();
    _notifyRouter();
  }

  /// Funcion donde recibimos los datos de google de un usuario luego de logearse.
  void googleCallback(GoogleSignInUserData userData, {String? idToken}) async {
    final user = User.fromGoogleSignInUserData(userData, idToken: idToken);

    final User completeUser;
    try {
      completeUser = await authUserCases.login(user);
    } catch (error) {
      // Ej. el backend rechazó el id_token de Google (401). Sin esto el login
      // quedaba colgado, sin mensaje.
      final data = error is DioException ? error.response?.data : null;
      final message = data is Map && data['error'] is String
          ? data['error'] as String
          : 'No se pudo iniciar sesión. Probá de nuevo.';
      emitError(message);
      return;
    }

    // Sin esto, cualquier request autenticado hecho después de este login
    // (incluido el registro del device token de push) sale sin header
    // `Authorization` y tira 401 — el interceptor de Dio solo se arma acá o
    // en `checkAuthStatus()` (con el token guardado en un arranque previo),
    // nunca de forma automática. Mismo fix ya aplicado en turni_client.
    if (completeUser.token != null) {
      await DioInit.addTokenToInterceptor(sl<Dio>(), completeUser.token!);
    }

    emit(AuthLogged(userCredential: completeUser));

    sl<GlobalDataCubit>();

    _notifyRouter();

    _registerPushToken();
  }

  /// Pide permiso de notificaciones, obtiene el token FCM y lo registra
  /// contra el backend. Sin credenciales reales de Firebase (o sin permiso
  /// otorgado) esto es un no-op silencioso: nunca bloquea ni rompe el login.
  Future<void> _registerPushToken() async {
    try {
      final token = await PushNotificationService.getToken();

      if (token == null) return;

      await authUserCases.registerDeviceToken(
        token,
        PushNotificationService.currentPlatform(),
      );
    } catch (error) {
      // No-op: el registro de push nunca debe bloquear el login.
    }
  }

  /// Da de baja el token de FCM del dispositivo en logout. No-op silencioso
  /// ante cualquier error.
  Future<void> _unregisterPushToken() async {
    try {
      final token = await PushNotificationService.getToken();

      if (token == null) return;

      await authUserCases.unregisterDeviceToken(token);
    } catch (error) {
      // No-op: el logout nunca debe bloquear por esto.
    }
  }

  /// Vuelve a pedir el usuario al backend sin pasar por la pantalla de carga
  /// (ej. después de aceptar una invitación de admin, cambia su rol).
  Future<void> refreshUser() async {
    final String? token = await LocalStorage.read(LocalStorage.TOKEN_KEY);
    if (token == null) return;

    final user = await authUserCases.validateToken(token);
    if (user == null) return;

    user.location = state.userCredential?.location;
    emit(AuthLogged(userCredential: user));
    _notifyRouter();
  }

  /// Cierra sesión y, al volver a entrar, abre [route] (ej. el link de
  /// invitación, para aceptarlo con otra cuenta o con un login verificado).
  void signOutAndReturnTo(String route) {
    initialRoute = route;
    signOutGoogle();
  }

  void emitError(String error) async {
    emit(AuthError(error: error));
    _notifyRouter();
  }

  bool getLoadingStatus() {
    return state.loadingAuthentication;
  }

  bool isAdmin() {
    return state.userCredential?.isAdmin ?? false;
  }

  /// Permisos del admin logueado (ver [Permissions]).
  bool can(String permission) => state.userCredential?.adminAccess?.can(permission) ?? false;

  bool canAny(Iterable<String> permissions) =>
      state.userCredential?.adminAccess?.canAny(permissions) ?? false;

  /// Admin deshabilitado por otro admin del club: no puede usar la app.
  bool isDisabledAdmin() => state.userCredential?.adminAccess?.active == false;

  int getClubId() {
    return state.userCredential!.admin!.clubPartitions.first.club_id;
  }

  /*   void setInitialRoute(String? route){
    state.initialRoute = route;
  } */
}
