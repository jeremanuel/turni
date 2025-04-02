import 'package:dio/dio.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/entities/coordinate.dart';
import '../../../../core/utils/entities/range_date.dart';
import '../../../../domain/entities/session.dart';

class ClientSessionProvider {
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
}
