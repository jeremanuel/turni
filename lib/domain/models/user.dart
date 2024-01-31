
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  User({required this.name, required this.lastName, required this.email, this.socialId, this.picture});
  

  final String name;
  final String lastName;
  final String email;
  final String? picture;

  final String? socialId;

  factory User.fromGoogleSignInUserData(GoogleSignInUserData userData) => User(
    name: userData.displayName!,
    email: userData.email,
    lastName: "",
    picture: userData.photoUrl,
    socialId: userData.id
    
  );
        
      
        
  

}

