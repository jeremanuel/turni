import 'package:turni/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login(User user);


  Future saveToken(String token);
  
}