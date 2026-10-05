import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/club_map/club_map.dart';
import '../../../domain/repositories/club_map_repository.dart';
import 'base/base_repository.dart';

class ClubMapRepositoryImpl extends BaseRepository implements ClubMapRepository {
  final dioInstance = sl<Dio>();

  static const _path = "/admin/club-map";

  @override
  Future<RepositoryResponse<ClubMapView>> getClubMap() {
    return safeCall(() async {
      final response = await dioInstance.get(_path);

      return ClubMapView.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<ClubMapView>> saveClubMap(ClubMapLayout layout) {
    return safeCall(() async {
      final response = await dioInstance.put(_path, data: layout.toJson());

      return ClubMapView.fromJson(response.data as Map<String, dynamic>);
    });
  }
}
