import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:turni/domain/entities/user.dart';
import 'package:turni/domain/repositories/auth_repository.dart';
import 'package:turni/infrastructure/api/providers/auth_provider.dart';

class AuthRepositoryImpl extends AuthRepository {

  final AuthProvider authProvider;

  AuthRepositoryImpl({required this.authProvider});

  @override
  login(User user) {
    authProvider.login(user);
  }

}
