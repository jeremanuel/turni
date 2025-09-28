import 'package:go_router/go_router.dart';
import '../../../presentation/client/profile_manager_screen/profile/profile_page.dart';

List<StatefulShellBranch> profileBranches() => [
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  ),
];