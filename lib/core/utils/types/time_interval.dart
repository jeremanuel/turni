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

}

extension DateTimeExtension on DateTime {
  DateTime applied(TimeOfDay time) {
    return DateTime(year, month, day, time.hour, time.minute);
  }
}
