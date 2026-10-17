import 'package:flutter/material.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/utils/permissions.dart';

/// Un destino de la navegación principal del admin: una rama del
/// `StatefulShellRoute` (`buildBranches`). Lo usan el menú lateral
/// (escritorio/tablet) y la barra inferior (celular).
class AdminDestination {
  const AdminDestination({
    required this.icon,
    required this.label,
    required this.branch,
    required this.path,
    this.permissions = const [],
  });

  final IconData icon;
  final String label;

  /// Índice de la rama en `buildBranches`.
  final int branch;

  /// Ruta raíz de la rama.
  final String path;

  /// Alcanza con uno; vacío = visible para todos los admins.
  final List<String> permissions;

  bool get isVisible => permissions.isEmpty || Permissions.canAny(permissions);
}

class AdminDestinations {
  AdminDestinations._();

  static const inicio = AdminDestination(icon: Icons.space_dashboard_outlined, label: 'Inicio', branch: 0, path: '/dashboard');
  static const turnos = AdminDestination(icon: Icons.calendar_month_outlined, label: 'Turnos', branch: 1, path: '/session_manager', permissions: [Permissions.AGENDA_VER]);
  static const clientes = AdminDestination(icon: Icons.groups_outlined, label: 'Clientes', branch: 2, path: '/clients', permissions: [Permissions.CLIENTES_VER]);
  static const pagos = AdminDestination(icon: Icons.credit_card, label: 'Pagos', branch: 3, path: '/payments', permissions: [Permissions.PAGOS_VER]);
  static const mapa = AdminDestination(icon: Icons.map_outlined, label: 'Mapa', branch: 4, path: '/club_map', permissions: [Permissions.MAPA_VER]);
  static const configuracion = AdminDestination(icon: Icons.settings_outlined, label: 'Configuración', branch: 5, path: '/admin/settings', permissions: [Permissions.CONFIGURACION_VER]);
  static const usuarios = AdminDestination(icon: Icons.manage_accounts_outlined, label: 'Usuarios', branch: 6, path: '/users', permissions: [Permissions.ADMINISTRADORES_VER, Permissions.ROLES_VER]);
  static const torneos = AdminDestination(icon: Icons.emoji_events_outlined, label: 'Torneos', branch: 7, path: '/tournaments', permissions: [Permissions.TORNEOS_VER]);

  /// Orden del menú lateral.
  static const rail = [inicio, turnos, clientes, pagos, mapa, torneos, configuracion, usuarios];

  /// Orden por uso en el celular (sin Inicio, que es un placeholder): los
  /// primeros van en la barra inferior y el resto en «Más».
  static const mobile = [turnos, clientes, pagos, torneos, mapa, configuracion, usuarios];

  /// Destinos fijos de la barra inferior antes de «Más».
  static const mobileBarSlots = 4;

  static List<AdminDestination> visible(List<AdminDestination> all) => all.where((d) => d.isVisible).toList();

  /// Ruta donde arranca el admin en el celular: el primer destino que el rol
  /// puede ver (Turnos, si tiene permiso de agenda).
  static String mobileHomePath() {
    final first = visible(mobile);
    return first.isEmpty ? AppRoutes.DASHBOARD_ROUTE.path : first.first.path;
  }
}
