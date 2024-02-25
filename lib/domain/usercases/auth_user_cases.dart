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
  Future login(User user)  {

    return authRepository.login(user);

  }


}