// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../presentation/admin/client_page/client_page.dart';
import '../../presentation/admin/clients_list/bloc/clients_list_bloc.dart';
import '../../presentation/admin/clients_list/clients_list_page.dart' deferred as list;
import '../../presentation/admin/clients_list/list_utils/client_list_filters.dart';
import '../../presentation/admin/payments_list/payments_list_page.dart';
import '../../presentation/admin/states/scaffold_cubit/scaffold_cubit.dart';
import '../utils/responsive_builder.dart';
import 'service_locator.dart';

import '../../presentation/auth/check_status_page.dart';
import '../../presentation/auth/login_page.dart';
import '../../presentation/core/cubit/auth/auth_cubit.dart';
import '../../presentation/home_layout/widgets/custom_layout.dart';
import '../../presentation/client/profile_manager_screen/profile/profile_page.dart';

import '../../presentation/admin/session_manager_screen/bloc/session_manager_bloc.dart';
import '../../presentation/admin/session_manager_screen/bloc/session_manager_event.dart';
import '../../presentation/admin/create_session_screen/create_sessions_screen.dart';

import '../../domain/entities/club_type.dart';
import '../../presentation/admin/session_manager_screen/session_manager_route.dart';
import '../../presentation/admin/session_manager_screen/utils/session_manager_add_page_builder.dart';
import '../../presentation/admin/session_manager_screen/utils/session_manager_reserve_page_builder.dart';
import '../../presentation/admin/session_manager_screen/widgets/calendar_side_column.dart';
import '../../presentation/client/home_manager_screen/home/home.dart';
import '../../presentation/client/session_manager_screen/session_feed/session_feed.dart';
import 'app_routes.dart';

enum RouterType { clientRoute, adminRoute }

enum ClientRoutes { session_feed }

GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
final GlobalKey customLayoutKey = GlobalKey();
String? currentRoute;
GoRouter buildGoRouter(RouterType routerType) {
  final goRouter =  GoRouter(
    
    initialLocation: '/payments',
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
        builder: (context, state, navigationShell) {
          return CustomLayout(scaffoldKey: scaffoldKey, key: customLayoutKey,child: navigationShell);
        },
      )
    ],
  );

  return goRouter;
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
    StatefulShellBranch(
      routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => Center(
          child: FilledButton(onPressed: () {}, child: const Text("data")),
        ),
      )
    ]),
    StatefulShellBranch(routes: [
      ShellRoute(
        builder: (context, state, child) {
          var idSession = state.pathParameters['idSession'];

          final parsedIdSession =
              idSession != null ? int.tryParse(idSession) : null;

          return SessionManagerRoute(
              routeName: state.topRoute?.name,
              sessionId: parsedIdSession,
              child: child);
        },
        routes: [
          GoRoute(
            name: AppRoutes.SESSION_MANAGER_ROUTE.name,
            path: AppRoutes.SESSION_MANAGER_ROUTE.path,
            redirect: setCurrentRoute,
            pageBuilder: (context, state) {
              context.read<SessionManagerBloc>().add(SetSelectedSession(null));
              return const NoTransitionPage(child: CalendarSideColumn());
            },
          ),
          GoRoute(
            path: '/session_manager/reserve/:idSession',
            name: "SESSION_MANAGER_RESERVE",
            redirect: setCurrentRoute,  
            pageBuilder: sessionManagerReservePageBuilder,

          ),
          GoRoute(
            path: '/session_manager/edit',
            redirect: setCurrentRoute,
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: Text("Editar turno"));
            },
          ),
          GoRoute(
            path: '/session_manager/add/:idPhysicalPartition',
            name: "SESSION_MANAGER_ADD",
            redirect: setCurrentRoute,
            pageBuilder: sessionManagerAddPageBuilder,
          ),
          GoRoute(
            path: '/add_sessions',
            name: "ADD_SESSIONS_MASIVE",
            redirect: setCurrentRoute,
            builder: (context, state) => const CreateSessionScreen(),
          )
        ],
      ),
    ]),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.CLIENTS_LIST_ROUTE.path,
          name: AppRoutes.CLIENTS_LIST_ROUTE.name,
          redirect: setCurrentRoute,
          builder: (context, state){

            final params = state.uri.queryParameters;
            
            return FutureBuilder(
              future: list.loadLibrary(),
              builder:(context, snapshot) {
                if(snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if(snapshot.hasError) {
                  return const Center(child: Text("Error al cargar la página"));
                }
                return BlocProvider( 
                create: (context) => ClientsListBloc(context, sl<AdminRepository>(), ClientListFilters.fromJson(params), params['sort'], bool.tryParse(params['order'] ?? '')),
                child: list.ClientsList(),
              );
              }
            
            );
          },
       
        ),
        GoRoute(
          path: AppRoutes.CLIENT_ROUTE.path,
          name: AppRoutes.CLIENT_ROUTE.name,
          redirect: (context, state) {  
            
            final extraMap = state.extra as Map?;
            final clientFromList = extraMap?['client'] as Client?;
            final bloc = extraMap?['bloc'] as ClientsListBloc;

            if(ResponsiveBuilder.isMobile(context)) return null;

            scaffoldKey.currentState?.openEndDrawer();

            final scaffoldCubit = sl<ScaffoldCubit>();

            final clientId = int.tryParse(
              state.pathParameters['clientId'] ?? '',
            );

            if(clientId != null) {
              scaffoldCubit.setChild(
                BlocProvider.value(
                  value: bloc,
                  child: Clientpage(clientId: clientId, client: clientFromList, onUpdateClient: (p0) {}),
            ));
            }

            return currentRoute ?? AppRoutes.CLIENTS_LIST_ROUTE.path;
          },
          builder: (context, state){

            if(ResponsiveBuilder.isDesktop(context)) return const SizedBox();

            final extraMap = state.extra as Map?;
            final clientFromList = extraMap?['client'] as Client?;
            final bloc = extraMap?['bloc'] as ClientsListBloc;

            final clientId = int.tryParse(
              state.pathParameters['clientId'] ?? '',
            );

            return BlocProvider.value(
              value: bloc,
              child: Clientpage(clientId: clientId!, client: clientFromList, onUpdateClient: (p0) {
                
              },),
            );
          },
        ),

        
        GoRoute(
          path: AppRoutes.NEW_CLIENT_ROUTE.path,
          name: AppRoutes.NEW_CLIENT_ROUTE.name,
         
          redirect: (context, state) {  


            if(ResponsiveBuilder.isMobile(context)) return null;

            scaffoldKey.currentState?.openEndDrawer();

            final scaffoldCubit = sl<ScaffoldCubit>();

            scaffoldCubit.setChild(BlocProvider.value(
              value: state.extra as Bloc,
              child:  Clientpage(clientId: -1, createNewClient: true, onUpdateClient: (p0) {
                
              },)));
       
           return currentRoute ?? AppRoutes.CLIENTS_LIST_ROUTE.path;
          },
          builder: (context, state){

            if(ResponsiveBuilder.isDesktop(context)) {
              return const SizedBox();
            }

            return  Clientpage(clientId: -1, createNewClient: true, onUpdateClient: (p0) {
              
            },);
          },
        ),

    ]),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.PAYMENTS_LIST.path,
          name: AppRoutes.PAYMENTS_LIST.name,
          builder: (context, state) => const PaymentsListPage(),
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
 String? setCurrentRoute(BuildContext context, GoRouterState state) {
  currentRoute = state.fullPath;
  return null;
}

