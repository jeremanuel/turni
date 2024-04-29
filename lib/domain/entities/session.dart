

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';


@freezed
class Session with _$Session{
   factory Session({
    required int sessionId, 
    required DateTime createdAt, 
    required DateTime startTime, 
    required String duration, 
    int? clientId, 
    required double price, 
    required int adminCreatorId, 
    required int partitionPhysicalId

  }) = _Session;

  Session._();

  getDurationInMinutes(){
    
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

}