// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/admin/payments_list/payments_list_page.dart';
import 'branches/client_shell_branch.dart';
import 'branches/profile_shell_branch.dart';
import '../service_locator.dart';

import '../../../presentation/auth/check_status_page.dart';
import '../../../presentation/auth/login_page.dart';
import '../../../presentation/core/cubit/auth/auth_cubit.dart';
import '../../../presentation/home_layout/widgets/custom_layout.dart';

import 'app_routes.dart';
import 'branches/session_shell_branch.dart';
import 'dialog_page.dart';

enum RouterType { clientRoute, adminRoute }

enum ClientRoutes { session_feed }

GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
final GlobalKey customLayoutKey = GlobalKey();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
String? currentRoute;
GoRouter buildGoRouter(RouterType routerType) {
  final goRouter =  GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/clients',
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

        return routerType == RouterType.adminRoute ? '/dashboard' : '/feed';
      }
      
      return null;
    },
    routes: [
      /// Estas dos rutas son comunes a ambos tipos de usuario.
      GoRoute(
        path: '/',
        builder: (context, state) => AuthCheck(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        branches: buildBranches(routerType),
        builder: (context, state, navigationShell) {
          return CustomLayout(scaffoldKey: scaffoldKey, key: customLayoutKey,child: navigationShell);
        },
      )
    ],
  );

  return goRouter;
}

List<StatefulShellBranch> buildBranches(RouterType routerType) {


  return [
    StatefulShellBranch(
      routes: [
        
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => Center(
          child: FilledButton(onPressed: () {}, child: const Text("data")),
        ),
      )
    ]),
    sessionShellBranch(),
    clientShellBranch(),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.PAYMENTS_LIST.path,
          name: AppRoutes.PAYMENTS_LIST.name,
          builder: (context, state) => const PaymentsListPage(),

        ),
         
      ]
    ),
    
    profileShellBranch()
  ];
}
 String? setCurrentRoute(BuildContext context, GoRouterState state) {
  currentRoute = state.fullPath;
  return null;
}

