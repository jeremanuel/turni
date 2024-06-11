import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/value_transformers.dart';

part 'session.freezed.dart';
part 'session.g.dart';

@freezed
class Session with _$Session {
  factory Session({
    @JsonKey(name: "session_id") required int sessionId,
    @JsonKey(name: "created_at") required DateTime createdAt,
    @JsonKey(
        name: "start_time", fromJson: ValueTransformers.fromJsonDateTimeLocale)
    required DateTime startTime,
    @JsonKey(defaultValue: "1:30") required String duration,
    @JsonKey(name: "client_id") int? clientId,
    @JsonKey(fromJson: ValueTransformers.fromJsonDouble) required double price,
    @JsonKey(name: "admin_creator_id") int? adminCreatorId,
    @JsonKey(name: "partition_physical_id") required int partitionPhysicalId,
    @JsonKey(name: "club_name") String? clubName,
    @JsonKey(name: "club_type_name") String? clubTypeName,
  }) = _Session;

  Session._();

  getDurationInMinutes() {
    if (duration != null) return 0;

    final [hours, minutes] = duration.split(':');

    return (int.parse(hours) * 60) + int.parse(minutes);
  }

  static Session fromDates(DateTime startTime, TimeOfDay duration) {
    return Session(
        sessionId: 1,
        createdAt: DateTime.now(),
        startTime: startTime,
        duration: "${duration.hour}:${duration.minute}",
        price: 1500,
        adminCreatorId: 1,
        partitionPhysicalId: 1);
  }

  get endTime => startTime.add(Duration(minutes: getDurationInMinutes()));

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);

  bool get isReserved => clientId != null;
}
