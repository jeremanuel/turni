
import 'package:json_annotation/json_annotation.dart';
import 'package:turni/core/utils/value_transformers.dart';

part 'person.g.dart';

@JsonSerializable()
class Person {

  Person( {this.personId, this.phone, required this.name, required this.lastName, required this.email});
  

  final String name;
  @JsonKey(name: "last_name")
  final String lastName;
  final String email;
  final String? phone;
  @JsonKey(name: "person_id", fromJson: ValueTransformers.fromJsonString)
  final String? personId;


  
  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);

  

}

