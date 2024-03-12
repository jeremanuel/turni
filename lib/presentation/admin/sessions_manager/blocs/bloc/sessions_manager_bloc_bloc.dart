import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'sessions_manager_bloc_event.dart';
part 'sessions_manager_bloc_state.dart';

class SessionsManagerBlocBloc extends Bloc<SessionsManagerBlocEvent, SessionsManagerBlocState> {
  SessionsManagerBlocBloc() : super(SessionsManagerBlocInitial()) {
    on<SessionsManagerBlocEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
