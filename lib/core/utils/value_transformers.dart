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

  // Sin esto, el `toJson` default de un DateTime local llama a
  // `toIso8601String()` sin agregar 'Z' ni offset (ej: "...T13:00:00.000") —
  // el backend (corriendo en TZ=UTC) lo interpreta como si esas 13:00 ya
  // fueran UTC, perdiendo el offset de Argentina (-3h) al guardar. Forzar
  // `.toUtc()` antes de serializar deja el instante real explícito, sin
  // depender del TZ del server para interpretarlo bien.
  static String toJsonDateTimeUtc(DateTime value) {
    return value.toUtc().toIso8601String();
  }

  static int? toJsonInt(dynamic value){

    if(value == null) return null;

    return int.tryParse(value);
  }
}
