import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/value_transformers.dart';

part 'club_info.g.dart';

@JsonSerializable()
class ClubInfo {
  ClubInfo({this.name, this.address, this.lat, this.lng});

  final String? name;
  final String? address;
  @JsonKey(fromJson: ValueTransformers.fromJsonDoubleNullable)
  final double? lat;
  @JsonKey(fromJson: ValueTransformers.fromJsonDoubleNullable)
  final double? lng;

  Map<String, dynamic> toJson() => _$ClubInfoToJson(this);
  factory ClubInfo.fromJson(Map<String, dynamic> json) =>
      _$ClubInfoFromJson(json);
}
