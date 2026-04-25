import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/home_layout/widgets/custom_layout.dart';
import '../../../presentation/core/cubit/auth/auth_cubit.dart';
import '../service_locator.dart';
import 'dashboard_routes.dart';
import '../session_manager_routes.dart';
import 'clients_routes.dart';
import 'profile_routes.dart';

GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
final GlobalKey customLayoutKey = GlobalKey();

GoRouter buildGoRouter() {
  return GoRouter(
    initialLocation: "/session_manager",
    refreshListenable: sl<AuthCubit>(),
    redirect: (context, state) {
      final authCubit = sl<AuthCubit>();

      
      if (authCubit.getLoadingStatus()) {
        if (state.matchedLocation != "/") {
          authCubit.initialRoute = state.uri.toString();
        }
        return '/';
      }
      if (authCubit.state.userCredential == null) return '/login';
      if (state.matchedLocation == "/" || state.matchedLocation == "/login") {
        if (authCubit.initialRoute != null) {
          return authCubit.initialRoute;
        }
        return '/dashboard';
      }
      return null;
    },
    routes: [
      ...dashboardRoutes(),
      StatefulShellRoute.indexedStack(
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: "/dashboard",
              builder: (context, state) => SizedBox(),
            )
          ]),
          ...sessionManagerBranches(),
          ...clientsBranches(scaffoldKey),
          ...profileBranches(),
        ],
        builder: (context, state, navigationShell) {
          return CustomLayout(
            scaffoldKey: scaffoldKey,
            key: customLayoutKey,
            child: navigationShell,
          );
        },
      ),
    ],
  );
}