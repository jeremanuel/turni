part of 'feed_cubit.dart';

@immutable
sealed class FeedState {
  final bool isLoading;
  final List<Session> turnos;

  FeedState(this.isLoading, this.turnos);

}

final class FeedInitial extends FeedState {

  FeedInitial() : super(true, []);
}


final class FeedLoaded extends FeedState {

  FeedLoaded(List<Session> sessions) : super(false, sessions);
}
