// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turno.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Turno _$TurnoFromJson(Map<String, dynamic> json) => Turno(
      startAt: DateTime.parse(json['startAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      duration: json['duration'] as String,
      place: Place.fromJson(json['place'] as Map<String, dynamic>),
      persons: json['persons'] as int,
      price: (json['price'] as num).toDouble(),
    );

Map<String, dynamic> _$TurnoToJson(Turno instance) => <String, dynamic>{
      'startAt': instance.startAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'duration': instance.duration,
      'place': instance.place,
      'persons': instance.persons,
      'price': instance.price,
    };
