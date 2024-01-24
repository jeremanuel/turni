import 'package:json_annotation/json_annotation.dart';
import 'package:turni/domain/models/place.dart';
part 'turno.g.dart';

@JsonSerializable()
class Turno {
  
      Turno({
    required this.startAt,
    required this.createdAt,
    required this.duration,
    required this.place,
    required this.persons,
    required this.price
  });



  final DateTime startAt;
  final DateTime createdAt;
  
  final String duration;
  final Place place;
  final int persons;
  final double price;
  static Map<String, dynamic> DateTimeToJson(DateTime timestamp) {
    return {
      "seconds":timestamp.millisecondsSinceEpoch / 1000,
    };
  }



  Map<String, dynamic> toJson() => _$TurnoToJson(this);

  factory Turno.fromJson(Map<String, dynamic> json) => _$TurnoFromJson(json);
}