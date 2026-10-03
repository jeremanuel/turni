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
import '../../../domain/entities/session_status.dart';
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

  @override
  Future<Either<DomainError, SessionStatus>> acceptSessionRequest(int sessionId) async {
    try {
      final data = await sessionProvider.acceptSession(sessionId);

      return Either.right(SessionStatus.fromApiValue(data['status'])!);
    } on DioException catch (err) {
      return Either.left(_domainErrorFromSessionActionError(err));
    }
  }

  @override
  Future<Either<DomainError, SessionStatus>> rejectSessionRequest(int sessionId) async {
    try {
      final data = await sessionProvider.rejectSession(sessionId);

      return Either.right(SessionStatus.fromApiValue(data['status'])!);
    } on DioException catch (err) {
      return Either.left(_domainErrorFromSessionActionError(err));
    }
  }

  /// Traduce el error de aceptar/rechazar una solicitud a un [DomainError]
  /// con mensaje legible. El 409 `STALE_STATUS` usa un shape de respuesta
  /// `{ error: "STALE_STATUS", message: "..." }` distinto del genérico
  /// `{ error: "<mensaje>" }` que arma el resto del backend a propósito
  /// (ver `SessionStateConflictError` en `turni_mono_be`) — por eso no se
  /// puede usar `DomainError.fromErrorResponse` acá sin perder el mensaje.
  DomainError _domainErrorFromSessionActionError(DioException err) {
    final data = err.response?.data;

    if (data is Map && data['error'] == 'STALE_STATUS') {
      return DomainError(
        message: data['message'] as String? ??
            "Esta solicitud ya no está disponible: alguien más la resolvió.",
        internalCode: DomainError.unknwonError,
        httpStatusCode: err.response?.statusCode ?? 409,
        date: DateTime.now(),
      );
    }

    if (data == null) return DomainError.unknownError();

    return DomainError.fromErrorResponse(data);
  }

}