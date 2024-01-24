
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  User(this.givenName, this.familyName, this.email, this.picture, this.accessToken,);
  
  @JsonKey(name: 'given-name')
  final String givenName;
  @JsonKey(name: 'family_name')
  final String familyName;
  final String email;
  final String picture;
  final String accessToken;

}

