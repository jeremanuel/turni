import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../core/utils/types/time_interval.dart';
import '../../../../domain/entities/session.dart';
import '../bloc/create_sesssions_form_bloc.dart';
import '../create_sessions_form.dart';
import 'session_form_dropdown.dart';

class AgendaEditCard extends StatelessWidget {
  
  AgendaEditCard({super.key, required this.session});

  final Session session;
  final dropdownController = DropdownController(); 

  @override
  Widget build(BuildContext context) {
    return DropdownWidget(
      aligned: const Aligned(follower: Alignment.topLeft, target: Alignment.topRight, offset: Offset(8,0)),
      dropdownController: dropdownController,
      menuWidget: SessionFormDropdown(
        onSave: (initialTime, duration){
          dropdownController.hide!();
          sl<CreateSesssionsFormBloc>().add(
            EditSession(session, session.copyWith(startTime: DateTime.now().applied(initialTime), duration: "${duration.hour}:${duration.minute}"))
          );
        },
        onCancel: () => dropdownController.hide!(),
        session: session
      ),
      child: buildCard(context),
    );
  }

  Container buildCard(BuildContext context) {
    return Container(
            width: 190,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12)
                ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Theme.of(context).colorScheme.primary,
                  width: 16,
                ),
                const SizedBox(
                  width: 4,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time),
                          Text(
                            "${DateFormat.jm().format(session.startTime)} - ${DateFormat.jm().format(session.endTime)}",
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (session.clientId == null)
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text("Reservar"),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          dropdownController.show!();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {},
                      ),
                      const Spacer(),
                    ],
                  ),
                )
              ],
            ),
          );
  }
}