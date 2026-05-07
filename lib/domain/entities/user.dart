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
    this.userInterest
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


  Coordinate? location;

  bool get isAdmin {
    return admin != null;
  }

  factory User.fromGoogleSignInUserData(GoogleSignInUserData userData) {
    final nameParts = _splitDisplayName(userData.displayName);
    final fallbackName = userData.email.split('@').first;

    return User(
      socialId: userData.id,
      picture: userData.photoUrl,
      client: Client(
        person: Person(
          name: nameParts.firstName.isEmpty
              ? fallbackName
              : nameParts.firstName,
          lastName: nameParts.lastName,
          email: userData.email,
        ),
      ),
    );
  }

  static ({String firstName, String lastName}) _splitDisplayName(
    String? displayName,
  ) {
    final normalized = (displayName ?? '').trim();

    if (normalized.isEmpty) {
      return (firstName: '', lastName: '');
    }

    final parts = normalized.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return (firstName: parts.first, lastName: '');
    }

    return (firstName: parts.first, lastName: parts.sublist(1).join(' '));
  }

  Map<String, dynamic> toJson() => _$UserToJson(this);
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Person get person {
    if (admin != null) {
      return admin!.person;
    }

    return client!.person!;
  }
}
