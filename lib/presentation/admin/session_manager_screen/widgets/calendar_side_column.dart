import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/service_locator.dart';
import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';
import '../../bloc/session_manager_state.dart';
import 'session_manager_day_carrousel.dart';

class CalendarSideColumn extends StatelessWidget {
  const CalendarSideColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 80, child: SessionManagerDayCarrousel()),
        const SizedBox(
          height: 8,
        ),
        const Divider(),
        const SizedBox(
          height: 8,
        ),
        Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
            ),
            width: 300,
            child: calendarDatepicker2(context)),
        const SizedBox(
          height: 8,
        ),
        const Divider(),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 36,
              child: FilledButton(
                  onPressed: () {
                    context.go('/add_sessions');
                  }, 
                  child: const Text("Agregar Turnos")),
            ),
            SizedBox(
              height: 36,
              child: TextButton(
                  onPressed: () {},
                  child: const Text("Secondary option")),
            ),
          ],
        ),
      ],
    );
  }
}

  Widget calendarDatepicker2(BuildContext context) {
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      bloc: sl<SessionManagerBloc>(),
      buildWhen: (previous, current) => previous.currentDate != current.currentDate,
      builder: (context, state) {
        return CalendarDatePicker2(
            onValueChanged: (value) {
              sl<SessionManagerBloc>()
                  .add(SessionChangeDateEvent(value.first ?? DateTime.now()));
            },
            config: CalendarDatePicker2Config(
           
            ),
            value: [state.currentDate]);
      },
    );
  }