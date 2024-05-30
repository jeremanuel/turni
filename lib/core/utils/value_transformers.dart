
import 'package:intl/intl.dart';

class ValueTransformers {


  // Transforma el valor en string
  static String fromJsonString(value){

    if(value is String) return value;
    
    return value.toString();
  }

   static String? fromJsonStringNullable(value){

    if(value == null) return value;

    if(value is String) return value;
    
    return value.toString();
  }

  static int? fromJsonIntNullable(value){

    if(value == null) return value;

    if(value is int) return value;

    return int.parse(value);
  }

  static int fromJsonInt(value){
    
    if(value is int) return value;

    return int.parse(value);

  }

  static double fromJsonDouble(value){
    if(value is double) return value;

    return double.parse(value);
  }

  static DateTime fromJsonDateTimeLocale(value){
    final newVal = DateTime.parse(value).toLocal();

    return newVal;
  }
}