import 'package:bloc/bloc.dart';

import '../../../core/utils/entities/coordinate.dart';
import '../../../core/utils/entities/range_date.dart';
import '../../../domain/entities/club_type.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/usecases/session/get_sessions.dart';
import '../../../infrastructure/api/providers/session_provider.dart';
import '../../../infrastructure/api/repositories/session_repository_impl.dart';

part 'session_state.dart';

class SessionCubit extends Cubit<SessionState> {
  SessionCubit() : super(SessionInitial());

  loadSessions(ClubType clubType, Coordinate coordinate) async {
    List<Session> sessions = await GetSesssions(
      SessionRepositoryImplementation(sessionProvider: SessionProvider()),
    ).excute(
      clubType.clubTypeId,
      coordinate,
      RangeDate(
        from: DateTime.tryParse("2024-05-05T00:00:00Z"),
        to: DateTime.tryParse("2024-05-05T03:00:00.000Z"),
      ),
    );

    emit(SessionLoaded(sessions));
  }
}
