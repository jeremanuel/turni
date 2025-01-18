import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';

import 'cubit/scaffold_cubit.dart';

class DesktopLayout extends StatelessWidget {

  final StatefulNavigationShell child;

  const DesktopLayout({super.key, required this.child, required this.scaffoldKey});
  final GlobalKey<ScaffoldState> scaffoldKey;
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      key: scaffoldKey,
      drawer: const Drawer(
        child: Text("Drawer"),
      ),
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
                color: Theme.of(context).colorScheme.surfaceContainer,
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

class EndDrawer extends StatelessWidget {
  const EndDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final scaffoldCubit = sl<ScaffoldCubit>();

        return scaffoldCubit.state.child ?? const SizedBox();
      },
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
      labelType: NavigationRailLabelType.selected,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      minExtendedWidth: 200,
      leading:  Padding(
        padding: const EdgeInsets.all(32),
        child: SvgPicture.asset(
                "assets/img/logotype_white.svg",
                semanticsLabel: 'Logo de la app de Turni',
                height: 25,
                colorFilter:  ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.srcIn)
              ),
      ),
      trailing:  Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children:[
            IconButton(onPressed: (){
              sl<AuthCubit>().signOutGoogle();
            }, icon: const Icon(Icons.logout)),
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
          label: Text("Clientes")
        ),
          NavigationRailDestination(
          padding: EdgeInsets.all(16),
          icon: Icon(Icons.build), 
          label: Text("Perfil")
        )
    ];
  }
}

/*       BottomNavigationBarItem(
        label: "Clientes",
        icon: Icon(Icons.person),
        activeIcon: Icon(Icons.person)),
      BottomNavigationBarItem(
          label: "Perfil",
          icon: Icon(Icons.build),
          activeIcon: Icon(Icons.build)) */