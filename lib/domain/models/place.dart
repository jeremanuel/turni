import 'package:json_annotation/json_annotation.dart';
part 'place.g.dart';
@JsonSerializable()
class Place {

  Place(this.name, this.court, this.courtDescription, this.photo);

  final String name;
  final String court;
  final String courtDescription;
  final String photo;






  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceToJson(this);

}