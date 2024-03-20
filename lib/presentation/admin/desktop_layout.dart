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
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          
          children: [
                       
            const SizedBox(width: 20,),
            SideBar(child: child),
            const SizedBox(width: 20,),

            Expanded(
              child: Material(
                elevation: 25,
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: child,
                ),
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
      extended: true,
      minExtendedWidth: 200,
      leading: const Padding(
        padding: EdgeInsets.all(32),
        child: Text("Turni", style: TextStyle(fontWeight: FontWeight.w600),),
      ),
      trailing:  Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children:[
            IconButton(onPressed: (){}, icon: const Icon(Icons.logout)),
            const SizedBox(height: 40,)
          ] 
        ),
      ) ,
      onDestinationSelected: (index) => child.goBranch(index),

      elevation: 25,
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
        padding: EdgeInsets.all(16),
        icon: Icon(Icons.dashboard), 
        label: Text("Dashboard")
        ),
        NavigationRailDestination(
        padding: EdgeInsets.all(16),
        icon: Icon(Icons.calendar_month), 
        label: Text("Turnos")
        ),
        NavigationRailDestination(
        padding: EdgeInsets.all(16),
        icon: Icon(Icons.person), 
        label: Text("Perfil")
        )
    ];
  }
}