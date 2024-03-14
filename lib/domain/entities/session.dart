import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Session {
  
  final int sessionId;
  final DateTime createdAt;
  final DateTime startTime;
  final String duration;
  final int? clientId;
  final double price;
  final int adminCreatorId;
  final int partitionPhysicalId;

  Session(
    this.sessionId, 
    this.createdAt, 
    this.startTime, 
    this.duration, 
    this.clientId, 
    this.price, 
    this.adminCreatorId, 
    this.partitionPhysicalId
  );

  getDurationInMinutes(){
    
   final [hours, minutes] = duration.split(':');

   return (int.parse(hours) * 60) + int.parse(minutes);

  }

  get endTime => startTime.add(Duration(minutes: getDurationInMinutes()));
  
}