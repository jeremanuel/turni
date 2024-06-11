import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/types/time_interval.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/person.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/entities/session.dart';
import '../../../core/custom_time_picker.dart';
import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';

class AddNewSession extends StatefulWidget {
  AddNewSession(
      {super.key,
      required int idPhysicalPartition,
      required this.selectedTimeInterval})
      : clubPartition = _findPhysicalPartition(idPhysicalPartition){

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
    return FormBuilder(
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
                  partitionPhysicalId: widget.physicalPartition.partitionPhysicalId
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
    );
  }

  Stack buildHeader(BuildContext context) {
    return Stack(
                  children: [
                    SizedBox(
                      height: 64,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Nuevo Turno ${widget.selectedTimeInterval.toStringTime()}", style: const TextStyle(fontSize: 16),)
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

class PickClient extends StatefulWidget {
  const PickClient({super.key,
  this.onPressNew, 
  this.onBackToSelection, 
  this.onSelect
  });  
  
  /// Invocado cuando se preciona en "Nuevo" cliente.
  final Function()? onPressNew;
  /// Invocado al volver a la etapa inicial del componente.
  final Function()? onBackToSelection;
  /// Invocado al seleccionar un cliente existente desde la etapa inicial.
  final Function()? onSelect;

  @override
  State<PickClient> createState() => _PickClientState();
}

class _PickClientState extends State<PickClient> {
  Client? pickedClient;
  final SearchController _searchController = SearchController();
  bool newMode = false;

  @override
  @override
  Widget build(BuildContext context) {
    final children = [
      if(!newMode)
      const Text("Cliente"),
      if(newMode) Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Nuevo Cliente"),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                newMode = false;
              });

              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                widget.onBackToSelection?.call();
              });
              

            },
            icon: const Icon(Icons.close)
          )
          
      ]),
      const SizedBox(height: 16),
    ];
    
    if (pickedClient == null && !newMode) {
      children.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SearchAnchor(
            searchController: _searchController,
            builder: (context, controller) {
              return FilledButton.icon(onPressed: (){
                _searchController.openView();
              }, 
              label: const Text("buscar"),
              icon: const Icon(Icons.search),
            );
            },
            suggestionsBuilder: (context, controller) {
              final clients = [
                "Mailen Fioravanti",
                "Guido CHiara",
                "Agustin masa",
                "Joaquin Mastropierro",
                "Lucas Medico",
                "Esteban ",
                "XD ",
                "Guido CHiara",
                "Agustin masa",
                "Joaquin Mastropierro",
                "Lucas Medico",
              ];

              return clients
                  .where(
                    (element) => element.contains(controller.text),
                  )
                  .map(
                    (client) => InkWell(
                      onTap: () {
                        _searchController.closeView(null);
                        setState(() {
                          pickedClient = Client(
                              person: Person(
                                  name: "Agustin",
                                  lastName: "Massa",
                                  email: "masa",
                                  phone: "223412323"));
                        });
                      },
                      child: ListTile(
                        leading:
                            CircleAvatar(child: Text(client.characters.first)),
                        subtitle: Text("2284690141"),
                        title: Text(client),
                      ),
                    ),
                  );
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Crear"),
            onPressed: () {
              setState(() {
                newMode = true;
              });

              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                widget.onPressNew?.call();
              });
              
            }
          )
        ],
      ));
    }

    if(pickedClient != null){
      children.add(
        ListTile(  
        leading: CircleAvatar(
            child: Text(pickedClient!.person!.fullName.characters.first)
          ),
        trailing: IconButton(
            onPressed: () {
              setState(() {
                pickedClient = null;
              });
            },
            icon: const Icon(Icons.close)
          ),
        subtitle: Text(pickedClient!.person!.phone!),
        title: Text(pickedClient!.person!.fullName),
      ));
    } 

    if(pickedClient == null && newMode){
      children.add(
        Column(
        children: [
          FormBuilderTextField(
            autofocus: true,
            validator: requiredAndMin3,
            name: "name", 
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person, size: 14,),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              helperText: "Obligatorio",
              labelText: "Nombre",
              
              
            ),
          ),
          const SizedBox(height: 16,),
          FormBuilderTextField(
            name: "lastname", 
            validator: requiredAndMin3,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person, size: 14,),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              helperText: "Obligatorio",
              labelText: "Apellido"        
            ),
          ),
          const SizedBox(height: 16,),
          FormBuilderTextField(
            validator: requiredAndMin3,
            name: "phone", 
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')), 
              // for version 2 and greater youcan also use this
              FilteringTextInputFormatter.digitsOnly

            ],
            
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone, size: 14,),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              helperText: "Obligatorio",
              labelText: "Telefono",
              
                
            ),
          ),
          const SizedBox(height: 16,),
          FormBuilderTextField(
            name: "email", 
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.mail, size: 14,),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              labelText: "Email",


            ),
          ),                
        ],
    ));
    } 

    return Column(
      children: children,
    );

  }

  String? requiredAndMin3(value) {
          if(value == null || value.trim() == ''){
            return "Campo obligatorio";
          }
          if(value.length < 3){
            return "Por lo menos 3 caracteres.";
          }
  
          return null;
        }
}
