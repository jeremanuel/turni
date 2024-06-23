import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../domain/entities/session.dart';

class SessionManagerCard extends StatefulWidget {
  const SessionManagerCard({super.key, required this.session});

  final Session session;

  @override
  State<SessionManagerCard> createState() => _SessionManagerCardState();
}

class _SessionManagerCardState extends State<SessionManagerCard> {

  final dropdownController = DropdownController(); 

  @override
  Widget build(BuildContext context) {

    if(widget.session.isReserved) return ReservedSessionCard(session: widget.session);

    return NotReservedSessionCard(session: widget.session); 

  }
}


class ReservedSessionCard extends StatelessWidget {

  final Session session;

  const ReservedSessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 190,
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12)),
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
                  Row(
                    children: [
                      const Icon(Icons.person),
                      SizedBox(
                        width: 90,
                        child: Text(session.client!.person!.fullName, style: TextStyle(overflow: TextOverflow.ellipsis, fontSize: 12),)),
                    ],
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


class NotReservedSessionCard extends StatelessWidget {

  final Session session;


  const NotReservedSessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 190,
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Theme.of(context).colorScheme.tertiary,
              width: 16,
            ),
            Padding(
              padding: const EdgeInsets.all( 8.0),
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
                
                  OutlinedButton(
                    onPressed: () {
                      context.go("/session_manager/reserve");
                    },
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
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      showDialog(
                      context: context,
                       builder: (context) {
                        return  Dialog(
                          
                          child: SizedBox(
                            height: 150,
                            width: 150,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Text("Seguro que desea eliminar el turno?"),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      FilledButton(onPressed: (){}, child: const Text("Eliminar")),                                      
                                      OutlinedButton(onPressed: (){}, child: const Text("Cancelar"))
                                    ],
                                  )                                  
                                ],
                              ),
                            )),
                        );
                      },);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      context.go("/session_manager/edit");
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      );
  }
}