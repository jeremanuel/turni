import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/club_info.dart';
import '../../../domain/repositories/club_info_repository.dart';
import 'base/base_repository.dart';

class ClubInfoRepositoryImpl extends BaseRepository
    implements ClubInfoRepository {
  final dioInstance = sl<Dio>();

  @override
  Future<RepositoryResponse<ClubInfo>> getClubInfo() {
    return safeCall(() async {
      final response = await dioInstance.get('/admin/club');

      return ClubInfo.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<ClubInfo>> updateClubInfo({
    String? name,
    String? address,
    double? lat,
    double? lng,
  }) {
    return safeCall(() async {
      final response = await dioInstance.put('/admin/club', data: {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });

      return ClubInfo.fromJson(response.data as Map<String, dynamic>);
    });
  }
}
