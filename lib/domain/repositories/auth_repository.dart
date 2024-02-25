import 'package:turni/domain/entities/user.dart';

abstract class AuthRepository {
  login(User user);
  
}