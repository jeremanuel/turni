
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
    final routeName = router.state.topRoute?.name ?? router.state.name;

    final routeDefinition =
        AppRoutes.routesMap[routeName] ?? AppRoutes.routesMap[router.state.name];
    final usesScaffold = routeDefinition?.usesScaffold ?? true;
    final mobileAppBar = routeDefinition?.mobileAppBar;

    if(!usesScaffold) return child;
    
    return Scaffold(
      
      appBar: AppBar(
        leading: mobileAppBar?.backToPath != null
            ? IconButton(
                onPressed: () {
                  context.go(mobileAppBar!.backToPath!);
                },
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: mobileAppBar != null ? Text(mobileAppBar.title) : null,
      ),
      drawer: CustomDrawer(),
      body: child,
    );
  }
}