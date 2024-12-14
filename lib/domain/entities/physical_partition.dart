import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/value_transformers.dart';
import 'club_partition.dart';


part 'physical_partition.freezed.dart';
part 'physical_partition.g.dart';
@freezed
class PhysicalPartition with _$PhysicalPartition {

  factory PhysicalPartition({
    @JsonKey(name: "partition_physical_id")
    required int partitionPhysicalId,
    @JsonKey(name: "club_partition_id")
    required int clubPartitionId, 
    @JsonKey(name: "min_players", fromJson: ValueTransformers.fromJsonInt)
    required int minPlayers, 
    @JsonKey(name: "max_players", fromJson: ValueTransformers.fromJsonIntNullable)
    required int? maxPlayers, 
    @JsonKey(name: "physical_identifier")
    required int? physicalIdentifier,
    @JsonKey(name: "is_cover") 
    required String? isCover, 
    required String? description,
    @JsonKey(defaultValue: 90) int? durationInMinutes,
    @JsonKey(name: "club_partition") 
    ClubPartition? clubPartition,

  }
  ) = _PhysicalPartition;

  factory PhysicalPartition.fromJson(Map<String, dynamic> json) => _$PhysicalPartitionFromJson(json);
}