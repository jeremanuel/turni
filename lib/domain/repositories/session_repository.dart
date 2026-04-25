import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../entities/client.dart';
import '../entities/club_partition.dart';
import '../entities/extra.dart';
import '../entities/payment/payment.dart';
import '../entities/session.dart';

abstract class SessionRepository {
  Future<List<Session>> getSessions(DateTime date);

  Future<Either<DomainError, List<Session>>> getSessionsBySessionId(int sessionId);

  Future<List<ClubPartition>> getPhysicalPartitions();

  createSessions(List<Session> sessions, List<int> physicalPartitions,
      List<DateTime> dates);

  Future<Session> saveSession(Session session);

  Future<Client?> reservateSession(int sessionId, Client client);

  Future<Either<DomainError, Payment>> addPaymentToSession(
      int sessionId, Payment payment);

  Future<Either<DomainError, Extra>> addExtraToSession(
      int sessionId, Extra extra,
      {bool paidExtra = false});

  Future<Either<DomainError, Extra>> paySessionExtra(int sessionId, Extra extra);

  Future<Either<DomainError, bool>> deleteSessionExtra(int sessionId, Extra extra);

  Future deleteSession(int sessionId);
}
