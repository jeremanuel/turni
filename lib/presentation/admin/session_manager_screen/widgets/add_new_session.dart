import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../core/utils/types/time_interval.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/person.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/entities/session.dart';
import '../../../../domain/repositories/admin_repository.dart';
import '../../../core/custom_time_picker.dart';
import '../../../core/pick_client/pick_client.dart';
import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';

class AddNewSession extends StatefulWidget {
  AddNewSession(
      {super.key,
      required int idPhysicalPartition,
      required this.selectedTimeInterval})
      : clubPartition = _findPhysicalPartition(idPhysicalPartition) {

        physicalPartition = clubPartition.physicalPartitions!.firstWhere(
          (element) => element.partitionPhysicalId == idPhysicalPartition,
        );

        duration = physicalPartition.durationInMinutes != null ? Duration(minutes: physicalPartition.durationInMinutes!) : selectedTimeInterval.getDuration();
  } 

  late final PhysicalPartition physicalPartition;
  final ClubPartition clubPartition;
  final TimeInterval selectedTimeInterval;
  late final Duration? duration;
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  static ClubPartition _findPhysicalPartition(int idPhysicalPartition) {
    return sl<SessionManagerBloc>().state.clubPartitions.firstWhere((element) {
      final index = element.physicalPartitions!.indexWhere(
        (element) => element.partitionPhysicalId == idPhysicalPartition,
      );

      return index != -1;
    });
  }

  @override
  State<AddNewSession> createState() => _AddNewSessionState();
}

class _AddNewSessionState extends State<AddNewSession> {

  bool isValid = true;

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
                            label: Text("Cancha ${widget.physicalPartition.physicalIdentifier}")
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    PickClient(
                      name: "client",
                      onPressNew: () {
                        setState(() {
                          isValid = widget._formKey.currentState!.validate(focusOnInvalid: false);
                        });
                      },
                      onBackToSelection: () {
                        setState(() {
                          isValid = widget._formKey.currentState!.validate(focusOnInvalid: false);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text("Hora de inicio"),
                    const SizedBox(height: 16),
                    CustomTimePicker(
                      name: "initialTime",
                      initialHours: widget.selectedTimeInterval.initialDate!.hour.toString(),
                      initialMinutes: widget.selectedTimeInterval.initialDate!.minute.toString(),
                    ),
                    const SizedBox(height: 16),
                    const Text("Duracion"),
                    const SizedBox(height: 16),
                    CustomTimePicker(
                      name: "duration",
                      initialHours: widget.duration?.inHours.toString(),
                      initialMinutes:
                          (widget.duration!.inMinutes - widget.duration!.inHours * 60).toString(),
                      
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 220,
                      child: FormBuilderTextField(
                        name: "price",
                        decoration: InputDecoration(
                          prefix: Text("\$"),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          labelText: "Precio",                                        
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    )
                    
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top:16),
              child: FilledButton(
                onPressed: isValid ? (){
      
                  final sessionManagerBloc = sl<SessionManagerBloc>();
      
                  final currentDate = sessionManagerBloc.state.currentDate;
      
                  final values = widget._formKey.currentState?.instantValue;
           
                  TimeOfDay duration = values!['duration'];
      
                  final newSession = Session(
                    sessionId: -1,
                    createdAt: DateTime.now(),
                    startTime: currentDate.applied(values['initialTime']), 
                    duration: duration.getTotalMinutes,
                    price: values['price'] != null ? double.parse(values['price']) : 0, 
                    partitionPhysicalId: widget.physicalPartition.partitionPhysicalId,
                    clientId: values['client']?.clientId != null ? int.tryParse(values['client'].clientId) : null,
                    client: values['client'] != null && values['client'].clientId == null ? values['client'] : null

                  );

      
                sessionManagerBloc.add(
                    SaveSessionEvent(newSession)
                ); 
      
                context.go("/session_manager");
           } : null,
                child: const Text("Crear Turno")
              ),
            )
          ],
        ),
      ),
    );
  }

  Stack buildHeader(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 64,
          width: ResponsiveBuilder.isDesktop(context) ? 300 : double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Nuevo Turno", style: const TextStyle(fontSize: 16),),
              Text("${widget.selectedTimeInterval.getInitialTextString()} | ${widget.selectedTimeInterval.toStringTime()}", style: const TextStyle(fontSize: 16),),
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

