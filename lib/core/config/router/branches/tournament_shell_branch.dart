import 'package:go_router/go_router.dart';

import '../../../../presentation/admin/tournaments/tournament_detail_page.dart';
import '../../../../presentation/admin/tournaments/tournament_form_page.dart';
import '../../../../presentation/admin/tournaments/tournaments_page.dart';
import '../app_routes.dart';

/// Torneos: listado (con ranking y categorías), alta, detalle y edición.
StatefulShellBranch tournamentShellBranch() {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.TOURNAMENTS_ROUTE.path,
        name: AppRoutes.TOURNAMENTS_ROUTE.name,
        builder: (context, state) => const TournamentsPage(),
        routes: [
          GoRoute(
            path: 'new',
            name: AppRoutes.TOURNAMENT_NEW_ROUTE.name,
            builder: (context, state) => const TournamentFormPage(),
          ),
          GoRoute(
            path: ':tournamentId',
            name: AppRoutes.TOURNAMENT_DETAIL_ROUTE.name,
            builder: (context, state) => TournamentDetailPage(tournamentId: int.parse(state.pathParameters['tournamentId']!)),
            routes: [
              GoRoute(
                path: 'edit',
                name: AppRoutes.TOURNAMENT_EDIT_ROUTE.name,
                builder: (context, state) => TournamentFormPage(tournamentId: int.parse(state.pathParameters['tournamentId']!)),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
