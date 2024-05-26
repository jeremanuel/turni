import '../../../core/utils/entities/coordinate.dart';
import '../../../core/utils/entities/range_date.dart';
import '../../../domain/entities/club_partition.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/repositories/session_repository.dart';
import '../providers/session_provider.dart';

class SessionRepositoryImplementation extends SessionRepository {
  final SessionProvider sessionProvider;

  SessionRepositoryImplementation({required this.sessionProvider});

  @override
  Future<List<Session>> getClientSessions(
    int clubTypeId,
    Coordinate coordinate,
    RangeDate rangeDate,
  ) async {
    return sessionProvider.getSessions(clubTypeId, coordinate, rangeDate);
  }

  @override
  List<ClubPartition> getPhysicalPartitions() {
    throw UnimplementedError();
  }

  @override
  Future<List<Session>> getSessions(DateTime date) {
    throw UnimplementedError();
  }
}
