
import 'package:json_annotation/json_annotation.dart';

part 'person.g.dart';

@JsonSerializable()
class Person {

  Person( {this.personId, this.phone, required this.name, required this.lastName, required this.email});
  

  final String name;
  final String lastName;
  final String email;
  final String? phone;
  final String? personId;


  
  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);

  

}

