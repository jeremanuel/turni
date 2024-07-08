import '../../../../core/utils/entities/coordinate.dart';
import '../../../../core/utils/entities/range_date.dart';
import '../../../../domain/entities/session.dart';
import '../../../../domain/repositories/client/client_session_repository.dart';
import '../../providers/client/client_session_provider.dart';

class ClientSessionRepositoryImplementation extends ClientSessionRepository {
  final ClientSessionProvider sessionProvider;

  ClientSessionRepositoryImplementation({required this.sessionProvider});

  @override
  Future<List<Session>> getClientSessions(
    int clubTypeId,
    Coordinate coordinate,
    RangeDate rangeDate,
  ) async {
    return sessionProvider.getClientSessions(clubTypeId, coordinate, rangeDate);
  }
}
