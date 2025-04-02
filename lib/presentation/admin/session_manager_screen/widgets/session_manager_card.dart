
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/entities/session.dart';
import '../../../../main.dart';
import '../bloc/session_manager_bloc.dart';
import '../bloc/session_manager_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SessionManagerCard extends StatefulWidget {
  const SessionManagerCard({
    super.key, 
    required this.session, 
    required this.physicalPartition,  
    this.onReserve, 
    this.onDelete, 
    this.hasFocus = false
  });

  final Session session;
  final PhysicalPartition physicalPartition;
  final Function? onReserve;
  final Function? onDelete;
  final bool hasFocus;

  @override
  State<SessionManagerCard> createState() => _SessionManagerCardState();
}

class _SessionManagerCardState extends State<SessionManagerCard>  {

  final dropdownController = DropdownController(); 

  @override
  Widget build(BuildContext context) {

    if(widget.session.isReserved) return ReservedSessionCard(session: widget.session, hasFocus: widget.hasFocus,);

    return NotReservedSessionCard(session: widget.session, onReserve: widget.onReserve, onDelete: widget.onDelete, hasFocus: widget.hasFocus); 

  }
}


class ReservedSessionCard extends StatelessWidget {

  final Session session;
  final bool hasFocus;
  const ReservedSessionCard({super.key, required this.session, this.hasFocus = false});

  getColor(context){

    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    
    if(!hasFocus) return color;

    HSLColor hslColor = HSLColor.fromColor(color);

    double newLightness = (hslColor.lightness + 0.1).clamp(0.0, 1.0);
  
    // Devolver el nuevo color en formato RGB
    return hslColor.withLightness(newLightness).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 190,
        decoration: BoxDecoration(
            color: getColor(context),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Theme.of(context).colorScheme.primary,                  
              width: 16,
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
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
                        Expanded(child: Text(session.client!.person!.fullName, style: const TextStyle(overflow: TextOverflow.ellipsis, fontSize: 12),)),
                      ],
                    ),
              
                  ],
                ),
              ),
            ),
            if(session.physicalPartition?.clubPartition?.clubType != null)
              ...[
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text("${session.physicalPartition!.clubPartition!.clubType!.name} | ${session.physicalPartition!.physicalIdentifier.toString()}"),
                )
              ]
          ],
        ),
      );
  }
}


class NotReservedSessionCard extends StatelessWidget {

  final Session session;
  final Function? onReserve;
  final Function? onDelete;
  final bool hasFocus;

  const NotReservedSessionCard({super.key, required this.session,  this.onReserve, this.onDelete, this.hasFocus = false});

    getColor(context){

    final color = Theme.of(context).colorScheme.tertiaryContainer;
    
    if(!hasFocus) return color;

    HSLColor hslColor = HSLColor.fromColor(color);

    double newLightness = (hslColor.lightness + 0.1).clamp(0.0, 1.0);
  
    // Devolver el nuevo color en formato RGB
    return hslColor.withLightness(newLightness).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 190,
        decoration: BoxDecoration(
            color: getColor(context),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: hasFocus ? Border(
              top: BorderSide(color: Theme.of(context).colorScheme.primary),
              right: BorderSide(color: Theme.of(context).colorScheme.primary),
              bottom: BorderSide(color: Theme.of(context).colorScheme.primary) 
            ) : null
            ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(                
                color: Theme.of(context).colorScheme.tertiary,
              ),
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
                      onReserve?.call();
                      context.goNamed("SESSION_MANAGER_RESERVE", pathParameters: {"idSession":session.sessionId.toString()});
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
                  if(session.physicalPartition?.clubPartition?.clubType != null)
                    ...[Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text("${session.physicalPartition!.clubPartition!.clubType!.name} | ${session.physicalPartition!.physicalIdentifier.toString()}"),
                    ), 
                  const  Spacer()],
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      showDialog(
                      context: context,
                       builder: (dialogContext) {
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
                                      FilledButton(
                                        onPressed: (){ 
                                          context.read<SessionManagerBloc>().add(DeleteSession(session.sessionId)); 
                                          Navigator.pop(dialogContext); 
                                          onDelete?.call(); 
                                        }, 
                                        child: const Text("Eliminar")
                                      ),                                      
                                      OutlinedButton(
                                        onPressed: (){  
                                          Navigator.pop(dialogContext);
                                        }, 
                                        child: const Text("Cancelar")
                                      )
                                    ],
                                  )                                  
                                ],
                              ),
                            )),
                        );
                      },);
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