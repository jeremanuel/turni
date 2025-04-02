import 'package:intl/intl.dart';

class DateFunctions {

  /// @Param todayAndTomorrow 
  /// Indica si tiene que usar textos 'hoy', 'mañana', 'ayer' para representar esos dias. 
  static String formatDateToDayMonth(DateTime date, [bool todayAndTomorrow = true]){
    
    if(!todayAndTomorrow) return DateFormat.MMMd().format(date);

    final aDate = DateTime(date.year, date.month, date.day);

    final now = DateTime.now().copyWith(hour: 0,second: 0, minute: 0, microsecond: 0, millisecond: 0);

    if(aDate == now) return "Hoy";

    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if(aDate == tomorrow) return "Mañana";

    final yesterday = DateTime(now.year, now.month, now.day - 1);


    if(aDate == yesterday) return "Ayer";

    return DateFormat.MMMd().format(date);

  }

  static String formatDateToDefaultFormat(DateTime date){
    return DateFormat.yMd().format(date);
  }

  static DateTime? tryParseDate(String? value){
    if(value == null) return null;

    return DateFormat.yMd().tryParse(value);
  }

  static String differenceInYears(DateTime date){
    return (DateTime.now().difference(date).inDays / 365).floor().toString();
  }

}