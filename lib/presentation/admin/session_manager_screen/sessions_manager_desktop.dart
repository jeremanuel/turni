import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/session_manager_bloc.dart';
import 'bloc/session_manager_state.dart';
import 'widgets/agenda_container.dart';

class SessionManagerDesktop extends StatelessWidget {
  final Widget sideChild;
  final int? sessionId;
  
  const SessionManagerDesktop({
    super.key,
    required this.sideChild,
    this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      buildWhen: (previous, current) => previous.isFirstLoad != current.isFirstLoad,
      builder: (context, state) {          
        return buildDesktopManager(context);
      },
    );
  }

  Padding buildDesktopManager(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: AgendaContainer(),
          ),
          const VerticalDivider(),
          const SizedBox(
            width: 16,
          ),
          SizedBox(width: 300, child: sideChild)
        ],
      ),
    );
  }

}
