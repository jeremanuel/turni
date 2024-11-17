import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive_builder.dart';
import '../../../../core/utils/types/time_interval.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/entities/session.dart';
import '../../../core/pick_client/pick_client.dart';
import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReservateSession extends StatefulWidget {

  ReservateSession({super.key, required this.session, required this.physicalPartition, required this.clubPartition});

  final _formKey = GlobalKey<FormBuilderState>();

  final Session session;
  final PhysicalPartition physicalPartition;
  final ClubPartition clubPartition;

  @override
  State<ReservateSession> createState() => _ReservateSessionState();
}

class _ReservateSessionState extends State<ReservateSession> {

  bool isValid = false;
  bool isLoadingSession = false;

  @override
  void initState() {
    
    super.initState();

    
  }

  

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: FormBuilder(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        key: widget._formKey,
        onChanged: (){
          
          setState(() {
            isValid = widget._formKey.currentState!.validate(focusOnInvalid: false);
          });

        },
        child: Column(
          children: [          
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildHeader(context),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InputChip(
                          label: Text(widget.clubPartition.clubType!.name)
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        InputChip(
                            label:  Text("Cancha ${widget.physicalPartition.physicalIdentifier}")
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    PickClient(
                      name: "client",
                      isRequired:true,
                      onPressNew: () {
                  
                      },
                      onBackToSelection: () {
               
                      },
                    ),
              
              
                    
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top:16),
              child: FilledButton(
                onPressed: isValid ? (){
      
                final sessionManagerBloc = context.read<SessionManagerBloc>();
                
                final client = widget._formKey.currentState!.fields['client']?.value;

                sessionManagerBloc.add(
                   ReserveEvent(widget.session, client)
                );  
      
                context.go("/session_manager");
           } : null,
                child: const Text("Reservar Turno")
              ),
            )
          ],
        ),
      ),
    );
  }

Stack buildHeader(BuildContext context) {
  final timeInterval = TimeInterval(initialDate: widget.session.startTime,endDate: widget.session.endTime);

  return Stack(
    children: [
      SizedBox(
        height: 64,
        width: ResponsiveBuilder.isDesktop(context) ? 300 : double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Reservar turno", style:  TextStyle(fontSize: 16)),
            Text("${timeInterval.getInitialTextString()} | ${timeInterval.toStringTime()}", style: const TextStyle(fontSize: 16),),

          ],
        ),
      ),
      SizedBox(
        height: 64,
        child: IconButton(
          onPressed: (){
            context.go("/session_manager");
          }, 
          icon: const Icon(Icons.arrow_back)
        ),
      ),
      
    ],
  );
}
}
