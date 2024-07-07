import 'package:bloc/bloc.dart';

import '../../../../../core/utils/entities/coordinate.dart';
import '../../../../../core/utils/entities/range_date.dart';
import '../../../../../domain/entities/club_type.dart';
import '../../../../../domain/entities/session.dart';
import '../../../../../domain/usecases/session/get_sessions.dart';
import '../../../../../infrastructure/api/providers/client/client_session_provider.dart';
import '../../../../../infrastructure/api/repositories/client/client_session_repository_impl.dart';

part 'session_state.dart';

//@deprecated was replace with ClientSessionManagerBloc
class SessionCubit extends Cubit<SessionState> {
  SessionCubit() : super(SessionInitial());

  loadSessions(
      ClubType clubType, Coordinate coordinate, RangeDate rangeDate) async {
    List<Session> sessions = await GetClientSessions(
      ClientSessionRepositoryImplementation(
          sessionProvider: ClientSessionProvider()),
    ).excute(
      clubType.clubTypeId,
      coordinate,
      rangeDate,
    );

    emit(SessionLoaded(sessions));
  }
}
