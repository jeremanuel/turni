import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(User user);

  Future<User?> validateToken(String token);

  Future saveToken(String token);
  
  Future removeToken();
}