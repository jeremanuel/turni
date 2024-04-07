
import 'package:freezed_annotation/freezed_annotation.dart';

import 'club_type.dart';
import 'physical_partition.dart';

part 'club_partition.freezed.dart';

@freezed
class ClubPartition with _$ClubPartition {


    const factory ClubPartition({
      int? club_partition_id,
      required int club_id,
      required int club_type_id,
      required String phone,

      // Relations
      List<PhysicalPartition>? physicalPartitions,
      ClubType? clubType

  }) = _ClubPartition;

}