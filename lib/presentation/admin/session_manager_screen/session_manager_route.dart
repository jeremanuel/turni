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
      child: MultiBlocListener(
        listeners: [
          BlocListener<SessionManagerBloc, SessionManagerState>(
            listenWhen: (previous, current) => previous.error != current.error && current.error != null,
            listener: (context, state) {

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  width: 300,
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  behavior: SnackBarBehavior.floating,
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Theme.of(context).colorScheme.onErrorContainer,),
                      const SizedBox(width: 8,),
                      Text(state.error!.message, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),)
                    ],
                  )
                )
              );

              context.goNamed(AppRoutes.SESSION_MANAGER_ROUTE['name']!);
            },
          ),
          // Error al aceptar/rechazar una solicitud (ej. 409 STALE_STATUS).
          // A propósito no navega a ningún lado: la lista ya se refresca
          // desde el bloc antes de emitir este error (ver
          // `SessionManagerBloc.AcceptSessionRequest`/`RejectSessionRequest`),
          // así que solo hace falta avisarle al admin.
          BlocListener<SessionManagerBloc, SessionManagerState>(
            listenWhen: (previous, current) => previous.actionError != current.actionError && current.actionError != null,
            listener: (context, state) {

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  width: 300,
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  behavior: SnackBarBehavior.floating,
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Theme.of(context).colorScheme.onErrorContainer,),
                      const SizedBox(width: 8,),
                      Flexible(child: Text(state.actionError!.message, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),)),
                    ],
                  )
                )
              );
            },
          ),
        ],
        child: BlocBuilder<SessionManagerBloc, SessionManagerState>(
          buildWhen: (previous, current) => previous.isFirstLoad != current.isFirstLoad,
          builder: (context, sessionManagerState) {

            if(routeName == "ADD_SESSIONS_MASIVE"){
              return child;
            }

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
      ),
    );
  }
}