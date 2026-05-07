// ignore_for_file: constant_identifier_names

class AppRoutes {

  static const ROOT_ROUTE = RouteDefinition("ROOT", "/", usesScaffold: false);

  static const LOGIN_ROUTE = RouteDefinition("LOGIN", "/login", usesScaffold: false);

  static const DASHBOARD_ROUTE = RouteDefinition("DASHBOARD", "/dashboard");

  static const FEED_ROUTE = RouteDefinition("FEED", "/feed");

  static const PROFILE_ROUTE = RouteDefinition("PROFILE", "/profile");

  static const SESSION_MANAGER_ROUTE =  RouteDefinition("SESSION_MANAGER", "/session_manager");

  static const SESSION_MANAGER_RESERVE_ROUTE = RouteDefinition(
    "SESSION_MANAGER_RESERVE",
    "/session_manager/reserve/:idSession",
    mobileAppBar: MobileAppBarConfig(
      title: 'Datos del Turno',
      backToPath: '/session_manager',
    ),
  );

  static const SESSION_MANAGER_EDIT_ROUTE = RouteDefinition("SESSION_MANAGER_EDIT", "/session_manager/edit");

  static const SESSION_MANAGER_ADD_ROUTE = RouteDefinition("SESSION_MANAGER_ADD", "/session_manager/add/:idPhysicalPartition");

  static const ADD_SESSIONS_MASSIVE_ROUTE = RouteDefinition(
    "ADD_SESSIONS_MASSIVE",
    "/add_sessions",
    mobileAppBar: MobileAppBarConfig(
      title: 'Agregar turnos',
      backToPath: '/session_manager',
    ),
  );

  static const CLIENTS_LIST_ROUTE = RouteDefinition("CLIENTS_LIST", "/clients");

  static const CLIENT_ROUTE = RouteDefinition("CLIENT", '/client/:clientId', usesScaffold: false);

  static const NEW_CLIENT_ROUTE = RouteDefinition("NEW_CLIENT", '/client', usesScaffold: false);

  static const NEW_ROUTINE_ROUTE = RouteDefinition("NEW_ROUTINE", '/:clientId/routine', usesScaffold: false);

  static const PROFILE_SETTINGS_ROUTE = RouteDefinition("PROFILE_SETTINGS", "/profile/settings");

  static const PROFILE_SECURITY_ROUTE = RouteDefinition("PROFILE_SECURITY", "/profile/security");

  static const PAYMENTS_LIST = RouteDefinition("PAYMENTS", '/payments');

  

  static final routesMap = {
    ROOT_ROUTE.name: ROOT_ROUTE,
    LOGIN_ROUTE.name: LOGIN_ROUTE,
    DASHBOARD_ROUTE.name: DASHBOARD_ROUTE,
    FEED_ROUTE.name: FEED_ROUTE,
    PROFILE_ROUTE.name: PROFILE_ROUTE,
    SESSION_MANAGER_ROUTE.name: SESSION_MANAGER_ROUTE,
    SESSION_MANAGER_RESERVE_ROUTE.name: SESSION_MANAGER_RESERVE_ROUTE,
    SESSION_MANAGER_EDIT_ROUTE.name: SESSION_MANAGER_EDIT_ROUTE,
    SESSION_MANAGER_ADD_ROUTE.name: SESSION_MANAGER_ADD_ROUTE,
    ADD_SESSIONS_MASSIVE_ROUTE.name: ADD_SESSIONS_MASSIVE_ROUTE,
    CLIENTS_LIST_ROUTE.name: CLIENTS_LIST_ROUTE,
    CLIENT_ROUTE.name: CLIENT_ROUTE,
    NEW_CLIENT_ROUTE.name: NEW_CLIENT_ROUTE,
    NEW_ROUTINE_ROUTE.name: NEW_ROUTINE_ROUTE,
    PROFILE_SETTINGS_ROUTE.name: PROFILE_SETTINGS_ROUTE,
    PROFILE_SECURITY_ROUTE.name: PROFILE_SECURITY_ROUTE,
    PAYMENTS_LIST.name: PAYMENTS_LIST,
  };
}

class RouteDefinition {

  final String name;
  final String path;
  final bool usesScaffold;
  final MobileAppBarConfig? mobileAppBar;
  const RouteDefinition(
    this.name,
    this.path, {
    this.usesScaffold = true,
    this.mobileAppBar,
  });
}

class MobileAppBarConfig {
  final String title;
  final String? backToPath;

  const MobileAppBarConfig({
    required this.title,
    this.backToPath,
  });
}