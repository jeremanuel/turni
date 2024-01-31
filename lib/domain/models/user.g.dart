// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      name: json['name'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      socialId: json['socialId'] as String?,
      picture: json['picture'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'name': instance.name,
      'lastName': instance.lastName,
      'email': instance.email,
      'picture': instance.picture,
      'socialId': instance.socialId,
    };
