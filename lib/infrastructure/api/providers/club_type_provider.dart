import 'package:dio/dio.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/entities/coordinate.dart';
import '../../../domain/entities/club_type.dart';

class ClubTypeProvider {
  final dioInstance = sl<Dio>();

  Future<List<ClubType>> getClubTypes(Coordinate coordinate) async {
    final data = {"coordinate": coordinate.toJson()};

    final response = await dioInstance.post("/club_partition/", data: data);

    return (response.data.activity as List)
        .map((clubType) => ClubType.fromJson(clubType))
        .toList();
  }
}
