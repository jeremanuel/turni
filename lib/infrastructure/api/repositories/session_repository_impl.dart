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
  Future<List<ClubPartition>> getPhysicalPartitions() async {
    return sessionProvider.getClubPartitionsByAdmin();
  }

  @override
  Future<List<Session>> getSessions(DateTime date) {
    return sessionProvider.getSessionsByAdmin(date);
  }
}
