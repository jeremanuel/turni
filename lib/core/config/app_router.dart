// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/presentation/admin/session_manager_screen/sessions_manager.dart';
import 'package:turni/presentation/auth/check_status_page.dart';
import 'package:turni/presentation/auth/login_page.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';
import 'package:turni/presentation/home_layout/widgets/custom_layout.dart';
import 'package:turni/presentation/client/profile_manager_screen/profile/profile_page.dart';

import '../../presentation/admin/create_session_screen/create_sessions_screen.dart';

import '../../domain/entities/club_type.dart';
import '../../presentation/admin/session_manager_screen/widgets/add_new_session.dart';
import '../../presentation/admin/session_manager_screen/widgets/calendar_side_column.dart';
import '../../presentation/client/home_manager_screen/home/home.dart';
import '../../presentation/client/session_manager_screen/session_feed/session_feed.dart';
import '../utils/types/time_interval.dart';

enum RouterType { clientRoute, adminRoute }

enum ClientRoutes { session_feed }

GoRouter buildGoRouter(RouterType routerType) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: sl<AuthCubit>(),
    redirect: (context, state) {
      final authCubit = sl<AuthCubit>();

      if (authCubit.getLoadingStatus()) return '/';

      if (authCubit.state.userCredential == null) return '/login';

      if (state.matchedLocation == "/" || state.matchedLocation == "/login") {
        return routerType == RouterType.adminRoute ? '/dashboard' : '/home';
      }
    },
    routes: [
      /// Estas dos rutas son comunes a ambos tipos de usuario.
      GoRoute(
        path: '/',
        builder: (context, state) => AuthCheck(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      if (routerType == RouterType.clientRoute)
        GoRoute(
          path: "/session_feed",
          builder: (context, state) =>
              SessionFeedPage(clubType: state.extra as ClubType),
        ),
      StatefulShellRoute.indexedStack(
        branches: buildBranches(routerType),
        builder: (context, state, navigationShell) =>
            CustomLayout(child: navigationShell),
      )
    ],
  );
}

List<StatefulShellBranch> buildBranches(RouterType routerType) {
  if (routerType == RouterType.clientRoute) {
    return [
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) {
            return HomePage();
          },
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            return const ProfilePage();
          },
        ),
      ])
    ];
  }

  return [
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => Center(
          child: FilledButton(onPressed: () {}, child: Text("data")),
        ),
      )
    ]),
    StatefulShellBranch(routes: [
      ShellRoute(
        builder: (context, state, child) => SessionsManager(sideChild: child),
        routes: [
          GoRoute(
            path: '/session_manager',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: CalendarSideColumn());
            },
          ),
          GoRoute(
            path: '/session_manager/reserve',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: Text("reservar turno"));
            },
          ),
          GoRoute(
            path: '/session_manager/edit',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: Text("Editar turno"));
            },
          ),
          GoRoute(
            path: '/session_manager/add/:idPhysicalPartition',
            name: "SESSION_MANAGER_ADD",
            pageBuilder: (context, state) {
              final idPhysicalPartition =
                  state.pathParameters['idPhysicalPartition'];

              final startTime = state.uri.queryParameters['start'];
              final endTime = state.uri.queryParameters['end'];

              DateFormat dateFormat = DateFormat("HH:mm");

              final timeInterval = TimeInterval(
                  initialDate:
                      startTime != null ? dateFormat.parse(startTime) : null,
                  endDate: endTime != null ? dateFormat.parse(endTime) : null);

              return NoTransitionPage(
                  child: AddNewSession(
                      idPhysicalPartition: int.parse(idPhysicalPartition!),
                      selectedTimeInterval: timeInterval));
            },
          ),
        ],
      ),
      GoRoute(
        path: '/add_sessions',
        builder: (context, state) => CreateSessionScreen(),
      )
    ]),
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          return const ProfilePage();
        },
      ),
    ])
  ];
}
