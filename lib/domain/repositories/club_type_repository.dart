import '../../core/utils/entities/coordinate.dart';
import '../entities/club_type.dart';

abstract class ClubTypeRepository {
  Future<List<ClubType>> getClubTypes(Coordinate coordinate);
}
