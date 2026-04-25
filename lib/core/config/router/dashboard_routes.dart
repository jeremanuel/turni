import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/auth/check_status_page.dart';

List<RouteBase> dashboardRoutes() => [
  GoRoute(
    path: '/',
    builder: (context, state) => AuthCheck(), // AuthCheck si lo necesitas
  ),
  GoRoute(
    path: '/login',
    builder: (context, state) => const SizedBox(), // LoginPage si lo necesitas
  ),
  
];