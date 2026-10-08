import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/club_map/club_map.dart';
import '../../../domain/entities/club_map/court_usage.dart';
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

  @override
  Future<RepositoryResponse<CourtUsageView>> getCourtUsage({required int days}) {
    return safeCall(() async {
      final today = DateTime.now();
      final from = DateTime(today.year, today.month, today.day - (days - 1));
      final response = await dioInstance.get('$_path/usage', queryParameters: {'from': _day(from), 'to': _day(today)});

      return CourtUsageView.fromJson(response.data as Map<String, dynamic>);
    });
  }

  static String _day(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
