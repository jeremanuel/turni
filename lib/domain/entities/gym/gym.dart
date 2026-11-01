/// Rutinas de gimnasio del admin (backend `turni_mono_be`, `/gym/admin`).
///
/// Una rutina se divide en grupos ("Empuje", "Piernas"…) que el cliente
/// entrena de a uno por día, en el orden de la rutina.
library;

int _int(dynamic value) => (value as num?)?.toInt() ?? 0;
DateTime? _date(dynamic value) => value == null ? null : DateTime.tryParse('$value')?.toLocal();

/// Una serie: repeticiones y peso. `weightKg` 0 = sin peso.
class Serie {
  const Serie({required this.reps, required this.weightKg});

  final int reps;
  final double weightKg;

  factory Serie.fromJson(Map<String, dynamic> json) =>
      Serie(reps: _int(json['reps']), weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0);

  Map<String, dynamic> toJson() => {'reps': reps, 'weight_kg': weightKg};

  Serie copyWith({int? reps, double? weightKg}) => Serie(reps: reps ?? this.reps, weightKg: weightKg ?? this.weightKg);

  @override
  bool operator ==(Object other) => other is Serie && other.reps == reps && other.weightKg == weightKg;

  @override
  int get hashCode => Object.hash(reps, weightKg);
}

List<Serie> seriesFromJson(dynamic json) =>
    ((json as List?) ?? const []).map((s) => Serie.fromJson(s as Map<String, dynamic>)).toList();

/// "62,5" / "60".
String formatKg(double kg) {
  final rounded = (kg * 10).round() / 10;
  final text = rounded == rounded.roundToDouble() ? rounded.toStringAsFixed(0) : rounded.toStringAsFixed(1);
  return text.replaceAll('.', ',');
}

/// "62,5" o "62.5" → 62.5. null si no es un número.
double? parseKg(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || value < 0) return null;
  return value;
}

bool isUniform(List<Serie> series) => series.toSet().length <= 1;

/// Descanso más largo que acepta el back (30 min).
const maxRestSeconds = 1800;

/// Descanso entre series: "1:30", "0:45", "3:00".
String formatRest(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// "2:30" o "150" (segundos) → 150. null si no es un descanso válido.
int? parseRest(String text) {
  final value = text.trim();
  if (value.isEmpty) return null;
  final parts = value.split(':');
  int? seconds;
  if (parts.length == 1) {
    seconds = int.tryParse(parts.first);
  } else if (parts.length == 2) {
    final minutes = int.tryParse(parts[0].isEmpty ? '0' : parts[0]);
    final secs = int.tryParse(parts[1]);
    if (minutes != null && secs != null && secs < 60) seconds = minutes * 60 + secs;
  }
  if (seconds == null || seconds < 0 || seconds > maxRestSeconds) return null;
  return seconds;
}

/// "4 × 8 · 60 kg", "4 × 12/10/8/6 · 50→57,5 kg", "3 × 12".
String seriesLabel(List<Serie> series) {
  if (series.isEmpty) return 'Sin series';
  final reps = series.map((s) => s.reps).toSet().length == 1 ? '${series.first.reps}' : series.map((s) => s.reps).join('/');
  final weights = series.map((s) => s.weightKg);
  final first = series.first.weightKg;
  final last = series.last.weightKg;
  final max = weights.reduce((a, b) => a > b ? a : b);
  final weight = max == 0 ? '' : (weights.toSet().length == 1 ? ' · ${formatKg(first)} kg' : ' · ${formatKg(first)}→${formatKg(last)} kg');
  return '${series.length} × $reps$weight';
}

class Muscle {
  const Muscle({required this.id, required this.name, this.region});

  final int id;
  final String name;

  /// Zona del cuerpo: Piernas, Pecho, Espalda, Hombro, Brazos, Core.
  final String? region;

  factory Muscle.fromJson(Map<String, dynamic> json) =>
      Muscle(id: _int(json['muscle_id']), name: json['name'] as String, region: json['region'] as String?);
}

/// Ejercicio del catálogo (global de Turni o propio del club).
class CatalogExercise {
  const CatalogExercise({
    required this.id,
    required this.name,
    required this.muscles,
    this.clubOwn = false,
    this.lastForClient,
  });

  final int id;
  final String name;
  final List<Muscle> muscles;
  final bool clubOwn;

  /// Lo último que se le planificó al cliente de este ejercicio.
  final List<Serie>? lastForClient;

  Set<String> get regions => muscles.map((m) => m.region).whereType<String>().toSet();

  factory CatalogExercise.fromJson(Map<String, dynamic> json) => CatalogExercise(
        id: _int(json['exercise_id']),
        name: json['name'] as String,
        muscles: ((json['muscles'] as List?) ?? const []).map((m) => Muscle.fromJson(m as Map<String, dynamic>)).toList(),
        clubOwn: json['club_id'] != null,
        lastForClient: json['last_for_client'] == null ? null : seriesFromJson(json['last_for_client']),
      );
}

class ExerciseCatalog {
  const ExerciseCatalog({required this.exercises, required this.muscles});

  final List<CatalogExercise> exercises;
  final List<Muscle> muscles;

  factory ExerciseCatalog.fromJson(Map<String, dynamic> json) => ExerciseCatalog(
        exercises: ((json['exercises'] as List?) ?? const []).map((e) => CatalogExercise.fromJson(e as Map<String, dynamic>)).toList(),
        muscles: ((json['muscles'] as List?) ?? const []).map((m) => Muscle.fromJson(m as Map<String, dynamic>)).toList(),
      );
}

class RoutineExercise {
  const RoutineExercise({
    required this.id,
    required this.exerciseId,
    required this.name,
    required this.muscles,
    required this.series,
    this.notes,
    this.restSeconds,
  });

  final int id;
  final int? exerciseId;
  final String name;
  final List<String> muscles;
  final List<Serie> series;
  final String? notes;

  /// Descanso entre series que pidió el profe. null = no lo definió (el cliente usa el suyo).
  final int? restSeconds;

  factory RoutineExercise.fromJson(Map<String, dynamic> json) => RoutineExercise(
        id: _int(json['routine_exercise_id']),
        exerciseId: (json['exercise_id'] as num?)?.toInt(),
        name: json['name'] as String? ?? 'Ejercicio',
        muscles: ((json['muscles'] as List?) ?? const []).map((m) => '$m').toList(),
        series: seriesFromJson(json['series']),
        notes: json['notes'] as String?,
        restSeconds: (json['rest_seconds'] as num?)?.toInt(),
      );
}

class RoutineGroup {
  const RoutineGroup({required this.id, required this.name, required this.exercises});

  final int id;
  final String name;
  final List<RoutineExercise> exercises;

  List<String> get muscles {
    final out = <String>[];
    for (final exercise in exercises) {
      for (final muscle in exercise.muscles) {
        if (!out.contains(muscle)) out.add(muscle);
      }
    }
    return out;
  }

  factory RoutineGroup.fromJson(Map<String, dynamic> json) => RoutineGroup(
        id: _int(json['routine_group_id']),
        name: json['name'] as String? ?? 'Grupo',
        exercises: ((json['exercises'] as List?) ?? const []).map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class Routine {
  const Routine({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.groups,
    this.clientId,
    this.clientName,
  });

  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final List<RoutineGroup> groups;

  final int? clientId;

  /// Solo en "Tus últimas rutinas": de quién es.
  final String? clientName;

  bool get isActive => endDate == null;
  int get exercisesCount => groups.fold(0, (n, g) => n + g.exercises.length);

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['routine_id'] as String,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: _date(json['end_date']),
        createdAt: _date(json['created_at']) ?? DateTime.now(),
        groups: ((json['groups'] as List?) ?? const []).map((g) => RoutineGroup.fromJson(g as Map<String, dynamic>)).toList(),
        clientId: (json['client_id'] as num?)?.toInt(),
        clientName: json['client_name'] as String?,
      );
}

/// Card de rutina de la ficha del cliente.
class ClientGymSummary {
  const ClientGymSummary({
    required this.hasGym,
    required this.active,
    required this.previousCount,
    required this.unseenCount,
    required this.notes,
    required this.dislikes,
    required this.weightChanges,
  });

  /// Si mostrar la card: el club tiene gimnasio o el cliente tiene rutinas.
  final bool hasGym;
  final ActiveRoutineSummary? active;
  final int previousCount;
  final int unseenCount;
  final List<({String exercise, String text, DateTime updatedAt, bool unseen})> notes;
  final List<String> dislikes;
  final List<({String exercise, double planKg, double doneKg, DateTime date})> weightChanges;

  factory ClientGymSummary.fromJson(Map<String, dynamic> json) {
    final active = json['active'] as Map<String, dynamic>?;
    final feedback = (json['feedback'] as Map<String, dynamic>?) ?? const {};
    return ClientGymSummary(
      hasGym: json['has_gym'] == true,
      active: active == null ? null : ActiveRoutineSummary.fromJson(active),
      previousCount: _int(json['previous_count']),
      unseenCount: _int(feedback['unseen_count']),
      notes: ((feedback['notes'] as List?) ?? const []).map((n) {
        final note = n as Map<String, dynamic>;
        return (
          exercise: note['exercise_name'] as String? ?? 'Ejercicio',
          text: note['text'] as String? ?? '',
          updatedAt: _date(note['updated_at']) ?? DateTime.now(),
          unseen: note['unseen'] == true,
        );
      }).toList(),
      dislikes: ((feedback['dislikes'] as List?) ?? const []).map((d) => '$d').toList(),
      weightChanges: ((feedback['weight_changes'] as List?) ?? const []).map((w) {
        final change = w as Map<String, dynamic>;
        return (
          exercise: change['exercise_name'] as String? ?? 'Ejercicio',
          planKg: (change['plan_kg'] as num?)?.toDouble() ?? 0,
          doneKg: (change['done_kg'] as num?)?.toDouble() ?? 0,
          date: _date(change['date']) ?? DateTime.now(),
        );
      }).toList(),
    );
  }
}

class ActiveRoutineSummary {
  const ActiveRoutineSummary({
    required this.routineId,
    required this.startDate,
    required this.timesTrained,
    this.lastCheckDate,
    this.lastCheckGroup,
    required this.groups,
  });

  final String routineId;
  final DateTime startDate;
  final int timesTrained;
  final DateTime? lastCheckDate;
  final String? lastCheckGroup;
  final List<({String name, int exercisesCount, DateTime? lastDoneAt})> groups;

  factory ActiveRoutineSummary.fromJson(Map<String, dynamic> json) {
    final last = json['last_check'] as Map<String, dynamic>?;
    return ActiveRoutineSummary(
      routineId: json['routine_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      timesTrained: _int(json['times_trained']),
      lastCheckDate: _date(last?['date']),
      lastCheckGroup: last?['group_name'] as String?,
      groups: ((json['groups'] as List?) ?? const []).map((g) {
        final group = g as Map<String, dynamic>;
        return (
          name: group['name'] as String? ?? 'Grupo',
          exercisesCount: _int(group['exercises_count']),
          lastDoneAt: _date(group['last_done_at']),
        );
      }).toList(),
    );
  }
}

const _monthsShort = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String _cap(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// "Sep – Oct 2026", "Ago 2026" o "Nov 2025 – Feb 2026".
String routineMonthsLabel(Routine routine) {
  final start = routine.startDate;
  final last = routine.endDate ?? DateTime.now();
  final from = _cap(_monthsShort[start.month - 1]);
  final to = _cap(_monthsShort[last.month - 1]);
  if (start.year != last.year) return '$from ${start.year} – $to ${last.year}';
  if (start.month == last.month) return '$from ${start.year}';
  return '$from – $to ${start.year}';
}

/// "1 sep 2026".
String shortDate(DateTime date, {bool year = true}) =>
    '${date.day} ${_monthsShort[date.month - 1]}${year ? ' ${date.year}' : ''}';

/// "Hoy", "Ayer", "Hace 3 días", "Hace 2 semanas".
String agoLabel(DateTime date, [DateTime? now]) {
  final today = now ?? DateTime.now();
  final days = DateTime(today.year, today.month, today.day).difference(DateTime(date.year, date.month, date.day)).inDays;
  if (days <= 0) return 'Hoy';
  if (days == 1) return 'Ayer';
  if (days < 14) return 'Hace $days días';
  return 'Hace ${days ~/ 7} semanas';
}
