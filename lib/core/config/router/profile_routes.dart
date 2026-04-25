import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/admin/profile_manager/profile_page.dart';

List<StatefulShellBranch> profileBranches() => [
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/profile',
        builder: (context, state) => SizedBox(),
      ),
    ],
  ),
];