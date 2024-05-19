import 'package:freezed_annotation/freezed_annotation.dart';

part 'coordinate.freezed.dart';
part 'coordinate.g.dart';

@freezed
class Coordinate with _$Coordinate {
  factory Coordinate({required double latitud, required double longitud}) =
      _Coordinate;

  factory Coordinate.fromJson(Map<String, dynamic> json) =>
      _$CoordinateFromJson(json);
}
