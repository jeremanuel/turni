import 'package:flutter/material.dart';

import '../../../core/utils/permissions.dart';
import 'tabs/admins_tab.dart';
import 'tabs/roles_tab.dart';
import '../../../core/presentation/components/onboarding/tour_anchor.dart';

/// Usuarios del panel: administradores del club (invitar, cambiar rol,
/// deshabilitar) y roles y permisos. Cada pestaña aparece según el rol.
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = <(String, String, Widget)>[
      if (Permissions.can(Permissions.ADMINISTRADORES_VER)) ('Administradores', 'users.tab.admins', const AdminsTab()),
      if (Permissions.can(Permissions.ROLES_VER)) ('Roles y permisos', 'users.tab.roles', const RolesTab()),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        appBar: AppBar(
          title: const Text('Usuarios'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (final (i, (label, anchor, _)) in tabs.indexed) TourAnchor(id: anchor, onActivate: TourAnchor.selectTab(i), child: Tab(text: label)),
            ],
          ),
        ),
        body: TabBarView(children: [for (final (_, _, tab) in tabs) tab]),
      ),
    );
  }
}
