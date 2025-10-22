class ValueTransformers {
  // Transforma el valor en string
  static String fromJsonString(dynamic value) {
    if (value is String) return value;

    return value.toString();
  }

  static String? fromJsonStringNullable(dynamic value) {
    if (value == null) return value;

    if (value is String) return value;

    return value.toString();
  }

  static int? fromJsonIntNullable(dynamic value) {
    if (value == null) return value;

    if (value is int) return value;

    return int.parse(value);
  }

  static int fromJsonInt(dynamic value) {
    if (value is int) return value;

    return int.parse(value);
  }

  static double fromJsonDouble(dynamic value) {
    if (value is double) return value;

    return double.parse(value.toString());
  }

  static double? fromJsonDoubleNullable(dynamic value) {
    if (value is double) return value;

    return double.tryParse(value.toString());
  }

  static DateTime fromJsonDateTimeLocale(dynamic value) {
    final newVal = DateTime.parse(value).toLocal();

    return newVal;
  }

  static DateTime? fromJsonDateTimeLocaleNullable(dynamic value) {
    if(value == null) return null;

    final newVal = DateTime.parse(value).toLocal();

    return newVal;
  }

  static int? toJsonInt(dynamic value){
    
    if(value == null) return null;

    return int.tryParse(value);
  }
}
