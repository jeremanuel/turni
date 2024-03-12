import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:turni/core/utils/value_transformers.dart';
import 'package:turni/domain/entities/person.dart';

part 'user.g.dart';

@JsonSerializable()
class User {

  User({this.userId, this.socialId, this.person, this.picture, this.token});
  
  @JsonKey(name: "user_id", fromJson: ValueTransformers.fromJsonString)
  final String? userId;
  
  @JsonKey(name: "social_id")
  final String? socialId;
  final String? picture;
  final Person? person;
  final String? token;

  bool isAdmin(){
    return true;
  }

  factory User.fromGoogleSignInUserData(GoogleSignInUserData userData) => User(
   socialId: userData.id,
       person: Person(name: userData.displayName!.split(' ')[0], lastName: userData.displayName!.split(' ')[1], email: userData.email)
    
  );

  Map<String, dynamic> toJson() => _$UserToJson(this);
  factory User.fromJson(Map<String,dynamic> json) => _$UserFromJson(json);
        
      
        
  

}

