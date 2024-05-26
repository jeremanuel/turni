

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

@freezed

class Session with _$Session{
   factory Session({
    @JsonKey(name: "session_id")
    required int sessionId, 
    @JsonKey(name: "created_at")
    required DateTime createdAt, 
    @JsonKey(name: "start_time")
    required DateTime startTime, 
    required String duration, 
    @JsonKey(name: "client_id")
    int? clientId, 
    required double price, 
    @JsonKey(name: "admin_creator_id")
    int? adminCreatorId, 
    @JsonKey(name: "partition_physical_id")

    required int partitionPhysicalId

  }) = _Session;

  Session._();


  getDurationInMinutes() {
    final [hours, minutes] = duration.split(':');

    return (int.parse(hours) * 60) + int.parse(minutes);
  }

  static Session fromDates(DateTime startTime, TimeOfDay duration){
    return Session(
      sessionId: 1,
      createdAt: DateTime.now(), 
      startTime: startTime, 
      duration: "${duration.hour}:${duration.minute}", 
      price: 1500, 
      adminCreatorId: 1,
      partitionPhysicalId: 1
    );
  }

  get endTime => startTime.add(Duration(minutes: getDurationInMinutes()));


   factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);
 

}
