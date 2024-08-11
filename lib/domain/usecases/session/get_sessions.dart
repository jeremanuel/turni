import '../../../core/utils/entities/coordinate.dart';
import '../../../core/utils/entities/range_date.dart';
import '../../entities/session.dart';
import '../../repositories/client/client_session_repository.dart';

class GetClientSessions {
  final ClientSessionRepository clientSessionRepository;

  GetClientSessions(this.clientSessionRepository);

  Future<List<Session>> excute(
    int clubTypeId,
    Coordinate coordinate,
    RangeDate rangeDate,
  ) async {
    final sesssions = await clientSessionRepository.getClientSessions(
        clubTypeId, coordinate, rangeDate);

    return sesssions;
  }
}
