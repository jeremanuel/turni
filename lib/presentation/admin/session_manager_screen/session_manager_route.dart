import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_router.dart';
import '../../../core/config/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/responsive_builder.dart';
import '../bloc/session_manager_bloc.dart';
import '../bloc/session_manager_state.dart';
import 'sessions_manager_desktop.dart';
import 'widgets/agenda_container.dart';
import 'package:go_router/go_router.dart';


/// Widget que Crea la instancia de BLOC con blocprovider.
class SessionManagerRoute extends StatelessWidget {

  final int? sessionId;
  final Widget child;
  final String? routeName;

  const SessionManagerRoute({super.key, this.sessionId, required this.child, this.routeName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SessionManagerBloc>(param1: sessionId),
      child: BlocConsumer<SessionManagerBloc, SessionManagerState>(
        listenWhen: (previous, current) => previous.error != current.error && current.error != null,
        listener: (context, state) {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: SizedBox(
                height: 50,
                child: Center(child: Text(state.error!.message))
              ),
              width: 600,
              padding: const EdgeInsets.only(bottom: 8),
            )
          );

          context.goNamed(AppRoutes.SESSION_MANAGER_ROUTE['name']!);
        },
        buildWhen: (previous, current) => previous.isFirstLoad != current.isFirstLoad,
        builder: (context, sessionManagerState) {

          if (sessionManagerState.isFirstLoad) {
            return const Center(
                child: CircularProgressIndicator(),
            );
          }

          if (ResponsiveBuilder.isDesktop(context)) {
            return SessionManagerDesktop(
              sideChild: child,
              sessionId: sessionId,
            );
          }

          if (routeName == "SESSION_MANAGER") {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: AgendaContainer(),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          );
        }
      ),
    );
  }
}