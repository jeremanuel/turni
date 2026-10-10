// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/admin/club_map/club_map_page.dart';
import '../../../presentation/admin/payments_list/payments_list_page.dart';
import 'branches/client_shell_branch.dart';
import 'branches/profile_shell_branch.dart';
import '../service_locator.dart';

import '../../../presentation/auth/check_status_page.dart';
import '../../../presentation/auth/login_page.dart';
import '../../../presentation/auth/admin_invite_page.dart';
import '../../../presentation/auth/no_access_page.dart';
import '../../../presentation/admin/users/users_page.dart';
import 'route_permissions.dart';
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
    initialLocation: AppRoutes.CLIENTS_LIST_ROUTE.path,
    refreshListenable: sl<AuthCubit>(),
    redirect: (context, state) {
      final authCubit = sl<AuthCubit>();
      if (authCubit.getLoadingStatus()) {
        if (state.matchedLocation != AppRoutes.ROOT_ROUTE.path) {
          authCubit.initialRoute = state.uri.toString();
        }

        return AppRoutes.ROOT_ROUTE.path;
      }

      final location = state.matchedLocation;
      final isInvite = location.startsWith('/invite/');

      if (authCubit.state.userCredential == null) {
        // Sin sesión, el link de invitación vuelve a abrirse después del login.
        if (isInvite) authCubit.initialRoute = state.uri.toString();
        return AppRoutes.LOGIN_ROUTE.path;
      }

      if (location == AppRoutes.ROOT_ROUTE.path || location == AppRoutes.LOGIN_ROUTE.path) {
        if (authCubit.initialRoute != null) {
          return authCubit.initialRoute;
        }

        return routerType == RouterType.adminRoute
            ? AppRoutes.DASHBOARD_ROUTE.path
            : AppRoutes.FEED_ROUTE.path;
      }

      // El link de invitación lo abre alguien que todavía no es admin.
      if (isInvite) return null;

      if (routerType == RouterType.adminRoute) {
        final hasAccess = authCubit.isAdmin() && !authCubit.isDisabledAdmin();
        if (!hasAccess) {
          return location == AppRoutes.NO_ACCESS_ROUTE.path ? null : AppRoutes.NO_ACCESS_ROUTE.path;
        }
        if (location == AppRoutes.NO_ACCESS_ROUTE.path) return AppRoutes.DASHBOARD_ROUTE.path;

        // Links directos a secciones que el rol no puede ver.
        final required = RoutePermissions.requiredFor(location);
        if (required != null && !authCubit.canAny(required)) return AppRoutes.DASHBOARD_ROUTE.path;
      }

      return null;
    },
    routes: [
      /// Estas dos rutas son comunes a ambos tipos de usuario.
      GoRoute(
        path: AppRoutes.ROOT_ROUTE.path,
        name: AppRoutes.ROOT_ROUTE.name,
        builder: (context, state) => AuthCheck(),
      ),
      GoRoute(
        path: AppRoutes.LOGIN_ROUTE.path,
        name: AppRoutes.LOGIN_ROUTE.name,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.ADMIN_INVITE_ROUTE.path,
        name: AppRoutes.ADMIN_INVITE_ROUTE.name,
        builder: (context, state) => AdminInvitePage(token: state.pathParameters['token'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.NO_ACCESS_ROUTE.path,
        name: AppRoutes.NO_ACCESS_ROUTE.name,
        builder: (context, state) => const NoAccessPage(),
      ),
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
        path: AppRoutes.DASHBOARD_ROUTE.path,
        name: AppRoutes.DASHBOARD_ROUTE.name,
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
    // El orden de las ramas es el de los destinos del NavigationRail
    // (desktop_layout.dart): Mapa va antes de Ajustes.
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.CLUB_MAP_ROUTE.path,
          name: AppRoutes.CLUB_MAP_ROUTE.name,
          builder: (context, state) => const ClubMapPage(),
        ),
      ]
    ),
    profileShellBranch(),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.USERS_ROUTE.path,
          name: AppRoutes.USERS_ROUTE.name,
          builder: (context, state) => const UsersPage(),
        ),
      ],
    ),
  ];
}
 String? setCurrentRoute(BuildContext context, GoRouterState state) {
  currentRoute = state.fullPath;
  return null;
}

