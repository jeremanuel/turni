// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      userId: ValueTransformers.fromJsonString(json['user_id']),
      socialId: json['social_id'] as String?,
      picture: json['picture'] as String?,
      token: json['token'] as String?,
      client: json['client'] == null
          ? null
          : Client.fromJson(json['client'] as Map<String, dynamic>),
      admin: json['admin'] == null
          ? null
          : Admin.fromJson(json['admin'] as Map<String, dynamic>),
      userInterest: (json['user_interest'] as List<dynamic>?)
          ?.map((e) => UserInterest.fromJson(e as Map<String, dynamic>))
          .toList(),
      templateMessage: json['template_message'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'user_id': instance.userId,
      'social_id': instance.socialId,
      'picture': instance.picture,
      'token': instance.token,
      'client': instance.client,
      'admin': instance.admin,
      'user_interest': instance.userInterest,
      'template_message': instance.templateMessage,
    };
