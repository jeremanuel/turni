import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/components/inputs/chips/filter_chip_local_list.dart';
import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../domain/entities/routine/exercise.dart';
import '../../../../domain/entities/routine/routine_exercise.dart';
import '../cubit/new_routine_cubit.dart';
import 'sets_dropdown.dart';

class ExerciseItem extends StatelessWidget {
  const ExerciseItem({super.key, required this.routineExercise, required this.index, required this.routineGroupId});

  final RoutineExercise routineExercise;
  final int index;
  final int routineGroupId;

  @override
  Widget build(BuildContext context) {
    return ListTile(
          
          key: key,
          title: Row(
            spacing: 4,
            children: [
              Text("${index + 1} ", style: Theme.of(context).textTheme.bodyMedium,),
              buildExcerciseDropdown(context),
              SetsDropdown(
                routineGroupId: routineGroupId,
                routineExercise: routineExercise,
              ),
              
            ],
          ),
          );
  }

  Widget buildExcerciseDropdown(BuildContext context) {

    final items = [
  Exercise(id: 1, name: "Press de Banca", muscularGroup: 1),
        Exercise(id: 2, name: "Sentadillas", muscularGroup: 2),
        Exercise(id: 3, name: "Peso Muerto", muscularGroup: 3),
        Exercise(id: 4, name: "Remo con Barra", muscularGroup: 4),
        Exercise(id: 5, name: "Press Militar", muscularGroup: 1),
        Exercise(id: 6, name: "Dominadas", muscularGroup: 2),
        Exercise(id: 7, name: "Fondos en paralelas", muscularGroup: 3),
        Exercise(id: 8, name: "Curl de bíceps con barra", muscularGroup: 4),
        Exercise(id: 9, name: "Curl de bíceps con mancuernas", muscularGroup: 1),
        Exercise(id: 10, name: "Extensiones de tríceps en polea", muscularGroup: 1),
        Exercise(id: 11, name: "Jalón al pecho", muscularGroup: 2),
        Exercise(id: 12, name: "Aperturas con mancuernas", muscularGroup: 3),
        Exercise(id: 13, name: "Remo con mancuerna", muscularGroup: 4),
        Exercise(id: 14, name: "Zancadas", muscularGroup: 1),
        Exercise(id: 15, name: "Prensa de piernas", muscularGroup: 2),
        Exercise(id: 16, name: "Elevaciones laterales", muscularGroup: 3),
        Exercise(id: 17, name: "Elevaciones frontales", muscularGroup: 4),
        Exercise(id: 18, name: "Face pull", muscularGroup: 1),
        Exercise(id: 19, name: "Pájaros", muscularGroup: 2),
        Exercise(id: 20, name: "Gemelos de pie", muscularGroup: 3),
        Exercise(id: 21, name: "Gemelos sentado", muscularGroup: 4),
        Exercise(id: 22, name: "Abdominales en banco", muscularGroup: 1),
        Exercise(id: 23, name: "Plancha", muscularGroup: 2),
        Exercise(id: 24, name: "Hip thrust", muscularGroup: 3),
        Exercise(id: 25, name: "Peso muerto rumano", muscularGroup: 4),
    ];
    
    return FilterChipLocalList<Exercise>(
      items: items,
      label:const Text("Ejercicio"),
      onItemSelected: (item) {
        context.read<NewRoutineCubit>().updateExerciseInGroup(routineGroupId, routineExercise.id, item);
      },
      buildItem: (item) {
        return Text(item.name);
      },
      buildSelectedLabel: (item) {
        return Text(item.name);
      },
      selectedItem: routineExercise.exercise,
      searchable: true,
      chipMaxWidth: 150,
      searchFunction: (text) {
        return items.where((element) => element.name.toLowerCase().contains(text.toLowerCase())).toList();
        
      },
    );
  }


}