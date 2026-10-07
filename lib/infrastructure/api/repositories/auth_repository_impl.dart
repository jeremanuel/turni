import '../../../domain/entities/request/google_user_request.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../../localstorage/provider/local_storage.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthProvider authProvider;

  AuthRepositoryImpl({required this.authProvider});

  @override
  Future<User> login(User user) async {
    final reqData = GoogleUserRequest(
      id: user.socialId!,
      displayName: user.person.fullName,
      email: user.person.email!,
      photoUrl: user.picture,
      idToken: user.googleIdToken,
    );

    return authProvider.login(reqData);
  }

  @override
  Future<User?> validateToken(String token) async {
    return await authProvider.validateToken(token);
  }

  @override
  Future saveToken(String token) {
    return LocalStorage.save(LocalStorage.TOKEN_KEY, token);
  }

  @override
  Future removeToken() {
    return LocalStorage.remove(LocalStorage.TOKEN_KEY);
  }

  @override
  Future<bool> registerDeviceToken(String token, String platform) {
    return authProvider.registerDeviceToken(token, platform);
  }

  @override
  Future<bool> unregisterDeviceToken(String token) {
    return authProvider.unregisterDeviceToken(token);
  }
}
