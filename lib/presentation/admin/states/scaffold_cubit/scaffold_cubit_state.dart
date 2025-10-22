part of 'scaffold_cubit.dart';

@freezed
sealed class ScaffoldCubitState with _$ScaffoldCubitState {
  const factory ScaffoldCubitState.initial(Widget? child) = _Initial;
}
