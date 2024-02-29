// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Person _$PersonFromJson(Map<String, dynamic> json) => Person(
      personId: ValueTransformers.fromJsonString(json['person_id']),
      phone: json['phone'] as String?,
      name: json['name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
      'name': instance.name,
      'last_name': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'person_id': instance.personId,
    };
