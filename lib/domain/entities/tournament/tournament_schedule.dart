/// Programación automática de un torneo (`/admin/tournament/:id/schedule`).
///
/// Los partidos se identifican por `key`: `m<match_id>`, o `k<ronda>-<posición>`
/// para los lugares de la llave de "grupos + eliminación" antes de que se arme.
library;

DateTime _date(dynamic v) => DateTime.parse(v as String).toLocal();

List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) parse) =>
    raw is List ? raw.map((e) => parse(e as Map<String, dynamic>)).toList() : <T>[];

enum SchedulePhase {
  group,
  knockout;

  static SchedulePhase parse(dynamic v) => v == 'KNOCKOUT' ? knockout : group;

  String get code => this == knockout ? 'KNOCKOUT' : 'GROUP';
}

/// Días y horarios de una fase.
class ScheduleWindow {
  final SchedulePhase phase;
  final DateTime start;
  final DateTime end;

  const ScheduleWindow({required this.phase, required this.start, required this.end});

  factory ScheduleWindow.fromJson(Map<String, dynamic> json) => ScheduleWindow(
        phase: SchedulePhase.parse(json['stage']),
        start: _date(json['starts_at']),
        end: _date(json['ends_at']),
      );

  Map<String, dynamic> toJson() => {
        'stage': phase.code,
        'starts_at': start.toUtc().toIso8601String(),
        'ends_at': end.toUtc().toIso8601String(),
      };
}

class ScheduleCourt {
  final int id;
  final String name;

  const ScheduleCourt({required this.id, required this.name});

  factory ScheduleCourt.fromJson(Map<String, dynamic> json) =>
      ScheduleCourt(id: json['partition_physical_id'] as int, name: json['name'] as String);
}

class ScheduleConfig {
  final List<ScheduleWindow> windows;
  final int restMinutes;
  /// Null = sin límite.
  final int? maxMatchesPerDay;
  final int matchDurationMinutes;
  final List<ScheduleCourt> courts;

  const ScheduleConfig({
    required this.windows,
    required this.restMinutes,
    required this.maxMatchesPerDay,
    required this.matchDurationMinutes,
    required this.courts,
  });

  factory ScheduleConfig.fromJson(Map<String, dynamic> json) => ScheduleConfig(
        windows: _list(json['windows'], ScheduleWindow.fromJson),
        restMinutes: json['rest_minutes'] as int,
        maxMatchesPerDay: json['max_matches_per_day'] as int?,
        matchDurationMinutes: json['match_duration_minutes'] as int,
        courts: _list(json['courts'], ScheduleCourt.fromJson),
      );
}

/// Partido a programar: "Zona A · Fecha 1", "Cuartos 2", "Final".
class ScheduleMatch {
  final String key;
  final int? matchId;
  final SchedulePhase phase;
  final int round;
  final String title;
  final String teamA;
  final String teamB;
  /// Los dos equipos ya están definidos.
  final bool defined;

  const ScheduleMatch({
    required this.key,
    required this.matchId,
    required this.phase,
    required this.round,
    required this.title,
    required this.teamA,
    required this.teamB,
    required this.defined,
  });

  factory ScheduleMatch.fromJson(Map<String, dynamic> json) => ScheduleMatch(
        key: json['key'] as String,
        matchId: json['match_id'] as int?,
        phase: SchedulePhase.parse(json['phase']),
        round: json['round'] as int,
        title: json['title'] as String,
        teamA: json['team_a'] as String,
        teamB: json['team_b'] as String,
        defined: json['defined'] as bool? ?? false,
      );
}

/// Un horario de una cancha dentro de las ventanas de juego.
class ScheduleSlot {
  final int courtId;
  final DateTime start;
  final DateTime end;
  final Set<SchedulePhase> phases;
  /// Lo que ocupa la cancha (turno reservado, otro torneo), o null.
  final String? busy;

  const ScheduleSlot({required this.courtId, required this.start, required this.end, required this.phases, this.busy});

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => ScheduleSlot(
        courtId: json['partition_physical_id'] as int,
        start: _date(json['start_time']),
        end: _date(json['end_time']),
        phases: {for (final p in (json['phases'] as List? ?? const [])) SchedulePhase.parse(p)},
        busy: json['busy'] as String?,
      );
}

class SchedulePlacement {
  final String key;
  final int courtId;
  final DateTime start;

  const SchedulePlacement({required this.key, required this.courtId, required this.start});

  factory SchedulePlacement.fromJson(Map<String, dynamic> json) => SchedulePlacement(
        key: json['key'] as String,
        courtId: json['partition_physical_id'] as int,
        start: _date(json['start_time']),
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'partition_physical_id': courtId,
        'start_time': start.toUtc().toIso8601String(),
      };
}

/// Partido con reglas rotas (WARN) o en un lugar imposible (BLOCKED).
class ScheduleIssue {
  final String key;
  final List<String> reasons;

  const ScheduleIssue({required this.key, required this.reasons});

  factory ScheduleIssue.fromJson(Map<String, dynamic> json) =>
      ScheduleIssue(key: json['key'] as String, reasons: [for (final r in json['reasons'] as List) r as String]);
}

enum OptionLevel {
  ok,
  warn,
  blocked;

  static OptionLevel parse(dynamic v) => switch (v) {
        'OK' => ok,
        'WARN' => warn,
        _ => blocked,
      };
}

/// Cómo queda un lugar libre para el partido que se está moviendo.
class ScheduleOption {
  final int courtId;
  final DateTime start;
  final OptionLevel level;
  final List<String> reasons;

  const ScheduleOption({required this.courtId, required this.start, required this.level, required this.reasons});

  factory ScheduleOption.fromJson(Map<String, dynamic> json) => ScheduleOption(
        courtId: json['partition_physical_id'] as int,
        start: _date(json['start_time']),
        level: OptionLevel.parse(json['level']),
        reasons: [for (final r in json['reasons'] as List? ?? const []) r as String],
      );
}

class TournamentSchedule {
  final DateTime? confirmedAt;
  final ScheduleConfig config;
  final List<ScheduleMatch> matches;
  final List<ScheduleSlot> slots;
  final List<SchedulePlacement> placements;
  /// Sin lugar: key → motivo (null si no hay uno, por ejemplo si lo sacó el club).
  final Map<String, String?> unplaced;
  final List<ScheduleIssue> warnings;
  final List<ScheduleIssue> blocked;
  final List<ScheduleOption>? options;
  final int maxParallel;
  final DateTime? endsAt;

  const TournamentSchedule({
    required this.confirmedAt,
    required this.config,
    required this.matches,
    required this.slots,
    required this.placements,
    required this.unplaced,
    required this.warnings,
    required this.blocked,
    required this.options,
    required this.maxParallel,
    required this.endsAt,
  });

  factory TournamentSchedule.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    return TournamentSchedule(
      confirmedAt: json['schedule_confirmed_at'] == null ? null : _date(json['schedule_confirmed_at']),
      config: ScheduleConfig.fromJson(json['config'] as Map<String, dynamic>),
      matches: _list(json['matches'], ScheduleMatch.fromJson),
      slots: _list(json['slots'], ScheduleSlot.fromJson),
      placements: _list(json['placements'], SchedulePlacement.fromJson),
      unplaced: {
        for (final u in json['unplaced'] as List) (u as Map<String, dynamic>)['key'] as String: u['reason'] as String?,
      },
      warnings: _list(json['warnings'], ScheduleIssue.fromJson),
      blocked: _list(json['blocked'], ScheduleIssue.fromJson),
      options: json['options'] == null ? null : _list(json['options'], ScheduleOption.fromJson),
      maxParallel: summary['max_parallel'] as int? ?? 0,
      endsAt: summary['ends_at'] == null ? null : _date(summary['ends_at']),
    );
  }
}

/// Lo que se manda para generar, revalidar o confirmar.
class ScheduleRequest {
  final List<ScheduleWindow> windows;
  final int restMinutes;
  final int? maxMatchesPerDay;
  /// Null = repartir de cero.
  final List<SchedulePlacement>? placements;
  final String? focusKey;
  final bool acceptWarnings;

  const ScheduleRequest({
    required this.windows,
    required this.restMinutes,
    required this.maxMatchesPerDay,
    this.placements,
    this.focusKey,
    this.acceptWarnings = false,
  });

  Map<String, dynamic> toJson() => {
        'windows': [for (final w in windows) w.toJson()],
        'rest_minutes': restMinutes,
        'max_matches_per_day': maxMatchesPerDay,
        if (placements != null) 'placements': [for (final p in placements!) p.toJson()],
        if (focusKey != null) 'focus_key': focusKey,
        if (acceptWarnings) 'accept_warnings': true,
      };
}
