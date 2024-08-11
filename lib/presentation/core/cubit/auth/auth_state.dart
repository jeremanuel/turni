part of 'auth_cubit.dart';


class AuthState {
  final User? userCredential;
  final bool loadingAuthentication;
  final String? error;
  
  const AuthState(
      {required this.loadingAuthentication, this.userCredential, this.error});

  List<Object?> get props => [userCredential, loadingAuthentication];
}

final class AuthInitial extends AuthState {
  const AuthInitial({super.loadingAuthentication = true});
}

final class AuthIsLoading extends AuthState {
  const AuthIsLoading({
    super.loadingAuthentication = true,
  });
}

final class AuthLogged extends AuthState {
  const AuthLogged({super.loadingAuthentication = false, super.userCredential});
}

final class AuthNotLogged extends AuthState {
  const AuthNotLogged({super.loadingAuthentication = false});
}

final class AuthError extends AuthState {
  const AuthError({super.error, super.loadingAuthentication = false});
}
