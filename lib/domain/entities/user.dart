import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/entities/coordinate.dart';
import '../../core/utils/value_transformers.dart';
import 'admin.dart';
import 'person.dart';

import 'client.dart';
import 'user_interest.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  User({
    this.userId,
    this.socialId,
    this.picture,
    this.token,
    this.client,
    this.admin,
    this.userInterest,
    this.templateMessage,
  });

  @JsonKey(name: "user_id", fromJson: ValueTransformers.fromJsonString)
  final String? userId;

  @JsonKey(name: "social_id")
  final String? socialId;
  final String? picture;
  final String? token;

  final Client? client;
  final Admin? admin;

  @JsonKey(name: "user_interest")
  final List<UserInterest>? userInterest;

  @JsonKey(name: "template_message")
  final String? templateMessage;
  Coordinate? location;

  bool get isAdmin {
    return admin != null;
  }

  factory User.fromGoogleSignInUserData(GoogleSignInUserData userData) => User(
        socialId: userData.id,
        client: Client(
          person: Person(
            name: userData.displayName!.split(' ')[0],
            lastName: userData.displayName!.split(' ')[1],
            email: userData.email,
          ),
        ),
      );

  Map<String, dynamic> toJson() => _$UserToJson(this);
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Person get person {
    if (admin != null) {
      return admin!.person;
    }

    return client!.person!;
  }
}
