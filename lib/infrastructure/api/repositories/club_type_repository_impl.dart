import '../../../core/utils/entities/coordinate.dart';
import '../../../domain/entities/club_type.dart';
import '../../../domain/repositories/club_type_repository.dart';
import '../providers/club_type_provider.dart';

class ClubTypeRepositoryImplementation extends ClubTypeRepository {
  final ClubTypeProvider clubTypeProvider;

  ClubTypeRepositoryImplementation({required this.clubTypeProvider});

  @override
  Future<List<ClubType>> getClubTypes(Coordinate coordinate) async {
    return clubTypeProvider.getClubTypes(coordinate);
  }
}
