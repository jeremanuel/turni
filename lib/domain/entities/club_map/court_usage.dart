/// Uso de cada cancha en un período (`GET /admin/club-map/usage`): minutos
/// de turnos cargados (ofrecidos) y reservados.
class CourtUsage {
  final int courtId;
  final int offeredMinutes;
  final int reservedMinutes;

  /// reservados / ofrecidos, de 0 a 1. `null`: la cancha no tuvo turnos.
  final double? usage;

  const CourtUsage({required this.courtId, required this.offeredMinutes, required this.reservedMinutes, this.usage});

  factory CourtUsage.fromJson(Map<String, dynamic> json) => CourtUsage(
        courtId: json['partition_physical_id'] as int,
        offeredMinutes: (json['offered_minutes'] as num).toInt(),
        reservedMinutes: (json['reserved_minutes'] as num).toInt(),
        usage: (json['usage'] as num?)?.toDouble(),
      );

  /// "72 %", o null si no tuvo turnos.
  String? get percentLabel => usage == null ? null : '${(usage! * 100).round()} %';
}

class CourtUsageView {
  final DateTime from;
  final DateTime to;
  final Map<int, CourtUsage> byCourt;

  const CourtUsageView({required this.from, required this.to, required this.byCourt});

  factory CourtUsageView.fromJson(Map<String, dynamic> json) => CourtUsageView(
        from: DateTime.parse(json['from'] as String).toLocal(),
        to: DateTime.parse(json['to'] as String).toLocal(),
        byCourt: {
          for (final c in (json['courts'] as List).map((c) => CourtUsage.fromJson(c as Map<String, dynamic>))) c.courtId: c,
        },
      );
}

/// Horas con hasta un decimal: 90 → "1,5 h", 600 → "10 h".
String formatHours(int minutes) {
  final hours = minutes / 60;
  final text = hours == hours.roundToDouble() ? hours.toStringAsFixed(0) : hours.toStringAsFixed(1);
  return '${text.replaceAll('.', ',')} h';
}
