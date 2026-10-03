import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(User user);

  Future<User?> validateToken(String token);

  Future saveToken(String token);

  Future removeToken();

  /// Registra el token de FCM del dispositivo contra el backend
  /// (`POST /user/device-token`). Devuelve `false` en cualquier error
  /// (no debe bloquear el flujo de login).
  Future<bool> registerDeviceToken(String token, String platform);

  /// Da de baja el token de FCM del dispositivo (`DELETE
  /// /user/device-token`), típicamente en logout. Devuelve `false` en
  /// cualquier error (no debe bloquear el logout).
  Future<bool> unregisterDeviceToken(String token);
}