import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../../core/utils/types/time_interval.dart';
import '../entities/client.dart';
import '../entities/club_partition.dart';
import '../entities/create_sessions_result.dart';
import '../entities/extra.dart';
import '../entities/payment/payment.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

class SessionUserCases {
  final SessionRepository _sessionRepository;

  SessionUserCases(this._sessionRepository);

  Future<List<Session>> getSessions(DateTime date) async {
    return _sessionRepository.getSessions(date);
  }

  Future<Either<DomainError, List<Session>>> getSessionsBySessionId(int sessionId) async {
    return _sessionRepository.getSessionsBySessionId(sessionId);
  }


  Future<List<ClubPartition>> getClubPartitions() async {
    return _sessionRepository.getPhysicalPartitions();
  }
  Future<CreateSessionsResult> createSessions(List<Session> sessions, List<int> physicalPartitions, TimeInterval interval) async {
   return _sessionRepository.createSessions(sessions, physicalPartitions, interval.generateDateRange());
  }

  Future<Session> saveSession(Session session) async {
   return _sessionRepository.saveSession(session);
  }

  Future<Client?> reservateSession(Session session, Client client) async {
   return _sessionRepository.reservateSession(session.sessionId, client);
  }

  Future<Either<DomainError, Payment>> addPaymentToSession(
      int sessionId, Payment payment) {
    return _sessionRepository.addPaymentToSession(sessionId, payment);
  }

  Future<Either<DomainError, Extra>> addExtraToSession(
    int sessionId,
    Extra extra, {
    bool paidExtra = false,
  }) {
    return _sessionRepository.addExtraToSession(
      sessionId,
      extra,
      paidExtra: paidExtra,
    );
  }

  Future<Either<DomainError, Extra>> paySessionExtra(int sessionId, Extra extra) {
    return _sessionRepository.paySessionExtra(sessionId, extra);
  }

  Future<Either<DomainError, bool>> deleteSessionExtra(int sessionId, Extra extra) {
    return _sessionRepository.deleteSessionExtra(sessionId, extra);
  }

  Future<bool> deleteSession(int sessionId){
    return _sessionRepository.deleteSession(sessionId);
  }

  Future<bool> cancelSessionReservation(int sessionId) {
    return _sessionRepository.cancelSessionReservation(sessionId);
  }


}
