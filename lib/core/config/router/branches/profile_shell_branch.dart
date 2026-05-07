import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_routes.dart';
import '../../../../presentation/admin/profile_manager/profile_page.dart';

StatefulShellBranch profileShellBranch() {
  return StatefulShellBranch(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ProfilePage(child: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.PROFILE_SETTINGS_ROUTE.path,
              name: AppRoutes.PROFILE_SETTINGS_ROUTE.name,
              builder: (context, state) => SizedBox(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.PROFILE_SECURITY_ROUTE.path,
              name: AppRoutes.PROFILE_SECURITY_ROUTE.name,
              builder: (context, state) => SizedBox(),
            ),
          ]),
        ],
      ),
    ],
  );
}
