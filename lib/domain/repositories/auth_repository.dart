import 'package:turni/domain/entities/user.dart';

abstract class AuthRepository {
  Future login(User user);
  
}