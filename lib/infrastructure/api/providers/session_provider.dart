import 'package:dio/dio.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/entities/coordinate.dart';
import '../../../core/utils/entities/range_date.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/club_partition.dart';
import '../../../domain/entities/session.dart';

class SessionProvider {
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
      print('error: $error');
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
      print(error);
      return [];
    }
  }


  Future<List<ClubPartition>> getClubPartitionsByAdmin() async {
    final response = await dioInstance.get("/admin/club_partitions");

    return (response.data as List)
        .map((session) => ClubPartition.fromJson(session))
        .toList();
  }

  createSessions(List<Session> sessions, List<int> physicalPartitions,
      List<DateTime> dates) async {
    try {
      final body = {
        "sessions": sessions,
        "physical_partitions": physicalPartitions,
        "dates": dates.map((el) => el.toString()).toList()
      };

      final response = await dioInstance.post("/admin/sessions", data: body);

      return response.data;
    } catch (e) {
      return false;
    }
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


      final response = await dioInstance.post("/admin/reserve/${sessionId}", data: {"client": client.toJson()});
      print(response.data['client']);
      return Client.fromJson(response.data['client']);

    } catch (e) {      
      print(e);
    }

  }

  
}
