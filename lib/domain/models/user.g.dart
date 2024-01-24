// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      json['given-name'] as String,
      json['family_name'] as String,
      json['email'] as String,
      json['picture'] as String,
      json['accessToken'] as String,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'given-name': instance.givenName,
      'family_name': instance.familyName,
      'email': instance.email,
      'picture': instance.picture,
      'accessToken': instance.accessToken,
    };
