// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_user_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GoogleUserRequest _$GoogleUserRequestFromJson(Map<String, dynamic> json) =>
    GoogleUserRequest(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String,
      photoUrl: json['photo_url'] as String?,
    );

Map<String, dynamic> _$GoogleUserRequestToJson(GoogleUserRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display_name': instance.displayName,
      'email': instance.email,
      'photo_url': instance.photoUrl,
    };
