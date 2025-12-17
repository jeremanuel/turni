import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/admin/session_manager_screen/bloc/session_manager_event.dart';
import '../../../../presentation/admin/session_manager_screen/bloc/session_manager_bloc.dart';
import '../../../../presentation/admin/session_manager_screen/session_manager_route.dart';
import '../../../../presentation/admin/session_manager_screen/widgets/calendar_side_column.dart';
import '../../../../presentation/admin/session_manager_screen/utils/session_manager_add_page_builder.dart';
import '../../../../presentation/admin/session_manager_screen/utils/session_manager_reserve_page_builder.dart';
import '../../../../presentation/admin/create_session_screen/create_sessions_screen.dart';
import '../app_router.dart';
import '../app_routes.dart';

StatefulShellBranch sessionShellBranch() {
  return StatefulShellBranch(routes: [
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
    ]);
}
