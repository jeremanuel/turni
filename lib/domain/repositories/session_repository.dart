import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../entities/client.dart';
import '../entities/club_partition.dart';
import '../entities/session.dart';

abstract class SessionRepository {
  Future<List<Session>> getSessions(DateTime date);

  Future<Either<DomainError, List<Session>>> getSessionsBySessionId(int sessionId);

  Future<List<ClubPartition>> getPhysicalPartitions();

  createSessions(List<Session> sessions, List<int> physicalPartitions,
      List<DateTime> dates);

  Future<Session> saveSession(Session session);

  Future<Client?> reservateSession(int sessionId, Client client);

  Future deleteSession(int sessionId);
}
