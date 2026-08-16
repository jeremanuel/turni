import 'package:turni/domain/entities/user.dart';
import 'package:turni/domain/repositories/auth_repository.dart';

class AuthUserCases {
  final AuthRepository authRepository;

  AuthUserCases(this.authRepository);

  /**
  * @brief User case para logear a un usuario
  * @author Jeremias Manuel
  */
  ///
  Future<User> login(User user) async {
    final loggedUser = await authRepository.login(user);

    await authRepository.saveToken(loggedUser.token!);

    return loggedUser;
  }

  Future logout() async {
    await authRepository.removeToken();
  }

  Future<User?> validateToken(String token) async {
    final loggedUser = await authRepository.validateToken(token);

    return loggedUser;
  }

  /// No-op silencioso ante cualquier falla (p. ej. sin Firebase real
  /// configurado todavía) — nunca debe bloquear el login.
  Future<bool> registerDeviceToken(String token, String platform) {
    return authRepository.registerDeviceToken(token, platform);
  }

  /// No-op silencioso ante cualquier falla — nunca debe bloquear el logout.
  Future<bool> unregisterDeviceToken(String token) {
    return authRepository.unregisterDeviceToken(token);
  }
}
