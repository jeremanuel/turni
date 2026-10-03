import '../../../../core/utils/types/time_interval.dart';

/// Reemplaza al selector de calendario como forma principal de elegir el
/// rango de carga — cubre el caso real (carga masiva a futuro) sin la
/// fricción de elegir dos fechas a mano. "Personalizado" deja el intervalo
/// tal cual lo arme el calendario existente (`FilterChipIntervalDate`), para
/// no perder esa capacidad.
enum DatePreset {
  today,
  week,
  twoWeeks,
  custom;

  /// null para `custom`: ahi el intervalo lo define el calendario, no el preset.
  TimeInterval? toInterval() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case DatePreset.today:
        return TimeInterval(initialDate: today, endDate: today);
      case DatePreset.week:
        return TimeInterval(initialDate: today, endDate: today.add(const Duration(days: 6)));
      case DatePreset.twoWeeks:
        return TimeInterval(initialDate: today, endDate: today.add(const Duration(days: 13)));
      case DatePreset.custom:
        return null;
    }
  }

  String get label {
    switch (this) {
      case DatePreset.today:
        return 'Hoy';
      case DatePreset.week:
        return 'Próximos 7 días';
      case DatePreset.twoWeeks:
        return 'Próximas 2 semanas';
      case DatePreset.custom:
        return 'Rango personalizado';
    }
  }
}
