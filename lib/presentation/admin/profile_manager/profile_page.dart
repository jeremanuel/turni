import 'package:flutter/material.dart';
import '../../../core/config/service_locator.dart';
import '../../core/cubit/auth/auth_cubit.dart';

import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  final StatefulNavigationShell  child;
  const ProfilePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {


    return Row(
      children: [
        SizedBox(
          width: 200,
          child: NavigationRail(
            extended: true,
            leading: Padding(
              padding: const EdgeInsets.only(top: 20.0,),
              child: const Text("Ajustes"),
            ),
            elevation: 35,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            destinations: const [
              NavigationRailDestination(
                padding: EdgeInsets.all(25),
                icon: Icon(Icons.house),
                label: Text("Club"),
              ),
              NavigationRailDestination(
                padding: EdgeInsets.all(25),
                icon: Icon(Icons.security),
                label: Text("Usuarios"),
              ),
            ],
            selectedIndex: child.currentIndex,
            onDestinationSelected: (index) {
              child.goBranch(index);
            },
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  void handleLogout() async {
    try {
      sl<AuthCubit>().signOutGoogle();
    } catch (error) {
      sl<AuthCubit>().emitError(error.toString());
    }
  }
}
