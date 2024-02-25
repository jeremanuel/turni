// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Client _$ClientFromJson(Map<String, dynamic> json) => Client(
      clientId: json['clientId'] as String?,
      personId: json['personId'] as String?,
      userId: json['userId'] as String?,
    );

Map<String, dynamic> _$ClientToJson(Client instance) => <String, dynamic>{
      'clientId': instance.clientId,
      'personId': instance.personId,
      'userId': instance.userId,
    };
