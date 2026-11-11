import 'package:go_router/go_router.dart';

import '../../../../presentation/admin/cash/cash_page.dart';
import '../../../../presentation/admin/cash/cash_shift_detail_page.dart';
import '../app_routes.dart';

/// Caja: puestos, movimientos, cierres y el detalle de una caja.
StatefulShellBranch cashShellBranch() {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.CASH_ROUTE.path,
        name: AppRoutes.CASH_ROUTE.name,
        builder: (context, state) => CashPage(initialTab: state.uri.queryParameters['tab']),
        routes: [
          GoRoute(
            path: 'shifts/:shiftId',
            name: AppRoutes.CASH_SHIFT_ROUTE.name,
            builder: (context, state) => CashShiftDetailPage(shiftId: state.pathParameters['shiftId']!),
          ),
        ],
      ),
    ],
  );
}
