/// Micro-progresos de una rutina (`/gym/admin/routines/:id/progress`).
///
/// Cada ejercicio tiene una línea de tiempo: arranca con el plan y suma un
/// punto cada vez que cambian sus series, reps o peso, sea porque el cliente
/// lo cambió entrenando o porque un admin editó el plan.
library;

import 'gym.dart';

double _maxReps(List<Serie> series) => series.fold<int>(0, (max, s) => s.reps > max ? s.reps : max).toDouble();
double _maxKg(List<Serie> series) => series.fold<double>(0, (max, s) => s.weightKg > max ? s.weightKg : max);

/// Qué se grafica.
enum ProgressMetric { weight, reps, sets }

extension ProgressMetricLabel on ProgressMetric {
  String get label => switch (this) {
        ProgressMetric.weight => 'Peso',
        ProgressMetric.reps => 'Reps',
        ProgressMetric.sets => 'Series',
      };
}

double metricValue(List<Serie> series, ProgressMetric metric) => switch (metric) {
      ProgressMetric.weight => _maxKg(series),
      ProgressMetric.reps => _maxReps(series),
      ProgressMetric.sets => series.length.toDouble(),
    };

/// Diferencia entre dos versiones: "+5 kg · +1 rep".
class SeriesDelta {
  const SeriesDelta({required this.label, required this.up, required this.kg, required this.reps, required this.sets});

  final String label;

  /// Nada bajó.
  final bool up;
  final bool kg;
  final bool reps;
  final bool sets;

  static SeriesDelta between(List<Serie> before, List<Serie> after) {
    final kg = _maxKg(after) - _maxKg(before);
    final reps = _maxReps(after) - _maxReps(before);
    final sets = after.length - before.length;
    String sign(num n) => n > 0 ? '+' : '−';
    final parts = [
      if (kg != 0) '${sign(kg)}${formatKg(kg.abs())} kg',
      if (reps != 0) '${sign(reps)}${reps.abs().toStringAsFixed(0)} ${reps.abs() == 1 ? 'rep' : 'reps'}',
      if (sets != 0) '${sign(sets)}${sets.abs()} ${sets.abs() == 1 ? 'serie' : 'series'}',
    ];
    return SeriesDelta(
      label: parts.isEmpty ? 'Cambiaron las series' : parts.join(' · '),
      up: kg >= 0 && reps >= 0 && sets >= 0,
      kg: kg != 0,
      reps: reps != 0,
      sets: sets != 0,
    );
  }
}

class ProgressPoint {
  const ProgressPoint({required this.date, required this.series, required this.byClient, this.adminName, this.byMe = false});

  final DateTime date;
  final List<Serie> series;

  /// true: lo cambió el cliente entrenando. false: una versión del plan.
  final bool byClient;
  final String? adminName;

  /// El cambio de plan lo hizo el admin logueado.
  final bool byMe;

  factory ProgressPoint.fromJson(Map<String, dynamic> json) => ProgressPoint(
        date: DateTime.parse(json['date'] as String).toLocal(),
        series: seriesFromJson(json['series']),
        byClient: json['source'] == 'CLIENT',
        adminName: json['admin_name'] as String?,
        byMe: json['by_me'] == true,
      );

  /// "Mai entrenando", "Vos, al armar la rutina", "Sol, en el plan".
  String who(String clientFirstName, {required bool first}) {
    if (byClient) return '$clientFirstName entrenando';
    final name = byMe ? 'Vos' : (adminName ?? 'El profe');
    return first ? '$name, al armar la rutina' : '$name, en el plan';
  }
}

class ExerciseProgress {
  const ExerciseProgress({
    required this.id,
    required this.name,
    required this.groupId,
    required this.groupName,
    required this.plan,
    required this.points,
  });

  /// `routine_exercise_id`.
  final int id;
  final String name;
  final int groupId;
  final String groupName;
  final List<Serie> plan;
  final List<ProgressPoint> points;

  int get changesCount => points.isEmpty ? 0 : points.length - 1;
  ProgressPoint? get first => points.isEmpty ? null : points.first;
  ProgressPoint? get last => points.isEmpty ? null : points.last;
  ProgressPoint? get lastChange => points.length > 1 ? points.last : null;

  SeriesDelta? get totalDelta => changesCount == 0 ? null : SeriesDelta.between(first!.series, last!.series);
  SeriesDelta? deltaAt(int index) => index <= 0 ? null : SeriesDelta.between(points[index - 1].series, points[index].series);

  /// Lo último que hizo el cliente, si es distinto del plan actual (para "Usar" en el editor).
  ProgressPoint? get doneBeyondPlan {
    final last = this.last;
    if (last == null || !last.byClient) return null;
    if (last.series.length == plan.length && [for (var i = 0; i < plan.length; i++) plan[i] == last.series[i]].every((same) => same)) return null;
    return last;
  }

  factory ExerciseProgress.fromJson(Map<String, dynamic> json) => ExerciseProgress(
        id: (json['routine_exercise_id'] as num).toInt(),
        name: json['name'] as String? ?? 'Ejercicio',
        groupId: (json['routine_group_id'] as num).toInt(),
        groupName: json['group_name'] as String? ?? 'Grupo',
        plan: seriesFromJson(json['plan']),
        points: ((json['points'] as List?) ?? const []).map((p) => ProgressPoint.fromJson(p as Map<String, dynamic>)).toList(),
      );
}

class RoutineProgress {
  const RoutineProgress({required this.routineId, required this.startDate, required this.exercises});

  final String routineId;
  final DateTime startDate;
  final List<ExerciseProgress> exercises;

  ExerciseProgress? exercise(int routineExerciseId) {
    for (final exercise in exercises) {
      if (exercise.id == routineExerciseId) return exercise;
    }
    return null;
  }

  /// Fecha del último cambio de cualquier ejercicio.
  DateTime? get lastChangeDate {
    DateTime? out;
    for (final exercise in exercises) {
      final date = exercise.lastChange?.date;
      if (date != null && (out == null || date.isAfter(out))) out = date;
    }
    return out;
  }

  factory RoutineProgress.fromJson(Map<String, dynamic> json) => RoutineProgress(
        routineId: json['routine_id'] as String,
        startDate: DateTime.parse(json['start_date'] as String),
        exercises: ((json['exercises'] as List?) ?? const []).map((e) => ExerciseProgress.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

const _weekdaysShort = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

/// "mar 14 oct".
String weekdayDate(DateTime date) => '${_weekdaysShort[date.weekday - 1]} ${shortDate(date, year: false)}';
