import 'package:json_annotation/json_annotation.dart';

part 'session.g.dart';

@JsonSerializable()
class Session {
  Session(
      {this.sessionId,
      this.createdAt,
      this.startTime,
      this.duration,
      this.clientId,
      this.price,
      this.adminCreatorId,
      this.partitionPhysicalId});

  @JsonKey(name: "session_id")
  final int? sessionId;
  @JsonKey(name: "client_id")
  final int? clientId;
  @JsonKey(name: "partition_physical_id")
  final int? partitionPhysicalId;
  @JsonKey(name: "created_at")
  final DateTime? createdAt;
  @JsonKey(name: "start_time")
  final DateTime? startTime;
  final String? duration;
  final double? price;
  final int? adminCreatorId;

  getDurationInMinutes() {
    final [hours, minutes] = duration!.split(':');

    return (int.parse(hours) * 60) + int.parse(minutes);
  }

  get endTime => startTime!.add(Duration(minutes: getDurationInMinutes()));

  Map<String, dynamic> toJson() => _$SessionToJson(this);
  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);
}
