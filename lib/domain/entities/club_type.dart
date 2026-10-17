import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/value_transformers.dart';

part 'club_type.g.dart';

/// Tipo de modalidad (Pádel, Yoga, Peluquería). Además del nombre trae el
/// vocabulario por defecto de sus espacios y su cupo, y qué funciones usa
/// (ver `PartitionVocabulary`). Esos campos son null cuando el endpoint no
/// los manda (consultas viejas): se toman los de una cancha.
@JsonSerializable()
class ClubType {
  ClubType({
    required this.clubTypeId,
    required this.name,
    this.logo,
    this.category,
    this.spaceSingular,
    this.spacePlural,
    this.spaceGender,
    this.participantSingular,
    this.participantPlural,
    this.usesMap,
    this.usesCover,
    this.usesCapacity,
  });

  @JsonKey(name: "club_type_id", fromJson: ValueTransformers.fromJsonInt)
  final int clubTypeId;
  final String name;
  final String? logo;

  /// COURT | CLASS | PERSONAL | OTHER
  final String? category;
  @JsonKey(name: "space_singular")
  final String? spaceSingular;
  @JsonKey(name: "space_plural")
  final String? spacePlural;

  /// 'f' | 'm'
  @JsonKey(name: "space_gender")
  final String? spaceGender;
  @JsonKey(name: "participant_singular")
  final String? participantSingular;
  @JsonKey(name: "participant_plural")
  final String? participantPlural;
  @JsonKey(name: "uses_map")
  final bool? usesMap;
  @JsonKey(name: "uses_cover")
  final bool? usesCover;
  @JsonKey(name: "uses_capacity")
  final bool? usesCapacity;

  Map<String, dynamic> toJson() => _$ClubTypeToJson(this);
  factory ClubType.fromJson(Map<String, dynamic> json) =>
      _$ClubTypeFromJson(json);
}
