part of 'session_cubit.dart';

sealed class SessionState {
  final bool isLoading;
  final ClubType? clubType;
  final List<Session> sessions;

  SessionState(
      {this.clubType, required this.isLoading, required this.sessions});
}

final class SessionInitial extends SessionState {
  SessionInitial() : super(isLoading: true, sessions: []);
}

final class SessionLoaded extends SessionState {
  SessionLoaded(List<Session> sessions)
      : super(isLoading: false, sessions: sessions);
}
