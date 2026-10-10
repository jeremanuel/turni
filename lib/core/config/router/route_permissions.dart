import '../../utils/permissions.dart';
import 'app_routes.dart';

/// Qué permiso pide cada sección para poder entrar por URL. El menú lateral
/// ya oculta lo que el rol no puede ver; esto cubre los links directos.
class RoutePermissions {
  static final _rules = <(String, List<String>)>[
    // Las más específicas primero: gana la primera que matchea.
    ('/session_manager/add', [Permissions.AGENDA_CREAR]),
    (AppRoutes.SESSION_MANAGER_ROUTE.path, [Permissions.AGENDA_VER]),
    (AppRoutes.ADD_SESSIONS_MASSIVE_ROUTE.path, [Permissions.AGENDA_CREAR]),
    (AppRoutes.BULK_SESSIONS_ROUTE.path, [Permissions.AGENDA_GESTION_MASIVA, Permissions.AGENDA_CREAR]),
    // `/client` cubre también `/clients`.
    (AppRoutes.NEW_CLIENT_ROUTE.path, [Permissions.CLIENTES_VER]),
    (AppRoutes.PAYMENTS_LIST.path, [Permissions.PAGOS_VER]),
    (AppRoutes.CLUB_MAP_ROUTE.path, [Permissions.MAPA_VER]),
    (AppRoutes.ADMIN_SETTINGS_ROUTE.path, [Permissions.CONFIGURACION_VER]),
    (AppRoutes.USERS_ROUTE.path, [Permissions.ADMINISTRADORES_VER, Permissions.ROLES_VER]),
  ];

  /// Permisos (alcanza con uno) para entrar a [location], o null si no pide ninguno.
  static List<String>? requiredFor(String location) {
    // `/client` a secas es el alta de cliente (`/client/:id` es la ficha).
    if (location == AppRoutes.NEW_CLIENT_ROUTE.path) return [Permissions.CLIENTES_EDITAR];
    for (final (prefix, permissions) in _rules) {
      if (location == prefix || location.startsWith(prefix)) return permissions;
    }
    return null;
  }
}
