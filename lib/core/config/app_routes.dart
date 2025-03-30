// ignore_for_file: constant_identifier_names

class AppRoutes {

  static const SESSION_MANAGER_ROUTE =  RouteDefinition("SESSION_MANAGER", "/session_manager");

  static const CLIENTS_LIST_ROUTE = RouteDefinition("CLIENTS_LIST", "/clients");

  static const CLIENT_ROUTE = RouteDefinition("CLIENT", 'client/:clientId');

  static const NEW_CLIENT_ROUTE = RouteDefinition("NEW_CLIENT", '/client');


}

class RouteDefinition {

  final String name;
  final String path;

  const RouteDefinition(this.name, this.path);
}