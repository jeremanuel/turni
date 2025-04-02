import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/value_transformers.dart';

part 'person.g.dart';

@JsonSerializable()
class Person {
  Person({
      this.personId,
      this.phone,
      required this.name,
      required this.lastName,
      required this.email,
      this.birdDate,
      this.observation
      });

  final String name;
  @JsonKey(name: "last_name")
  final String lastName;
  final String? email;
  final String? phone;
  @JsonKey(name: "person_id", fromJson: ValueTransformers.fromJsonString)
  final String? personId;
  @JsonKey(name: "bird_date", fromJson: ValueTransformers.fromJsonDateTimeLocaleNullable)
  final DateTime? birdDate;
  final String? observation;

  

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);


  String get fullName => "$name $lastName";

  bool hasPhone() => phone != null && phone!.isNotEmpty;
  bool hasEmail() => email != null && email!.isNotEmpty;

  Map<String, dynamic> toJson() => _$PersonToJson(this);
}
