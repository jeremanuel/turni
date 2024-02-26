import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:turni/domain/entities/request/google_user_request.dart';
import 'package:turni/domain/entities/user.dart';
import 'package:turni/domain/repositories/auth_repository.dart';
import 'package:turni/infrastructure/api/providers/auth_provider.dart';

class AuthRepositoryImpl extends AuthRepository {

  final AuthProvider authProvider;

  AuthRepositoryImpl({required this.authProvider});

  @override
  Future login(User user) async {
    final responseData = GoogleUserRequest(id: user.socialId!, displayName: user.person!.name, email: user.person!.email, photoUrl: user.picture);
    authProvider.login(responseData);
  }

}
