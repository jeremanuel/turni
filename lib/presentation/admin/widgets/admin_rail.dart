import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/services/app_version/app_version.dart';
import '../../../core/presentation/components/onboarding/tour_anchor.dart';
import '../../core/cubit/auth/auth_cubit.dart';
import '../guides/guides_dialog.dart';
import '../notifications/notifications_panel.dart';
import 'admin_destinations.dart';

/// Iniciales del admin logueado (avatar del menú lateral y del menú «Más»).
String adminInitials() {
  final person = sl<AuthCubit>().state.userCredential?.admin?.person;
  if (person == null) return '';
  String first(String s) => s.trim().isEmpty ? '' : s.trim().substring(0, 1).toUpperCase();
  return '${first(person.name)}${first(person.lastName)}';
}

/// Menú lateral del admin (diseño "Gestor de turnos: layout, menú lateral y
/// panel del turno"): logo, destinos con ícono y texto siempre visibles, y el
/// avatar del admin abajo con perfil y cerrar sesión.
///
/// Cada destino apunta a una rama del `StatefulShellRoute` (`buildBranches`)
/// y solo se muestra si el rol tiene alguno de sus permisos.
class AdminRail extends StatelessWidget {
  const AdminRail({super.key, required this.shell});

  final StatefulNavigationShell shell;

  String _initials() => adminInitials();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = AdminDestinations.visible(AdminDestinations.rail);

    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.surfaceContainerHigh)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 16),
      child: Column(
        children: [
          // El isotipo de Turni (el mismo del login), en el color primario.
          SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SvgPicture.asset(
                'assets/img/isotype_white.svg',
                width: 40,
                height: 40,
                semanticsLabel: 'Turni',
                colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(height: 28),
          for (final (i, destination) in visible.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            TourAnchor(
              id: destination.anchor,
              child: _RailItem(
                icon: destination.icon,
                label: destination.label,
                selected: shell.currentIndex == destination.branch,
                onTap: () => shell.goBranch(destination.branch, initialLocation: shell.currentIndex == destination.branch),
              ),
            ),
          ],
          const Spacer(),
          const GuidesButton(),
          const SizedBox(height: 4),
          const NotificationsButton(),
          const SizedBox(height: 12),
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            position: PopupMenuPosition.over,
            offset: const Offset(72, -8),
            onSelected: (value) {
              if (value == 'logout') sl<AuthCubit>().signOutGoogle();
              if (value == 'platform_clubs') context.push(AppRoutes.PLATFORM_CLUBS_ROUTE.path);
            },
            itemBuilder: (_) => [
              if (sl<AuthCubit>().isPlatformOperator())
                const PopupMenuItem(
                  value: 'platform_clubs',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.add_business_outlined),
                    title: Text('Alta de establecimiento'),
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                ),
              ),
              PopupMenuItem(
                enabled: false,
                height: 32,
                child: Text('Versión ${AppVersion.label}', style: Theme.of(context).textTheme.bodySmall),
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
