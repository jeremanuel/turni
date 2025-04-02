import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeInterval {

  TimeInterval({this.initialDate, this.endDate});

  DateTime? initialDate;
  DateTime? endDate;

  TimeInterval.fromArray(List<DateTime?> array){
    if(array.isEmpty) return;

    if(array.length == 1){
      initialDate = array[0];
      return;
    }

    initialDate = array[0];
    endDate = array[1];
  }

  toArray(){
    return [initialDate, endDate];
  } 

  String getInitialTextString(){

    if(initialDate == null) return '';
    
    final aDate = DateTime(initialDate!.year, initialDate!.month, initialDate!.day);

    final now = DateTime.now().copyWith(hour: 0,second: 0, minute: 0, microsecond: 0, millisecond: 0);

    if(aDate == now) return "Hoy";

    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if(aDate == tomorrow) return "Mañana";

    return DateFormat.MMMd().format(initialDate!);

  }

  String getEndTextString(){

    if(endDate == null) return '';

    return DateFormat.MMMd().format(endDate!);

  }

  @override
  String toString() {
    return 'TimeInterval(initialDate: $initialDate, endDate: $endDate)';
  }

  String toStringTime(){

    final initialTime = initialDate != null ? DateFormat.Hm().format(initialDate!) : '';
    final endTime = initialDate != null ? DateFormat.Hm().format(endDate!) : '';

    return '$initialTime - $endTime';

  }

  Duration? getDuration(){
    
    if(initialDate != null && endDate != null){
      return endDate!.difference(initialDate!);
    }

    return null;
  }

  List<DateTime> generateDateRange() {
    
  List<DateTime> dateRange = [];
  DateTime currentDate = initialDate!;

  if(endDate == null){
    return [initialDate!];
  }

  while (currentDate.isBefore(endDate!) || currentDate.isAtSameMomentAs(endDate!)) {
    dateRange.add(currentDate);
    currentDate = currentDate.add(const Duration(days: 1));
  }

  return dateRange;
}


}

extension DateTimeExtension on DateTime {
  DateTime applied(TimeOfDay time) {
    return DateTime(year, month, day, time.hour, time.minute);
  }
}
