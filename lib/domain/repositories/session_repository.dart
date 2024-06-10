import '../../core/utils/entities/coordinate.dart';
import '../../core/utils/entities/range_date.dart';
import '../../core/utils/types/time_interval.dart';
import '../entities/club_partition.dart';
import '../entities/session.dart';

abstract class SessionRepository {
  Future<List<Session>> getClientSessions(
    int clubTypeId,
    Coordinate coordinate,
    RangeDate rangeDate,
  );

  Future<List<Session>> getSessions(DateTime date);

  Future<List<ClubPartition>> getPhysicalPartitions();

  createSessions(List<Session> sessions, List<int> physicalPartitions, List<DateTime> dates);
}
