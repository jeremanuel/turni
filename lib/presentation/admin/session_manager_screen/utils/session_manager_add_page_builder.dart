import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/types/time_interval.dart';
import '../../../../main.dart';
import '../bloc/session_manager_bloc.dart';
import '../bloc/session_manager_event.dart';
import '../../create_session_screen/create_sessions_screen.dart';
import '../widgets/add_new_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


/// Metodo utilizado en el pagebuilder de la ruta.
/// Se encarga de formatear los parametros, para redenderizar parcialmente el widget AddNewSession
/// Depende de SessionManagerBloc
Page<dynamic> sessionManagerAddPageBuilder(BuildContext context,GoRouterState state) {
  
  final idPhysicalPartition = state.pathParameters['idPhysicalPartition'];

  final startTime = state.uri.queryParameters['start'];
  final endTime = state.uri.queryParameters['end'];

  DateFormat dateFormat = DateFormat("HH:mm");
  
  final startDate = startTime != null ? dateFormat.parse(startTime) : null;
  final endDate = endTime != null ? dateFormat.parse(endTime) : null;
  final selectedDay = context.read<SessionManagerBloc>().state.currentDate;

  context.read<SessionManagerBloc>().add(SetSelectedSession(null));

  final timeInterval = TimeInterval(
    initialDate: startDate != null ? selectedDay.copyWith(minute:startDate.minute, hour: startDate.hour ) : null,
    endDate: endDate != null ? selectedDay.copyWith(minute:endDate.minute, hour: endDate.hour ) : null
  );

  return NoTransitionPage(
    child: AddNewSession(
      context: context,
      idPhysicalPartition: int.parse(idPhysicalPartition!), 
      selectedTimeInterval: timeInterval
    )
  );
}