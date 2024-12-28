class AppRoutes {

  static const SESSION_MANAGER_ROUTE =  RouteDefinition("SESSION_MANAGER", "/session_manager");

  static const CLIENTS_LIST_ROUTE = RouteDefinition("CLIENTS_LIST", "/clients");

}

class RouteDefinition {

  final String name;
  final String path;

  const RouteDefinition(this.name, this.path);
}