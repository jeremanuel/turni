import 'package:dio/dio.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/entities/coordinate.dart';
import '../../../core/utils/entities/range_date.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/club_partition.dart';
import '../../../domain/entities/create_sessions_result.dart';
import '../../../domain/entities/extra.dart';
import '../../../domain/entities/payment/payment.dart';
import '../../../domain/entities/session.dart';

class SessionProvider {
  Future<Payment> addPaymentToSession(int sessionId, Payment payment) async {
    final payload = payment.toJson()
      ..remove('payment_id')
      ..remove('payment_date');

    payload['payment_method_id'] = payment.paymentMethod.paymentMethodId;

    final response = await dioInstance.post(
      "/admin/session/$sessionId/payment",
      data: {"payment": payload},
    );

    return Payment.fromJson(response.data['payment']);
  }

  Future<Extra> addExtraToSession(int sessionId, Extra extra,
      {bool paidExtra = false}) async {
    final payload = {
      'product_id': extra.productId,
      'amount': extra.amount,
      'payed': paidExtra,
      if (extra.payment != null)
        'payment_method_id': extra.payment!.paymentMethod.paymentMethodId,
    };

    final response = await dioInstance.post(
      "/admin/session/$sessionId/extra",
      data: {'extra': payload},
    );

    return Extra.fromJson(response.data['extra']);
  }

  Future<Extra> paySessionExtra(int sessionId, Extra extra) async {
    final response = await dioInstance.post(
      "/admin/session/$sessionId/extra/pay",
      data: {
        'extra': {
          'extra_id': extra.extraId,
        },
        'payment': {
          'amount': extra.amount,
          'payment_method_id': 1,
        }
      },
    );

    return Extra.fromJson(response.data['extra']);
  }

  Future<bool> deleteSessionExtra(int sessionId, Extra extra) async {
    final response = await dioInstance.delete(
      "/admin/session/$sessionId/extra",
      data: {
        'extra': {
          'extra_id': extra.extraId,
        }
      },
    );

    return response.data['success'] == true;
  }

  Future<bool> deleteSession(int sessionId) async {
    final response = await dioInstance.delete("/admin/session/$sessionId");
    return response.statusCode == 200;
  }

  Future<bool> cancelSessionReservation(int sessionId) async {
    final response = await dioInstance.post(
      "/admin/session/$sessionId/cancel_reservation",
    );

    return response.statusCode == 200;
  }

  final dioInstance = sl<Dio>();

  Future<List<Session>> getClientSessions(
    clubTypeId,
    Coordinate coordinate,
    RangeDate rangeDate,
  ) async {
    try {
      final data = {
        "club_type_id": clubTypeId,
        "coordinate": coordinate.toJson(),
        "range": rangeDate.toJson(),
      };

      final response = await dioInstance.post("/session", data: data);

      return (response.data as List)
          .map((session) => Session.fromJson(session))
          .toList();
    } catch (error) {
      // TODO: Manejar error.
      return [];
    }
  }

  Future<List<Session>> getSessionsByAdmin(DateTime date) async {
    try {
      final response = await dioInstance
          .get("/admin/sessions", queryParameters: {"date": date});

      return (response.data as List)
          .map((session) => Session.fromJson(session))
          .toList();
    } catch (error) {
      // TODO: Manejar error.
      return [];
    }
  }


  Future<List<ClubPartition>> getClubPartitionsByAdmin() async {
    final response = await dioInstance.get("/admin/club_partitions");

    return (response.data as List)
        .map((session) {
          final normalizedSession = Map<String, dynamic>.from(session as Map);

          normalizedSession['physical_partition_name'] ??=
              normalizedSession['partition_physical_name'] ??
              normalizedSession['physical_partition_label'] ??
              normalizedSession['partition_name'];

          return ClubPartition.fromJson(normalizedSession);
        })
        .toList();
  }

  Future<CreateSessionsResult> createSessions(List<Session> sessions, List<int> physicalPartitions,
      List<DateTime> dates) async {
    final body = {
      "sessions": sessions,
      "physical_partitions": physicalPartitions,
      "dates": dates.map((el) => el.toString()).toList()
    };

    final response = await dioInstance.post("/admin/sessions", data: body);
    return CreateSessionsResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Session> saveSession(Session session) async {
    try {
      final body = {
        "session": session,
      };

      final response = await dioInstance.post("/admin/session", data: body);

      return Session.fromJson(response.data);

    } catch (e) {      
      return Session.fromJson({});      
    }
  }

  Future<Client?> reservateSession(int sessionId, Client client) async {

  try { 


      final response = await dioInstance.post("/admin/reserve/$sessionId", data: {"client": client.toJson()});
      
      return Client.fromJson(response.data['client']);

    } catch (e) {      
      print(e);
    }
  return null;

  }

  
}
