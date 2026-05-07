import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../../../presentation/admin/profile_manager/profile_page.dart';

List<StatefulShellBranch> profileBranches() => [
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.PROFILE_ROUTE.path,
        name: AppRoutes.PROFILE_ROUTE.name,
        builder: (context, state) => SizedBox(),
      ),
    ],
  ),
];