import 'package:json_annotation/json_annotation.dart';

part 'user_interest.g.dart';

@JsonSerializable()
class UserInterest {
  UserInterest({
    required this.activity,
    required this.clubTypeId,
    required this.tierInterest,
  });

  @JsonKey(name: "name")
  final String activity;
  @JsonKey(name: "club_type_id")
  final String clubTypeId;
  @JsonKey(name: "tier_interest")
  final String tierInterest;

  factory UserInterest.fromJson(Map<String, dynamic> json) =>
      _$UserInterestFromJson(json);
}
