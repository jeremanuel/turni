
import 'package:json_annotation/json_annotation.dart';

part 'activity.g.dart';

@JsonSerializable()
class Activity {

  Activity({
    required this.name
  });
  final String name;

  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);
}