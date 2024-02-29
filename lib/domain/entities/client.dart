
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:turni/core/utils/value_transformers.dart';

part 'client.g.dart';

@JsonSerializable()
class Client {

  Client({this.clientId, this.personId, this.userId});



  @JsonKey(name: "client_id", fromJson: ValueTransformers.fromJsonString)
  final String? clientId;
  @JsonKey(name: "person_id", fromJson: ValueTransformers.fromJsonString)
  final String? personId;
  @JsonKey(name: "user_id", fromJson: ValueTransformers.fromJsonString)
  final String? userId;

       

}

