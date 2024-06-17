import 'package:dio/dio.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/entities/coordinate.dart';
import '../../../domain/entities/club_type.dart';

class ClubTypeProvider {
  final dioInstance = sl<Dio>();

  Future<List<ClubType>> getClubTypes(Coordinate coordinate) async {
    try {
      final data = {"coordinate": coordinate.toJson()};
      final response = await dioInstance.post("/club_partition", data: data);

      return (response.data as List)
          .map((clubType) => ClubType.fromJson(clubType))
          .toList();
    } catch (error) {
      print('error: $error');
      return List.filled(1, ClubType(clubTypeId: 1, name: "Error"));
    }
  }
}
