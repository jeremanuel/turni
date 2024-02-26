

import 'package:json_annotation/json_annotation.dart';


part "google_user_request.g.dart";

@JsonSerializable()
class GoogleUserRequest {
  /*    "id":"25",
        "id_token":"2",
        "display_name":"Jeremias Manuel",
        "email":"jeeremanuell@gmail.com",
        "photo_url":"" */


    final String id;
    @JsonKey(name: "display_name")
    final String displayName;
    final String email;

    @JsonKey(name: "photo_url")
    final String? photoUrl;

  GoogleUserRequest({required this.id, required this.displayName, required this.email, this.photoUrl});

  Map<String, dynamic> toJson() => _$GoogleUserRequestToJson(this);
    
}