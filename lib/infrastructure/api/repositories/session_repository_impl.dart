import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/club_partition.dart';
import '../../../domain/entities/create_sessions_result.dart';
import '../../../domain/entities/extra.dart';
import '../../../domain/entities/payment/payment.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/repositories/session_repository.dart';
import '../providers/session_provider.dart';
import 'base/base_repository.dart';

class SessionRepositoryImplementation extends BaseRepository implements SessionRepository {

  final SessionProvider sessionProvider;
  final dioInstance = sl<Dio>();

  SessionRepositoryImplementation({required this.sessionProvider});

  @override
  Future<List<ClubPartition>> getPhysicalPartitions() async {
    return sessionProvider.getClubPartitionsByAdmin();
  }

  @override
  Future<List<Session>> getSessions(DateTime date, {int? clubPartitionId}) {
    return sessionProvider.getSessionsByAdmin(date);
  }

  @override
  Future<CreateSessionsResult> createSessions(List<Session> sessions, List<int> physicalPartitions,
      List<DateTime> dates) {
    return sessionProvider.createSessions(sessions, physicalPartitions, dates);
  }

  @override
  Future<Session> saveSession(Session session) {
    return sessionProvider.saveSession(session);
  }
  
  @override
  Future<Client?> reservateSession(int sessionId, Client client) {
    
    return sessionProvider.reservateSession(sessionId, client);

  }
  
  @override
  Future<Either<DomainError,List<Session>>> getSessionsBySessionId(int sessionId) async {
    return safeCall<List<Session>>(() async {

      final response = await dioInstance
      .get<List<dynamic>>("/admin/sessions/$sessionId");

      return response.data!.map((e) => Session.fromJson(e)).toList();
      
    });

  }

  @override
  Future<Either<DomainError, Payment>> addPaymentToSession(
      int sessionId, Payment payment) {
    return safeCall<Payment>(
      () => sessionProvider.addPaymentToSession(sessionId, payment),
    );
  }

  @override
  Future<Either<DomainError, Extra>> addExtraToSession(
    int sessionId,
    Extra extra, {
    bool paidExtra = false,
  }) {
    return safeCall<Extra>(
      () => sessionProvider.addExtraToSession(
        sessionId,
        extra,
        paidExtra: paidExtra,
      ),
    );
  }

  @override
  Future<Either<DomainError, Extra>> paySessionExtra(int sessionId, Extra extra) {
    return safeCall<Extra>(() => sessionProvider.paySessionExtra(sessionId, extra));
  }

  @override
  Future<Either<DomainError, bool>> deleteSessionExtra(
      int sessionId, Extra extra) {
    return safeCall<bool>(() => sessionProvider.deleteSessionExtra(sessionId, extra));
  }
  

  
  @override
  Future<bool> deleteSession(int sessionId) async {
    try {
      return await sessionProvider.deleteSession(sessionId);

    } catch (error) {

      return false;
    }
  }

  @override
  Future<bool> cancelSessionReservation(int sessionId) async {
    try {
      return await sessionProvider.cancelSessionReservation(sessionId);
    } catch (error) {
      return false;
    }
  }
  
}
