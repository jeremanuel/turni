part of 'auth_cubit.dart';

@immutable
class AuthState {

  final User? userCredential;
  final bool loadingAuthentication;


  const AuthState({
    required this.loadingAuthentication,
    this.userCredential
  });



List<Object?> get props => [userCredential, loadingAuthentication];
}

final class AuthInitial extends AuthState {

  const AuthInitial({
    super.loadingAuthentication = true
  });
  
}

final class AuthLogged extends AuthState {
  
  const AuthLogged({
    super.loadingAuthentication = false,
    super.userCredential
  });

}

final class AuthNotLogged extends AuthState {
  
  const AuthNotLogged({
    super.loadingAuthentication = false
  });

}

