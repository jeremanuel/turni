import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

import '../../presentation/admin/create_session_screen/create_sessions_screen.dart';



enum RouterType {
  clientRoute,
  adminRoute
}

GoRouter buildGoRouter(RouterType routerType){

  return GoRouter(
    initialLocation: '/',
  refreshListenable: sl<AuthCubit>(),
    redirect: (context, state) {
    
     final authCubit = sl<AuthCubit>();

    if (authCubit.getLoadingStatus()) return '/';

    if (authCubit.state.userCredential == null) return '/login';

    if (state.matchedLocation == "/" || state.matchedLocation == "/login") return routerType == RouterType.adminRoute ? '/dashboard' : '/feed';


    return state.matchedLocation;
  },  
  routes: [

    /// Estas dos rutas son comunes a ambos tipos de usuario.
    GoRoute(
      path: '/',
      builder: (context, state) => AuthCheck(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage()
    ),

    StatefulShellRoute.indexedStack(
      branches: buildBranches(routerType),
      builder: (context, state, navigationShell) => CustomLayout(child: navigationShell),
    )
  ],
);
}


List<StatefulShellBranch> buildBranches(RouterType routerType){

  if(routerType == RouterType.clientRoute){
    return [
     StatefulShellBranch(
          routes: [
          GoRoute(
            path: '/feed',
            builder: (context, state) {
              return FeedPage();
            },
          ),
          GoRoute(
            path: '/turno',
            builder: (context, state) {
              return SessionPage(
                session: state.extra as Session,
              );
            },
          
          ),
        ]),
        StatefulShellBranch(
          routes: [
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
              builder: (context, state) =>  Center(child: FilledButton(onPressed: (){}, child: Text("data")),),
            )
          ]
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/session_manager',
              builder: (context, state) =>  SessionsManager(),
            ),
            GoRoute(
              path: '/add_sessions',
              builder: (context, state) =>  CreateSessionScreen(),
            )
          ]
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) {
                return const ProfilePage();
              },
            ),
        ])
  ];
}

