// ignore_for_file: constant_identifier_names

class AppRoutes {

  static const SESSION_MANAGER_ROUTE =  RouteDefinition("SESSION_MANAGER", "/session_manager");

  static const CLIENTS_LIST_ROUTE = RouteDefinition("CLIENTS_LIST", "/clients");

  static const CLIENT_ROUTE = RouteDefinition("CLIENT", '/client/:clientId', usesScaffold: false);

  static const NEW_CLIENT_ROUTE = RouteDefinition("NEW_CLIENT", '/client', usesScaffold: false);

  static const NEW_ROUTINE_ROUTE = RouteDefinition("NEW_ROUTINE", '/routine', usesScaffold: false);

  static const PAYMENTS_LIST = RouteDefinition("PAYMENTS", '/payments');

  static final routesMap = {
    SESSION_MANAGER_ROUTE.name: SESSION_MANAGER_ROUTE,
    CLIENTS_LIST_ROUTE.name: CLIENTS_LIST_ROUTE,
    CLIENT_ROUTE.name: CLIENT_ROUTE,
    NEW_CLIENT_ROUTE.name: NEW_CLIENT_ROUTE,
    NEW_ROUTINE_ROUTE.name: NEW_ROUTINE_ROUTE,
    PAYMENTS_LIST.name: PAYMENTS_LIST,
  };
}

class RouteDefinition {

  final String name;
  final String path;
  final bool usesScaffold;
  const RouteDefinition(this.name, this.path, {this.usesScaffold = true});
}