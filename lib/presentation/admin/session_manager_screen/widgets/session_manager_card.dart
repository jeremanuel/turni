
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/router/app_routes.dart';
import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/entities/session.dart';
import '../bloc/session_manager_bloc.dart';
import '../bloc/session_manager_event.dart';
import 'close_session_dialog.dart';

class SessionManagerCard extends StatefulWidget {
  const SessionManagerCard({
    super.key, 
    required this.session, 
    required this.physicalPartition,  
    this.onReserve, 
    this.onDelete, 
    this.hasFocus = false, 
    required this.height
  });

  final Session session;
  final PhysicalPartition physicalPartition;
  final Function? onReserve;
  final Function? onDelete;
  final bool hasFocus;
  final double height;

  @override
  State<SessionManagerCard> createState() => _SessionManagerCardState();
}

class _SessionManagerCardState extends State<SessionManagerCard>  {

  final dropdownController = DropdownController(); 

  @override
  Widget build(BuildContext context) {

    if(widget.session.isReserved) return ReservedSessionCard(session: widget.session, hasFocus: widget.hasFocus, height: widget.height,);

    return NotReservedSessionCard(session: widget.session, onReserve: widget.onReserve, onDelete: widget.onDelete, hasFocus: widget.hasFocus); 

  }
}


class ReservedSessionCard extends StatelessWidget {

  final Session session;
  final bool hasFocus;
  final double height;
  const ReservedSessionCard({super.key, required this.session, this.hasFocus = false, required this.height});

  bool get isFixedReservedSession => session.clubTypeName == "FIXED_SESSION";

  getColor(context){

    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = isFixedReservedSession
        ? Color.alphaBlend(
            colorScheme.secondary.withValues(alpha: 0.08),
            colorScheme.surfaceContainerHigh,
          )
        : colorScheme.surfaceContainerHigh;
    
    if(!hasFocus) return baseColor;

    HSLColor hslColor = HSLColor.fromColor(baseColor);

    double newLightness = (hslColor.lightness + 0.1).clamp(0.0, 1.0);
  
    // Devolver el nuevo color en formato RGB
    return hslColor.withLightness(newLightness).toColor();
  }

  // Calcular porcentaje pagado
  double _getPaymentPercentage() {
    if (session.totalPrice <= 0) return 0;
    return (session.totalPayedPrice / session.totalPrice).clamp(0, 1);
  }

  // Obtener color de barra según estado de pago


  @override
  Widget build(BuildContext context) {

    final colorScheme = Theme.of(context).colorScheme;
    final percentage = _getPaymentPercentage();
    final progressColor = isFixedReservedSession ? colorScheme.secondary : colorScheme.primary;
    final progressBackgroundColor = isFixedReservedSession ? colorScheme.secondaryContainer : colorScheme.primaryContainer;

    return Ink(
        width: 190,
        decoration: BoxDecoration(
            color: getColor(context),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
        ),
        child: InkWell(
          onTap: () {
            context.goNamed(AppRoutes.SESSION_MANAGER_RESERVE_ROUTE.name, pathParameters: {"idSession":session.sessionId.toString()});
          },
          child: Tooltip(
            message: '${(percentage * 100).toStringAsFixed(0)}% pagado • \$${session.totalPayedPrice.toStringAsFixed(0)} / \$${session.totalPrice.toStringAsFixed(0)}',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra vertical de progreso
                Stack(
                  children: [
                    Container(
                      color: progressBackgroundColor,
                      width: 16,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: progressColor,
                        width: 16,
                        height: (percentage * height).toDouble(), // Altura proporcionalmente a disponible
                      ),
                    ),
                  ],
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric( horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 4,
                          children: [
                            const Icon(Icons.access_time, size: 18,),
                            Text(
                              "${DateFormat.jm().format(session.startTime)} - ${DateFormat.jm().format(session.endTime)}",
                            ),
                          
                            const Spacer(),
                            IconButton(
                        icon: const Icon(Icons.close, size: 18,),
                        onPressed: () async {
                          final action = await showCloseSessionDialog(
                            context,
                            isReserved: true,
                          );

                          if (!context.mounted || action == null) {
                            return;
                          }

                          if (action == CloseSessionAction.cancelReservation) {
                            await context
                                .read<SessionManagerBloc>()
                                .cancelSessionReservation(session.sessionId);
                            return;
                          }

                          context
                              .read<SessionManagerBloc>()
                              .add(DeleteSession(session.sessionId));
                        },
                      )
                          ],
                        ),
                          if (isFixedReservedSession)
                              Tooltip(
                                message: 'Turno fijo',
                                child: Icon(
                                  Icons.event_repeat,
                                  size: 16,
                                  color: colorScheme.secondary,
                                ),
                              ),
                        const Spacer(),                  
                        Row(
                          spacing: 4,
                          children: [
                            const Icon(Icons.person, size: 18),
                            Expanded(child: Text(session.client!.person!.fullName, style: const TextStyle(overflow: TextOverflow.ellipsis, fontSize: 12),)),
                            IconButton(
                              onPressed: () {
                              context.goNamed(AppRoutes.CLIENT_ROUTE.name, pathParameters: {"clientId":session.client!.clientId!});
                              
                            }, icon: const Icon(Icons.open_in_new_rounded, size: 18,))
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
          ),
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
    return Ink(
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
        child: InkWell(
          onTap: () {
            onReserve?.call();
            context.goNamed(AppRoutes.SESSION_MANAGER_RESERVE_ROUTE.name, pathParameters: {"idSession":session.sessionId.toString()});
          },
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
                        const Icon(Icons.access_time, size: 18,),
                        Text(
                          "${DateFormat.jm().format(session.startTime)} - ${DateFormat.jm().format(session.endTime)}",
                        ),
                      ],
                    ),
                    const Spacer(),
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
                      icon: const Icon(Icons.close, size: 18,),
                      onPressed: () async {
                        final action = await showCloseSessionDialog(
                          context,
                          isReserved: false,
                        );

                        if (!context.mounted || action != CloseSessionAction.deleteSession) {
                          return;
                        }

                        context
                            .read<SessionManagerBloc>()
                            .add(DeleteSession(session.sessionId));
                      },
                    ),
           
                  ],
                ),
              )
            ],
          ),
        ),
      );
  }
}