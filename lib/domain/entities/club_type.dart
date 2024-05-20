import 'package:freezed_annotation/freezed_annotation.dart';

part 'club_type.g.dart';

@JsonSerializable()
class ClubType {
  ClubType({required this.clubTypeId, required this.name, this.logo});

  @JsonKey(name: "club_type_id")
  final int clubTypeId;
  final String name;
  final String? logo;

  Map<String, dynamic> toJson() => _$ClubTypeToJson(this);
  factory ClubType.fromJson(Map<String, dynamic> json) =>
      _$ClubTypeFromJson(json);
}
