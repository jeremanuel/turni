// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClubType _$ClubTypeFromJson(Map<String, dynamic> json) => ClubType(
      clubTypeId: json['club_type_id'] as String,
      name: json['name'] as String,
      logo: json['logo'] as String?,
    );

Map<String, dynamic> _$ClubTypeToJson(ClubType instance) => <String, dynamic>{
      'club_type_id': instance.clubTypeId,
      'name': instance.name,
      'logo': instance.logo,
    };
