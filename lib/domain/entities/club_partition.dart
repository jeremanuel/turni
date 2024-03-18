
import 'package:freezed_annotation/freezed_annotation.dart';

import 'club_type.dart';
import 'physical_partition.dart';

part 'club_partition.freezed.dart';

@freezed
class ClubPartition with _$ClubPartition {

    /*
        club_partition_id!: number;
    club_id!: number;
    club_type_id!: number;
    phone!: string | null;
 
     */
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