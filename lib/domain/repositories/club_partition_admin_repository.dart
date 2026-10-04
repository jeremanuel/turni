import '../../core/utils/repository_response.dart';
import '../entities/club_partition.dart';
import '../entities/club_type.dart';
import '../entities/physical_partition.dart';

/// CRUD de deportes/sectores (`club_partition`) y canchas (`partition_physical`) para la
/// pantalla de configuración de admin. Separado de `SessionRepository.getClubPartitions`
/// (que alimenta el flujo de creación de turnos y solo lista activos).
abstract class ClubPartitionAdminRepository {
  Future<RepositoryResponse<List<ClubType>>> listClubTypes();

  Future<RepositoryResponse<List<ClubPartition>>> listClubPartitions({
    bool includeInactive = true,
  });

  Future<RepositoryResponse<ClubPartition>> createClubPartition({
    required int clubTypeId,
    String? phone,
    String? physicalPartitionName,
  });

  Future<RepositoryResponse<ClubPartition>> updateClubPartition(
    int clubPartitionId, {
    int? clubTypeId,
    String? phone,
    String? physicalPartitionName,
  });

  Future<RepositoryResponse<ClubPartition>> setClubPartitionActive(
    int clubPartitionId,
    bool active,
  );

  Future<RepositoryResponse<List<PhysicalPartition>>> listPartitionPhysical(
    int clubPartitionId, {
    bool includeInactive = true,
  });

  Future<RepositoryResponse<PhysicalPartition>> createPartitionPhysical(
    int clubPartitionId, {
    required int minPlayers,
    int? maxPlayers,
    int? physicalIdentifier,
    bool? isCover,
    String? description,
    int? defaultSessionDuration,
    double? defaultSessionPrice,
  });

  Future<RepositoryResponse<PhysicalPartition>> updatePartitionPhysical(
    int partitionPhysicalId, {
    int? minPlayers,
    int? maxPlayers,
    int? physicalIdentifier,
    bool? isCover,
    String? description,
    int? defaultSessionDuration,
    double? defaultSessionPrice,
  });

  Future<RepositoryResponse<PhysicalPartition>> setPartitionPhysicalActive(
    int partitionPhysicalId,
    bool active,
  );
}
