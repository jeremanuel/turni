import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turni/data/repositories/auth_repository.dart';
import 'package:turni/domain/models/user.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> with ChangeNotifier {

  final authRepository = AuthRepository();

  AuthCubit() : super(const AuthInitial());


  void checkAuthStatus() {
/*     final user = FirebaseAuth.instance.currentUser;

    if(user == null){
      emit(const AuthNotLogged());
    }

    emit(AuthLogged(userCredential: user ));
 */    
    emit(AuthNotLogged());
    notifyListeners();
  }

  Future signInGoogle() async {
/*     UserCredential? userCred = await authRepository.signInGoogle();
  
    if(userCred == null) return;

    emit(AuthLogged(userCredential: userCred.user));
 */
    notifyListeners();
  }

  void signOutGoogle() async {
    
/*       await GoogleSignIn(
        clientId: kIsWeb ? "336678963982-6jcv4q55kckarab2ke8otrsos1kih8j0.apps.googleusercontent.com" : null
      ).signOut();
      await FirebaseAuth.instance.signOut();
      sl.resetLazySingleton(
        instance: sl<FeedCubit>()
      );
      emit(const AuthNotLogged());
 */      notifyListeners();
  }

    /// Funcion donde recibimos los datos de google de un usuario luego de logearse.
  void googleCallback(GoogleSignInUserData userData) async {
      print(userData.email);
      notifyListeners();
  }

  bool getLoadingStatus(){
    
    return state.loadingAuthentication;
  }
}
