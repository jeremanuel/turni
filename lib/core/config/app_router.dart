// ignore_for_file: constant_identifier_names

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/presentation/admin/session_manager_screen/sessions_manager_desktop.dart';
import 'package:turni/presentation/auth/check_status_page.dart';
import 'package:turni/presentation/auth/login_page.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';
import 'package:turni/presentation/home_layout/widgets/custom_layout.dart';
import 'package:turni/presentation/client/profile_manager_screen/profile/profile_page.dart';

import '../../presentation/admin/bloc/session_manager_bloc.dart';
import '../../presentation/admin/bloc/session_manager_event.dart';
import '../../presentation/admin/bloc/session_manager_state.dart';
import '../../presentation/admin/create_session_screen/create_sessions_screen.dart';

import '../../domain/entities/club_type.dart';
import '../../presentation/admin/session_manager_screen/session_manager_route.dart';
import '../../presentation/admin/session_manager_screen/utils/session_manager_add_page_builder.dart';
import '../../presentation/admin/session_manager_screen/utils/session_manager_reserve_page_builder.dart';
import '../../presentation/admin/session_manager_screen/widgets/agenda_container.dart';
import '../../presentation/admin/session_manager_screen/widgets/calendar_side_column.dart';
import '../../presentation/client/home_manager_screen/home/home.dart';
import '../../presentation/client/session_manager_screen/session_feed/session_feed.dart';
import '../utils/responsive_builder.dart';

enum RouterType { clientRoute, adminRoute }

enum ClientRoutes { session_feed }

GoRouter buildGoRouter(RouterType routerType) {
  return GoRouter(
    initialLocation: '/',
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
          child: FilledButton(onPressed: () {}, child: const Text("data")),
        ),
      )
    ]),
    StatefulShellBranch(
      routes: [
      ShellRoute(
        builder: (context, state, child) {
          var idSession = state.pathParameters['idSession'];

          final parsedIdSession = idSession != null ? int.tryParse(idSession) : null;
          
          return SessionManagerRoute(
            routeName: state.topRoute?.name,
            sessionId: parsedIdSession,
            child: child  
          );
          
        },
        routes: [
          GoRoute(
            name: "SESSION_MANAGER",
            path: '/session_manager',
            pageBuilder: (context, state) {
              context.read<SessionManagerBloc>().add(SetSelectedSession(null));
              return const NoTransitionPage(child: CalendarSideColumn());
            },
          ),
          GoRoute(
            path: '/session_manager/reserve/:idSession',
            name: "SESSION_MANAGER_RESERVE",
            pageBuilder: sessionManagerReservePageBuilder,
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
            pageBuilder: sessionManagerAddPageBuilder,
          ),
        ],
      ),
      GoRoute(
        path: '/add_sessions',
        builder: (context, state) => const CreateSessionScreen(),
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
