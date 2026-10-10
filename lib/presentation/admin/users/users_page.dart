import 'package:flutter/material.dart';

import '../../../core/utils/permissions.dart';
import 'tabs/admins_tab.dart';
import 'tabs/roles_tab.dart';

/// Usuarios del panel: administradores del club (invitar, cambiar rol,
/// deshabilitar) y roles y permisos. Cada pestaña aparece según el rol.
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = <(String, Widget)>[
      if (Permissions.can(Permissions.ADMINISTRADORES_VER)) ('Administradores', const AdminsTab()),
      if (Permissions.can(Permissions.ROLES_VER)) ('Roles y permisos', const RolesTab()),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        appBar: AppBar(
          title: const Text('Usuarios'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final (label, _) in tabs) Tab(text: label)],
          ),
        ),
        body: TabBarView(children: [for (final (_, tab) in tabs) tab]),
      ),
    );
  }
}
