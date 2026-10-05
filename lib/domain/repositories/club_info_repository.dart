import '../../core/utils/repository_response.dart';
import '../entities/club_info.dart';

abstract class ClubInfoRepository {
  Future<RepositoryResponse<ClubInfo>> getClubInfo();

  Future<RepositoryResponse<ClubInfo>> updateClubInfo({
    String? name,
    String? address,
    double? lat,
    double? lng,
  });
}
