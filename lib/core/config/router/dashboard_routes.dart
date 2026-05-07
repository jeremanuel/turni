import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../../../presentation/auth/check_status_page.dart';

List<RouteBase> dashboardRoutes() => [
  GoRoute(
    path: AppRoutes.ROOT_ROUTE.path,
    name: AppRoutes.ROOT_ROUTE.name,
    builder: (context, state) => AuthCheck(), // AuthCheck si lo necesitas
  ),
  GoRoute(
    path: AppRoutes.LOGIN_ROUTE.path,
    name: AppRoutes.LOGIN_ROUTE.name,
    builder: (context, state) => const SizedBox(), // LoginPage si lo necesitas
  ),
  
];