// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      userId: json['userId'] as String?,
      socialId: json['socialId'] as String?,
      person: json['person'] == null
          ? null
          : Person.fromJson(json['person'] as Map<String, dynamic>),
      picture: json['picture'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'userId': instance.userId,
      'socialId': instance.socialId,
      'picture': instance.picture,
      'person': instance.person,
    };
