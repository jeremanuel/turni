part of 'home_cubit.dart';

sealed class HomeState {
  final bool isLoading;
  final List<ClubType> clubTypes;

  HomeState(this.isLoading, this.clubTypes);
}

final class HomeInitial extends HomeState {
  HomeInitial() : super(true, []);
}

final class HomeLoaded extends HomeState {
  HomeLoaded(List<ClubType> clubTypes) : super(false, clubTypes);
}
