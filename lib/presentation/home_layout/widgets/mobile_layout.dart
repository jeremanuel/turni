
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/router/app_routes.dart';
import 'custom_drawer.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({
    super.key,
    required this.child,
  });

  final StatefulNavigationShell child;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);

    final usesScaffold = AppRoutes.routesMap[router.state.name]!.usesScaffold;

    if(!usesScaffold) return child;
    
    return Scaffold(
      appBar: AppBar(
      
        
      ),
      drawer: CustomDrawer(),
      body: child,
    );
  }
}