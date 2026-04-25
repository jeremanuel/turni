import 'package:go_router/go_router.dart';
import '../../presentation/admin/session_manager_screen/session_manager_route.dart';
import '../../presentation/admin/session_manager_screen/widgets/calendar_side_column.dart';
import '../../presentation/admin/session_manager_screen/utils/session_manager_add_page_builder.dart';
import '../../presentation/admin/session_manager_screen/utils/session_manager_reserve_page_builder.dart';
import '../../presentation/admin/create_session_screen/create_sessions_screen.dart';
import 'router/router_utils.dart';

List<StatefulShellBranch> sessionManagerBranches() => [
  StatefulShellBranch(
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          var idSession = state.pathParameters['idSession'];
          final parsedIdSession = idSession != null ? int.tryParse(idSession) : null;
          return SessionManagerRoute(
            routeName: state.topRoute?.name,
            sessionId: parsedIdSession,
            child: child,
          );
        },
        routes: [
          GoRoute(
            name: 'SESSION_MANAGER_ROUTE',
            path: '/session_manager',
            redirect: setCurrentRoute,
            pageBuilder: (context, state) {
              // Aquí puedes agregar lógica de bloc si es necesario
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
          ),
        ],
      ),
    ],
  ),
];