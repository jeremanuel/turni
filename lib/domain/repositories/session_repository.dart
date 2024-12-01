import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../../core/utils/entities/coordinate.dart';
import '../../core/utils/entities/range_date.dart';
import '../../core/utils/types/time_interval.dart';
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
