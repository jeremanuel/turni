import 'package:flutter/material.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/services/cash_status.dart';
import '../../../core/services/fiscal_status.dart';
import '../../../core/utils/permissions.dart';

/// Un destino de la navegación principal del admin: una rama del
/// `StatefulShellRoute` (`buildBranches`). Lo usan el menú lateral
/// (escritorio/tablet) y la barra inferior (celular).
class AdminDestination {
  const AdminDestination({
    required this.icon,
    required String label,
    required this.branch,
    required this.path,
    required this.anchor,
    this.permissions = const [],
    this.isEnabled,
    this.labelOf,
  }) : _label = label;

  final IconData icon;
  final String _label;

  /// Nombre que depende de la configuración (ej. «Comprobantes» si el club
  /// factura pero no usa caja).
  final String Function()? labelOf;

  String get label => labelOf?.call() ?? _label;

  /// Índice de la rama en `buildBranches`.
  final int branch;

  /// Ruta raíz de la rama.
  final String path;

  /// Nombre del `TourAnchor` del destino en el menú (lo usan las guías).
  final String anchor;

  /// Alcanza con uno; vacío = visible para todos los admins.
  final List<String> permissions;

  /// Condición extra además de los permisos (ej. que el club use caja).
  final bool Function()? isEnabled;

  bool get isVisible => (isEnabled?.call() ?? true) && (permissions.isEmpty || Permissions.canAny(permissions));
}

bool _usesCash() => CashStatus.enabled.value && Permissions.can(Permissions.CAJA_VER);
bool _usesFiscal() => FiscalStatus.enabled.value && Permissions.can(Permissions.FACTURACION_VER);
bool _cashEnabled() => _usesCash() || _usesFiscal();
String _cashLabel() => _usesCash() ? 'Caja' : 'Comprobantes';

class AdminDestinations {
  AdminDestinations._();

  static const inicio = AdminDestination(icon: Icons.space_dashboard_outlined, label: 'Inicio', branch: 0, path: '/dashboard', anchor: 'nav.inicio');
  static const turnos = AdminDestination(icon: Icons.calendar_month_outlined, label: 'Turnos', branch: 1, path: '/session_manager', anchor: 'nav.turnos', permissions: [Permissions.AGENDA_VER]);
  static const clientes = AdminDestination(icon: Icons.groups_outlined, label: 'Clientes', branch: 2, path: '/clients', anchor: 'nav.clientes', permissions: [Permissions.CLIENTES_VER]);
  static const pagos = AdminDestination(icon: Icons.credit_card, label: 'Pagos', branch: 3, path: '/payments', anchor: 'nav.pagos', permissions: [Permissions.PAGOS_VER]);
  static const mapa = AdminDestination(icon: Icons.map_outlined, label: 'Mapa', branch: 4, path: '/club_map', anchor: 'nav.mapa', permissions: [Permissions.MAPA_VER]);
  static const configuracion = AdminDestination(icon: Icons.settings_outlined, label: 'Configuración', branch: 5, path: '/admin/settings', anchor: 'nav.configuracion', permissions: [Permissions.CONFIGURACION_VER]);
  static const usuarios = AdminDestination(icon: Icons.manage_accounts_outlined, label: 'Usuarios', branch: 6, path: '/users', anchor: 'nav.usuarios', permissions: [Permissions.ADMINISTRADORES_VER, Permissions.ROLES_VER]);
  static const torneos = AdminDestination(icon: Icons.emoji_events_outlined, label: 'Torneos', branch: 7, path: '/tournaments', anchor: 'nav.torneos', permissions: [Permissions.TORNEOS_VER]);

  /// Solo si el establecimiento usa caja o factura con ARCA.
  static const caja = AdminDestination(
    icon: Icons.point_of_sale_outlined,
    label: 'Caja',
    branch: 8,
    path: '/cash',
    anchor: 'nav.caja',
    permissions: [Permissions.CAJA_VER, Permissions.FACTURACION_VER],
    isEnabled: _cashEnabled,
    labelOf: _cashLabel,
  );

  /// Cambia cuando el club prende o apaga la caja o la facturación.
  static final Listenable changes = Listenable.merge([CashStatus.enabled, FiscalStatus.enabled]);

  /// Orden del menú lateral.
  static const rail = [inicio, turnos, clientes, pagos, caja, mapa, torneos, configuracion, usuarios];

  /// Orden por uso en el celular (sin Inicio, que es un placeholder): los
  /// primeros van en la barra inferior y el resto en «Más».
  static const mobile = [turnos, clientes, pagos, caja, torneos, mapa, configuracion, usuarios];

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
