import 'package:flutter/material.dart';
import '../../../core/config/service_locator.dart';
import '../../core/cubit/auth/auth_cubit.dart';

import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  final StatefulNavigationShell  child;
  const ProfilePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }

  void handleLogout() async {
    try {
      sl<AuthCubit>().signOutGoogle();
    } catch (error) {
      sl<AuthCubit>().emitError(error.toString());
    }
  }
}
