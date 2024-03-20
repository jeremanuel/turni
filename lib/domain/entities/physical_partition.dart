import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class PhysicalPartition {
/*     partition_physical_id!: number;
    club_partition_id!: number;
    min_players!: number;
    max_players!: number | null;
    physical_identifier!: number | null;
    is_cover!: string | null;
    description!: string | null; */

  final int partitionPhysicalId;
  final int clubPartitionId;
  final int minPlayers;
  final int? maxPlayers;
  final int? physicalIdentifier;
  final String? isCover;
  final String? description;
  

  PhysicalPartition({
    required this.partitionPhysicalId,
    required this.clubPartitionId, 
    required this.minPlayers, 
    required this.maxPlayers, 
    required this.physicalIdentifier, 
    required this.isCover, 
    required this.description,
    
    
    });


}

