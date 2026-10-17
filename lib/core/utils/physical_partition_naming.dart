import '../../domain/entities/club_partition.dart';
import '../../domain/entities/partition_vocabulary.dart';
import '../../domain/entities/physical_partition.dart';

/// API vieja del nombre de los espacios. Delega en [PartitionVocabulary]; el
/// código nuevo usa `PartitionVocabulary.of(...)` / `spaceLabel()` directamente.
class PhysicalPartitionNaming {
  static String singularFromClubPartition(ClubPartition? clubPartition) =>
      PartitionVocabulary.of(clubPartition).space.singular;

  static String pluralFromClubPartition(ClubPartition? clubPartition) =>
      PartitionVocabulary.of(clubPartition).space.plural;

  static String labelFromPhysicalPartition(
    PhysicalPartition partition, {
    ClubPartition? fallbackClubPartition,
  }) =>
      partition.spaceLabel(fallback: fallbackClubPartition);

  static String labelFromIdentifier({
    required int? physicalIdentifier,
    required int? partitionPhysicalId,
    ClubPartition? clubPartition,
  }) =>
      PartitionVocabulary.of(clubPartition).space.label(physicalIdentifier ?? partitionPhysicalId);
}
