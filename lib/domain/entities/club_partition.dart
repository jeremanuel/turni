
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/value_transformers.dart';
import 'club_type.dart';
import 'physical_partition.dart';
import 'subscription/subscription.dart';

part 'club_partition.freezed.dart';
part 'club_partition.g.dart';

@freezed
sealed class ClubPartition with _$ClubPartition {


    const factory ClubPartition({
      int? club_partition_id,
      required int club_id,
      @JsonKey(fromJson: ValueTransformers.fromJsonInt)
      required int club_type_id,
      String? phone,

      // Relations
      @JsonKey(name: "partition_physical")
      List<PhysicalPartition>? physicalPartitions,
       @JsonKey(name: "club_type")
      ClubType? clubType,
      @JsonKey(name: "subscription")
      List<Subscription>? subscriptions,

  }) = _ClubPartition;


    factory ClubPartition.fromJson(Map<String, dynamic> json) => _$ClubPartitionFromJson(json);


}