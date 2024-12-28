import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_routes.dart';
import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';
import '../../bloc/session_manager_state.dart';
import '../widgets/reservate_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Metodo utilizado en el pagebuilder de la ruta.
/// Se encarga de formatear los parametros, buscar el turno, y en caso de no encontrarlo, disparar un evento del sesionManagerBloc
/// Que lo busca.
/// Obtiene todo lo necesario para renderizar ReservateSession
/// Depende de SessionManagerBloc
Page<dynamic> sessionManagerReservePageBuilder(
    BuildContext context, GoRouterState state) {
  final idSession = int.parse(state.pathParameters['idSession']!);

  final session = context
      .read<SessionManagerBloc>()
      .state
      .sessions
      .firstWhereOrNull((element) => element.sessionId == idSession);


  final sessionManagerbloc = context.read<SessionManagerBloc>();

  if (session == null) {
    sessionManagerbloc.add(LoadFromSessionIdEvent(idSession, true));
    return const NoTransitionPage(child: SizedBox());
  }

  sessionManagerbloc.add(SetSelectedSession(session));

  var selectedClubPartition = sessionManagerbloc.state.selectedClubPartition;

  var physicalPartition = selectedClubPartition!.physicalPartitions!
      .firstWhereOrNull((element) =>
          element.partitionPhysicalId == session.partitionPhysicalId);

  if (physicalPartition == null) {
    selectedClubPartition = sessionManagerbloc.getNewSelectedClubPartition(
        session, sessionManagerbloc.state.clubPartitions);

    sessionManagerbloc.add(ChangeClubPartitionEvent(selectedClubPartition));

    physicalPartition = selectedClubPartition.physicalPartitions!
        .firstWhereOrNull((element) =>
            element.partitionPhysicalId == session.partitionPhysicalId);
  }

  return NoTransitionPage(
    child: BlocListener<SessionManagerBloc, SessionManagerState>(
    listenWhen: (previous, current) => previous.sessions.firstWhereOrNull((element) => element.sessionId == idSession) != current.sessions.firstWhereOrNull((element) => element.sessionId == idSession),
    listener: (context, state) {
      
      final session = state.sessions.firstWhereOrNull((element) => element.sessionId == idSession);
      
      if(session == null){
        context.goNamed(AppRoutes.SESSION_MANAGER_ROUTE.name);
      }

      
    },
    child: ReservateSession(
        session: session,
        clubPartition: selectedClubPartition!,
        physicalPartition: physicalPartition!,
      ),
  ));
}
