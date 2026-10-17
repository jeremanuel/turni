import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/services/app_version/app_version.dart';
import '../../core/cubit/auth/auth_cubit.dart';
import '../widgets/admin_destinations.dart';
import '../widgets/admin_rail.dart';

/// Barra de navegación inferior del admin en el celular: los primeros
/// destinos que el rol puede ver y, si no entran todos, «Más» con el resto.
class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final visible = AdminDestinations.visible(AdminDestinations.mobile);
    final needsMore = visible.length > AdminDestinations.mobileBarSlots + 1;
    final inBar = needsMore ? visible.take(AdminDestinations.mobileBarSlots).toList() : visible;
    final inMore = needsMore ? visible.skip(AdminDestinations.mobileBarSlots).toList() : <AdminDestination>[];

    var selected = inBar.indexWhere((d) => d.branch == shell.currentIndex);
    if (selected < 0) selected = needsMore && inMore.any((d) => d.branch == shell.currentIndex) ? inBar.length : 0;

    if (inBar.length + (needsMore ? 1 : 0) < 2) return const SizedBox.shrink();

    return NavigationBar(
      selectedIndex: selected,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        if (index < inBar.length) {
          final branch = inBar[index].branch;
          shell.goBranch(branch, initialLocation: shell.currentIndex == branch);
        } else {
          showAdminMoreSheet(context, shell: shell, destinations: inMore);
        }
      },
      destinations: [
        for (final d in inBar) NavigationDestination(icon: Icon(d.icon), label: d.label),
        if (needsMore) const NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Más'),
      ],
    );
  }
}

/// Menú «Más»: los destinos que no entran en la barra, la cuenta y la versión.
Future<void> showAdminMoreSheet(
  BuildContext context, {
  required StatefulNavigationShell shell,
  required List<AdminDestination> destinations,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      final text = Theme.of(sheetContext).textTheme;
      final admin = sl<AuthCubit>().state.userCredential?.admin;
      final person = admin?.person;
      final role = sl<AuthCubit>().state.userCredential?.adminAccess?.role?.name;

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text(adminInitials()),
              ),
              title: Text(person == null ? '' : '${person.name} ${person.lastName}'.trim()),
              subtitle: role == null ? null : Text(role),
            ),
            const Divider(height: 1),
            for (final d in destinations)
              ListTile(
                leading: Icon(d.icon),
                title: Text(d.label),
                selected: shell.currentIndex == d.branch,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  shell.goBranch(d.branch, initialLocation: shell.currentIndex == d.branch);
                },
              ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text('Cerrar sesión', style: TextStyle(color: scheme.error)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                sl<AuthCubit>().signOutGoogle();
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text('Versión ${AppVersion.label}', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
      );
    },
  );
}
