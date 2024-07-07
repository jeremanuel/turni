import 'package:bloc/bloc.dart';

import '../../../../../core/utils/entities/coordinate.dart';
import '../../../../../core/utils/entities/range_date.dart';
import '../../../../../domain/entities/club_type.dart';
import '../../../../../domain/entities/session.dart';
import '../../../../../domain/usecases/session/get_sessions.dart';
import '../../../../../infrastructure/api/providers/session_provider.dart';
import '../../../../../infrastructure/api/repositories/session_repository_impl.dart';

part 'session_state.dart';

class SessionCubit extends Cubit<SessionState> {
  SessionCubit() : super(SessionInitial());

  loadSessions(
      ClubType clubType, Coordinate coordinate, RangeDate rangeDate) async {
    List<Session> sessions = await GetSesssions(
      SessionRepositoryImplementation(sessionProvider: SessionProvider()),
    ).excute(
      clubType.clubTypeId,
      coordinate,
      rangeDate,
    );

    emit(SessionLoaded(sessions));
  }
}
