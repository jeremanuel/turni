import '../entities/club_partition.dart';
import '../entities/session.dart';

abstract class SessionRepository {
  Future<List<Session>> getSessions(DateTime date);

  Future<List<ClubPartition>> getPhysicalPartitions();

  createSessions(List<Session> sessions, List<int> physicalPartitions,
      List<DateTime> dates);

  Future<Session> saveSession(Session session);
}
