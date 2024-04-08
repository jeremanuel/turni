
import 'package:json_annotation/json_annotation.dart';
import 'package:turni/core/utils/value_transformers.dart';

import 'person.dart';

part 'client.g.dart';

@JsonSerializable()
class Client {

  Client({this.clientId, this.personId, this.userId, this.person});



  @JsonKey(name: "client_id", fromJson: ValueTransformers.fromJsonString)
  final String? clientId;
  @JsonKey(name: "person_id", fromJson: ValueTransformers.fromJsonString)
  final String? personId;
  @JsonKey(name: "user_id", fromJson: ValueTransformers.fromJsonString)
  final String? userId;

  final Person? person;


  Map<String, dynamic> toJson() => _$ClientToJson(this);
  factory Client.fromJson(Map<String,dynamic> json) => _$ClientFromJson(json);

       

}
