import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/admin/profile_manager/profile_page.dart';

StatefulShellBranch profileShellBranch() {
  return StatefulShellBranch(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ProfilePage(child: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile/settings',
              builder: (context, state) => SizedBox(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile/security',
              builder: (context, state) => SizedBox(),
            ),
          ]),
        ],
      ),
    ],
  );
}
