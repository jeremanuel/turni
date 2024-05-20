import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/service_locator.dart';
import '../../domain/entities/club_type.dart';
import 'cubit/session_cubit.dart';

class SessionFeedPage extends StatelessWidget {
  final ClubType clubType;
  final whiteColor = const TextStyle(color: Colors.white);
  late final SessionCubit sessionCubit;

  SessionFeedPage({super.key, required this.clubType}) {
    sessionCubit = sl<SessionCubit>();
    sessionCubit.loadSessions(clubType);
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color.fromRGBO(240, 239, 242, 1);

    return BlocBuilder<SessionCubit, SessionState>(
        bloc: sessionCubit,
        builder: (context, state) {
          return Scaffold(
              appBar: AppBar(
                title: Text(state.isLoading
                    ? 'Loading'
                    : (state.sessions.isNotEmpty)
                        ? 'Turnos de ${clubType.name}'
                        : 'No hay turnos de ${clubType.name}'),
              ),
              backgroundColor: backgroundColor,
              body: SizedBox(
                height: 400,
                child: ListView(
                  children: getListItemView(state),
                ),
              ));
        });
  }

  List<Widget> getListItemView(SessionState state) {
    if (state.isLoading) return [const Text('Loading')];

    return state.sessions
        .map((session) => Container(
              color: const Color.fromRGBO(159, 121, 242, 1),
              child: Column(
                children: [
                  Text(
                    'Empieza: ${session.startTime.toString()}',
                    style: whiteColor,
                  ),
                  Text(
                    'Precio: ${session.duration}',
                    style: whiteColor,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ))
        .toList();
  }
}
