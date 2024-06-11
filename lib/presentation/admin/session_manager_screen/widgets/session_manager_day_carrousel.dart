import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../core/dates_carrousel/dates_carrousel.dart';

import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';
import '../../bloc/session_manager_state.dart';

class SessionManagerDayCarrousel extends StatelessWidget {
  const SessionManagerDayCarrousel({super.key, this.width = 300});

  final double width;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      bloc: sl<SessionManagerBloc>(),
      builder: (context, state) {
        return DatesCarrousel(
          datesCarrouselController: sl<SessionManagerBloc>().datesCarrouselController ,
          initialDate: state.currentDate,
          containerWidth: width,
          onSelect: (date) {
            sl<SessionManagerBloc>().add(SessionChangeDateEvent(date));
          },
        );
      },
    );
  }
}