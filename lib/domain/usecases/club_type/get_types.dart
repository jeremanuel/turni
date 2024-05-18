import '../../../core/utils/entities/coordinate.dart';
import '../../entities/club_type.dart';
import '../../repositories/club_type_repository.dart';

class GetTypes {
  final ClubTypeRepository clubTypeRepository;

  GetTypes(this.clubTypeRepository);

  Future<List<ClubType>> excute(Coordinate coordinate) async {
    final clubTypes = await clubTypeRepository.getClubTypes(coordinate);

    return clubTypes;
  }
}
