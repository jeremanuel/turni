import '../../../core/utils/entities/coordinate.dart';
import '../../../core/utils/entities/range_date.dart';
import '../../entities/session.dart';
import '../../repositories/session_repository.dart';

class GetSesssions {
  final SessionRepository sessionRepository;

  GetSesssions(this.sessionRepository);

  Future<List<Session>> excute(
    int clubTypeId,
    Coordinate coordinate,
    RangeDate rangeDate,
  ) async {
    final sesssions = await sessionRepository.getClientSessions(
        clubTypeId, coordinate, rangeDate);

    return sesssions;
  }
}
