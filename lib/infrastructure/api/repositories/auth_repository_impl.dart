import 'package:turni/domain/entities/request/google_user_request.dart';
import 'package:turni/domain/entities/user.dart';
import 'package:turni/domain/repositories/auth_repository.dart';
import 'package:turni/infrastructure/api/providers/auth_provider.dart';
import 'package:turni/infrastructure/localstorage/provider/local_storage.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthProvider authProvider;

  AuthRepositoryImpl({required this.authProvider});

  @override
  Future<User> login(User user) async {
    final reqData = GoogleUserRequest(
        id: user.socialId!,
        displayName: user.person!.name,
        email: user.person!.email,
        photoUrl: user.picture);

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
}
