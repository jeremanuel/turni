import 'package:freezed_annotation/freezed_annotation.dart';

import 'club_partition.dart';
import 'person.dart';

part 'admin.freezed.dart';
part 'admin.g.dart';

@freezed
sealed class Admin with _$Admin {

  const factory Admin({
    required Person person,
    @JsonKey(name: "admin_club_partition", fromJson: Admin.fromJsonClubPartitions)
    required List<ClubPartition> clubPartitions,
    @JsonKey(name: "admin_id")
    required int adminId
    }) = _Admin;

  factory Admin.fromJson(Map<String, dynamic> json) => _$AdminFromJson(json);

  static List<ClubPartition> fromJsonClubPartitions(List<dynamic> json) {
    return json.map((e) => ClubPartition.fromJson(e['club_partition'])).toList();
  }

}