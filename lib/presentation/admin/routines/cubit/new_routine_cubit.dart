import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/either.dart';
import '../../../../domain/entities/routine/exercise.dart';
import '../../../../domain/entities/routine/routine.dart';
import '../../../../domain/entities/routine/routine_exercise.dart';
import '../../../../domain/entities/routine/routine_group.dart';
import '../../../../domain/repositories/routine_repository.dart';


part 'new_routine_state.dart';
part 'new_routine_cubit.freezed.dart';

class NewRoutineCubit extends Cubit<NewRoutineState> {

  final List defaultGroupsNames = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"];
  int exerciseCounter = -1;
  final RoutineRepository routineRepository;
  final int clientId;

  NewRoutineCubit(this.routineRepository, this.clientId) : super(NewRoutineState.initial(routineGroups: [
    RoutineGroup(
      id: -1,
      groupName: "A",
      exercises: [
        RoutineExercise(
          id: -1,
          exercise: null,
          sets: "",
          repetitions: "",
          weight: ""
        )
      ]
    )
  ]));

  void deleteGroup(int groupId) {
    final updatedGroups = state.routineGroups.where((element) => element.id != groupId).toList();
    emit(state.copyWith(routineGroups: updatedGroups));
  }
  void addNewRoutineGroup() {
    exerciseCounter--;
    emit(state.copyWith(
      routineGroups: [
        ...state.routineGroups,
        RoutineGroup(
          id: (state.routineGroups.length + 1) * -1 ,
          groupName: defaultGroupsNames[state.routineGroups.length],
          exercises: [
            RoutineExercise(
              id: exerciseCounter,
              exercise: null,
              sets: "",
              repetitions: "",
              weight: ""
            )
          ]
        )
      ]
    ));
  }
  void addRoutineGroup(RoutineGroup routineGroup) {
    emit(state.copyWith(
      routineGroups: [
        ...state.routineGroups,
        routineGroup
      ]
    ));
  }

  RoutineGroup addNewExerciseToGroup(int groupId) {

    late RoutineGroup updatedGroup;

    exerciseCounter--;

    final updatedGroups = state.routineGroups.map((element) {
      if (element.id == groupId) {
        updatedGroup = element.copyWith(
          exercises: [
            ...element.exercises,
            RoutineExercise(
              id: exerciseCounter,
              exercise: null,
              sets: "",
              repetitions: "",
              weight: ""
            )
          ]
        );

        return updatedGroup;
      }
      return element;
    }).toList();
    
    emit(state.copyWith(routineGroups: updatedGroups));

    return updatedGroup;

  }

  RoutineGroup addExerciseToGroup(int groupId, RoutineExercise exercise) {

    late RoutineGroup updatedGroup;

    final updatedGroups = state.routineGroups.map((element) {
      if (element.id == groupId) {
        updatedGroup = element.copyWith(
          exercises: [
            ...element.exercises,
            exercise
          ]
        );

        return updatedGroup;
      }
      return element;
    }).toList();
    
    emit(state.copyWith(routineGroups: updatedGroups));

    return updatedGroup;

  }

  void updateRoutineGroup(int groupId, RoutineGroup updatedGroup) {
    final updatedGroups = state.routineGroups.map((element) {
      if (element.id == groupId) {
        return updatedGroup;
      }
      return element;
    }).toList();
    
    
    emit(state.copyWith(routineGroups: updatedGroups));
  }

  void updateExcercise(int groupId, int exerciseId, RoutineExercise updatedExercise) {
    final updatedGroups = state.routineGroups.map((group) {
      if (group.id == groupId) {
        final updatedExercises = group.exercises.map((exercise) {
          if (exercise.id == exerciseId) {
            return updatedExercise;
          }
          return exercise;
        }).toList();

        return group.copyWith(exercises: updatedExercises);
      }
      return group;
    }).toList();

    emit(state.copyWith(routineGroups: updatedGroups));
    
  }

  RoutineGroup reorderExerciseInGroup(int groupId, int oldIndex, int newIndex) {
    print("${ groupId }, ${ oldIndex }, ${ newIndex }");
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }      
    late RoutineGroup updatedGroup;
    final updatedGroups = state.routineGroups.map((group) {
      if (group.id == groupId) {

        final firstExercise = group.exercises[oldIndex];
        final secondExercise = group.exercises[newIndex];

        final exercises = group.exercises.mapIndexed((index, element) {
          if(index == newIndex) return firstExercise;
          if(index == oldIndex) return secondExercise;
          return element;
        }).toList();
        updatedGroup = group.copyWith(exercises: exercises);
        return updatedGroup;
      }
      return group;
    }).toList();

    
    emit(state.copyWith(routineGroups: updatedGroups));

    return updatedGroup;
  }

  void updateExerciseInGroup(int groupId, int exerciseId, Exercise updatedExercise) {
    final updatedGroups = state.routineGroups.map((group) {
      if (group.id == groupId) {
        final updatedExercises = group.exercises.map((routineExercise) {
          if (routineExercise.id == exerciseId) {
            return routineExercise.copyWith(exercise: updatedExercise);
          }
          return routineExercise;
        }).toList();

        return group.copyWith(exercises: updatedExercises);
      }
      return group;
    }).toList();

    emit(state.copyWith(routineGroups: updatedGroups));
  }

  void updateGroup(RoutineGroup updatedGroup) {
    final updatedGroups = state.routineGroups.map((group) {
      if (group.id == updatedGroup.id) {
        return updatedGroup;
      }
      return group;
    }).toList();

    emit(state.copyWith(routineGroups: updatedGroups));
  }

  void removeExerciseFromGroup(int groupId, int exerciseId) {
    final updatedGroups = state.routineGroups.map((group) {
      if (group.id == groupId) {
        final updatedExercises = group.exercises.where((routineExercise) => routineExercise.id != exerciseId).toList();
        print(updatedExercises);
        return group.copyWith(exercises: updatedExercises);
      }
      return group;
    }).toList();
    
    emit(state.copyWith(routineGroups: updatedGroups));
  }

  void setCopiedGroup(RoutineGroup? group) {
    emit(state.copyWith(copiedGroup: group));
  }
  void setCopiedExercise(RoutineExercise? exercise) {
    emit(state.copyWith(copiedExercise: exercise));
  }

  void loadPreviusRoutines() async {

    if(state.previusRoutines != null) return;

    final apiResponse = await routineRepository.getClientRoutines(clientId);

    switch (apiResponse) {
      case Left(:final failure):
        print(failure);
        break;
      case Right(:final value):
        emit(state.copyWith(previusRoutines: value));
      break;
  }
  }

  void loadRecentRoutines() async {

    if(state.lastRoutines != null) return;

    final apiResponse = await routineRepository.getLastRoutines(quantity: 5);

    switch (apiResponse) {
      case Left(:final failure):
        print(failure);
        break;
      case Right(:final value):
        emit(state.copyWith(lastRoutines: value));
      break;
  }
  }


}
