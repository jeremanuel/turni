// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Client _$ClientFromJson(Map<String, dynamic> json) => Client(
      clientId: ValueTransformers.fromJsonString(json['client_id']),
      personId: ValueTransformers.fromJsonString(json['person_id']),
      userId: ValueTransformers.fromJsonString(json['user_id']),
    );

Map<String, dynamic> _$ClientToJson(Client instance) => <String, dynamic>{
      'client_id': instance.clientId,
      'person_id': instance.personId,
      'user_id': instance.userId,
    };
