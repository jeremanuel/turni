import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/service_locator.dart';
import '../../core/cubit/auth/auth_cubit.dart';
import '../../../core/utils/permissions.dart';

/// Menú lateral del admin (diseño "Gestor de turnos: layout, menú lateral y
/// panel del turno"): logo, destinos con ícono y texto siempre visibles, y el
/// avatar del admin abajo con perfil y cerrar sesión.
///
/// Cada destino apunta a una rama del `StatefulShellRoute` (`buildBranches`)
/// y solo se muestra si el rol tiene alguno de sus permisos.
class AdminRail extends StatelessWidget {
  const AdminRail({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _destinations = <(IconData, String, int, List<String>)>[
    (Icons.space_dashboard_outlined, 'Inicio', 0, []),
    (Icons.calendar_month_outlined, 'Turnos', 1, [Permissions.AGENDA_VER]),
    (Icons.groups_outlined, 'Clientes', 2, [Permissions.CLIENTES_VER]),
    (Icons.credit_card, 'Pagos', 3, [Permissions.PAGOS_VER]),
    (Icons.map_outlined, 'Mapa', 4, [Permissions.MAPA_VER]),
    (Icons.settings_outlined, 'Configuración', 5, [Permissions.CONFIGURACION_VER]),
    (Icons.manage_accounts_outlined, 'Usuarios', 6, [Permissions.ADMINISTRADORES_VER, Permissions.ROLES_VER]),
  ];

  String _initials() {
    final person = sl<AuthCubit>().state.userCredential?.admin?.person;
    if (person == null) return '';
    String first(String s) => s.trim().isEmpty ? '' : s.trim().substring(0, 1).toUpperCase();
    return '${first(person.name)}${first(person.lastName)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = _destinations
        .where((destination) => destination.$4.isEmpty || Permissions.canAny(destination.$4))
        .toList();

    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.surfaceContainerHigh)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 16),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Text(
              'T',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 28),
          for (final (i, (icon, label, branch, _)) in visible.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            _RailItem(
              icon: icon,
              label: label,
              selected: shell.currentIndex == branch,
              onTap: () => shell.goBranch(branch, initialLocation: shell.currentIndex == branch),
            ),
          ],
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            position: PopupMenuPosition.over,
            offset: const Offset(72, -8),
            onSelected: (value) {
              if (value == 'logout') sl<AuthCubit>().signOutGoogle();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                ),
              ),
            ],
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
                border: Border.all(color: scheme.outlineVariant, width: 2),
              ),
              child: Text(
                _initials(),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            width: 88,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected ? scheme.secondaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
