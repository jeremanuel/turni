// ignore_for_file: constant_identifier_names

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/domain/entities/session.dart';
import 'package:turni/presentation/admin/session_manager_screen/sessions_manager.dart';
import 'package:turni/presentation/auth/check_status_page.dart';
import 'package:turni/presentation/auth/login_page.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';
import 'package:turni/presentation/feed/feed_page.dart';
import 'package:turni/presentation/home_layout/widgets/custom_layout.dart';
import 'package:turni/presentation/profile/profile_page.dart';
import 'package:turni/presentation/turno/turno_page.dart';

import '../../domain/entities/physical_partition.dart';
import '../../presentation/admin/bloc/session_manager_bloc.dart';
import '../../presentation/admin/create_session_screen/create_sessions_screen.dart';



import '../../domain/entities/club_type.dart';
import '../../presentation/admin/session_manager_screen/widgets/add_new_session.dart';
import '../../presentation/admin/session_manager_screen/widgets/calendar_side_column.dart';
import '../../presentation/admin/session_manager_screen/widgets/reservate_session.dart';
import '../../presentation/home/home.dart';
import '../../presentation/session_feed/session_feed.dart';
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
        return routerType == RouterType.adminRoute ? '/dashboard' : '/feed';
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
          path: '/feed',
          builder: (context, state) {
            return FeedPage();
          },
        ),
      ]),
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
    StatefulShellBranch(
      routes: [
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
                
                builder: (context, state, child) => SessionsManager(sideChild: child),
                routes: [
                  GoRoute(
                    path: '/session_manager',
                    pageBuilder: (context, state) {
                      return const NoTransitionPage(child: CalendarSideColumn());
                    },
                  ),
                  GoRoute(
                    path: '/session_manager/reserve/:idSession',
                    name: "SESSION_MANAGER_RESERVE",
                    pageBuilder: (context, state) {

                      final idSession = int.parse(state.pathParameters['idSession']!);
                      
                      final session = sl<SessionManagerBloc>().state.sessions.firstWhereOrNull((element) => element.sessionId == idSession);
                      
                      final sessionManagerbloc = sl<SessionManagerBloc>();

                      final selectedClubPartition = sessionManagerbloc.state.selectedClubPartition;
                      final physicalPartition = selectedClubPartition!.physicalPartitions!.firstWhere((element) => element.partitionPhysicalId == session!.partitionPhysicalId);


                      return NoTransitionPage(child: ReservateSession(session: session!, clubPartition: selectedClubPartition, physicalPartition: physicalPartition,));
                    },
                  ),    
                  GoRoute(
                    path: '/session_manager/edit',
                    pageBuilder: (context, state) {
                      return const  NoTransitionPage(child: Text("Editar turno"));
                    },
                  ),
                  GoRoute(
                    path: '/session_manager/add/:idPhysicalPartition',
                    name: "SESSION_MANAGER_ADD",
                    pageBuilder: (context, state) {
                      
                      final idPhysicalPartition = state.pathParameters['idPhysicalPartition'];

                      final startTime = state.uri.queryParameters['start'];
                      final endTime = state.uri.queryParameters['end'];

                      DateFormat dateFormat = DateFormat("HH:mm");
                      final startDate = startTime != null ? dateFormat.parse(startTime) : null;
                      final endDate = endTime != null ? dateFormat.parse(endTime) : null;

                      final selectedDay = sl<SessionManagerBloc>().state.currentDate;

                      final timeInterval = TimeInterval(
                        initialDate: startDate != null ? selectedDay.copyWith(minute:startDate.minute, hour: startDate.hour ) : null,
                        endDate: endDate != null ? selectedDay.copyWith(minute:endDate.minute, hour: endDate.hour ) : null
                      );

                      return NoTransitionPage(
                        child: AddNewSession(
                          idPhysicalPartition: int.parse(idPhysicalPartition!), 
                          selectedTimeInterval: timeInterval
                        )
                      );
                    },
                  ),
                ], 
                ),

            GoRoute(
              path: '/add_sessions',
              builder: (context, state) =>  CreateSessionScreen(),
            )
          ]
        ),
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
