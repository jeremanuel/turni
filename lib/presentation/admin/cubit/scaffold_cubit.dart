import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scaffold_cubit_state.dart';
part 'scaffold_cubit.freezed.dart';

class ScaffoldCubit extends Cubit<ScaffoldCubitState> {
  ScaffoldCubit() : super(ScaffoldCubitState.initial(null));

  void setChild(Widget child) {
    emit(state.copyWith(child:child));
  }
}
