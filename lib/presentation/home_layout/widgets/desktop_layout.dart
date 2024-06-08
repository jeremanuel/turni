import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';

class DesktopLayout extends StatelessWidget {

  final StatefulNavigationShell child;

  const DesktopLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body:  Padding(
        padding:const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
                       
            const SizedBox(width: 20,),
            SideBar(child: child),
            const SizedBox(width: 20,),

            Expanded(
              child: Material(
                borderRadius: BorderRadius.circular(16),
                elevation: 25,
                child: child,
              ),
            ),
            const SizedBox(width: 20,),

          ],
        ),
      ),
    );

  }
}

class SideBar extends StatelessWidget {

  final StatefulNavigationShell child;

  const SideBar({
    super.key, 
    required this.child,
  });

  @override
  Widget build(BuildContext context) {


    return NavigationRail(
      onDestinationSelected: (index) => child.goBranch(index),
      labelType: NavigationRailLabelType.none,
      elevation: 25,
      groupAlignment: 0,
      destinations: buildRails(),
      selectedIndex: child.currentIndex
      );

  }

  List<NavigationRailDestination> buildRails() {

    final isAdmin = sl<AuthCubit>().isAdmin();

    if(!isAdmin) {
      return const [
      NavigationRailDestination(
        padding: EdgeInsets.all(25),
        icon: Icon(Icons.dashboard), 
        label: Text("feed")
        ),
        NavigationRailDestination(
        padding: EdgeInsets.all(25),
        icon: Icon(Icons.person), 
        label: Text("Perfil")
        )
    ];
    }

    return const [
      NavigationRailDestination(
        padding: EdgeInsets.all(25),
        icon: Icon(Icons.dashboard), 
        label: Text("Dashboard")
        ),
        NavigationRailDestination(
        padding: EdgeInsets.all(25),
        icon: Icon(Icons.calendar_month), 
        label: Text("Turnos")
        ),
        NavigationRailDestination(
        padding: EdgeInsets.all(25),
        icon: Icon(Icons.person), 
        label: Text("Perfil")
        )
    ];
  }
}