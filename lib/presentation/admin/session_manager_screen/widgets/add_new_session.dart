import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/types/time_interval.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/person.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../core/custom_time_picker.dart';
import '../../bloc/session_manager_bloc.dart';
import 'calendar_side_column.dart';

class AddNewSession extends StatelessWidget {

  AddNewSession({
    super.key, 
    required int idPhysicalPartition,
    required this.selectedTimeInterval
  }) : physicalPartition = _findPhysicalPartition(idPhysicalPartition),
       duration = selectedTimeInterval.getDuration();

  final PhysicalPartition physicalPartition;
  final TimeInterval selectedTimeInterval;
  final Duration? duration; 

  static PhysicalPartition _findPhysicalPartition(int idPhysicalPartition){

    return sl<SessionManagerBloc>().state.clubPartitions.firstWhere((element) {

      final index = element.physicalPartitions!.indexWhere((element) => element.partitionPhysicalId == idPhysicalPartition,);

      return index != -1;
    })
    .physicalPartitions!.firstWhere((element) => element.partitionPhysicalId == idPhysicalPartition,);

  }

  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

 

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: (){
                  context.go("/session_manager");
                }, 
                icon: const Icon(Icons.arrow_back)
              ),
              const Spacer(),
              Text("Nuevo Turno ${selectedTimeInterval.toStringTime()}",),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 64),
          InputChip(label: Text("Cancha ${physicalPartition.physicalIdentifier}")),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text("Cliente"),
          const SizedBox(height: 16),
          const PickClient(),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text("Hora de inicio"),
          const SizedBox(height: 16),
          CustomTimePicker(
            name: "timepicker",
            initialHours: selectedTimeInterval.initialDate!.hour.toString(),
            initialMinutes: selectedTimeInterval.initialDate!.minute.toString(),
          ),
          const SizedBox(height: 16),
          const Text("Duracion"),
          const SizedBox(height: 16),
          CustomTimePicker(
            name: "timepicker",
            initialHours: duration?.inHours.toString(),
            initialMinutes: (duration!.inMinutes - duration!.inHours * 60).toString(),
          ),
          const SizedBox(height: 16),

        ],
      ),
    );
  }
}



class PickClient extends StatefulWidget {
  const PickClient({super.key});

  @override
  State<PickClient> createState() => _PickClientState();
}

class _PickClientState extends State<PickClient> {

  Client? pickedClient;
  final SearchController _searchController = SearchController();

  @override


  @override
  Widget build(BuildContext context) {
    
    if(pickedClient == null) {
      return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SearchAnchor(
                searchController: _searchController,
                builder: (context, controller) {
                return FilledButton(
                  
                  onPressed: () {
                  _searchController.openView();
                },
                child: Row(
                  children: [
                    Icon(Icons.search),
                    Text("Buscar"),
                  ],
                )
                );
              }, 
              suggestionsBuilder: (context, controller) {
                final clients = [
                  "Pedro Alfonso",
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
                .where((element) => element.contains(controller.text),)
                .map((client) => InkWell(
                  onTap: () {
                    _searchController.closeView(null);
                    setState(() {
                      pickedClient = Client(
                        person: Person(name: "Agustin", lastName: "Massa", email: "masa", phone: "223412323")
                      );
                    });
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(client.characters.first)
                      ),
                    subtitle: Text("2284690141"),
                    title: Text(client),
                  ),
                ),);
              },),
              OutlinedButton(onPressed: (){}, child: Row(children: [Icon(Icons.add) ,Text("Crear")],), )
            ],
          );
    }

    return Row(
      children: [
        Expanded(
          child: ListTile(
                        leading: CircleAvatar(
                          child: Text(pickedClient!.person!.fullName.characters.first)
                          ),
                        subtitle: Text(pickedClient!.person!.phone!),
                        title: Text(pickedClient!.person!.fullName),
                      ),
        ),
        IconButton(
          onPressed: (){
            setState(() {
              pickedClient = null;
            });
          },
          icon: const Icon(Icons.close)
        )
      ],
    );
  }
}