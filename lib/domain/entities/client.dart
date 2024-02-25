
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:json_annotation/json_annotation.dart';

part 'client.g.dart';

@JsonSerializable()
class Client {

  Client({this.clientId, this.personId, this.userId});
  

  final String? clientId;
  final String? personId;
  final String? userId;

       

}

