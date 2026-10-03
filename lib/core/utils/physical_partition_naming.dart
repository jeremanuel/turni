import '../../domain/entities/club_partition.dart';
import '../../domain/entities/physical_partition.dart';

class PhysicalPartitionNaming {
  static const String _defaultSingular = 'Cancha';

  static String singularFromClubPartition(ClubPartition? clubPartition) {
    final rawName = clubPartition?.physicalPartitionName?.trim();
    if (rawName == null || rawName.isEmpty) {
      return _defaultSingular;
    }

    return _capitalize(rawName);
  }

  static String pluralFromClubPartition(ClubPartition? clubPartition) {
    final singular = singularFromClubPartition(clubPartition);

    if (singular.toLowerCase().endsWith('s')) {
      return singular;
    }

    if (RegExp(r'[aeiou]$', caseSensitive: false).hasMatch(singular)) {
      return '${singular}s';
    }

    return '${singular}es';
  }

  static String labelFromPhysicalPartition(
    PhysicalPartition partition, {
    ClubPartition? fallbackClubPartition,
  }) {
    return labelFromIdentifier(
      physicalIdentifier: partition.physicalIdentifier,
      partitionPhysicalId: partition.partitionPhysicalId,
      clubPartition: partition.clubPartition ?? fallbackClubPartition,
    );
  }

  static String labelFromIdentifier({
    required int? physicalIdentifier,
    required int? partitionPhysicalId,
    ClubPartition? clubPartition,
  }) {
    final singular = singularFromClubPartition(clubPartition);
    final identifier = physicalIdentifier ?? partitionPhysicalId;

    if (identifier == null) {
      return singular;
    }

    return '$singular $identifier';
  }

  static String _capitalize(String input) {
    if (input.isEmpty) return input;
    if (input.length == 1) return input.toUpperCase();
    return '${input[0].toUpperCase()}${input.substring(1)}';
  }
}