import 'package:json_annotation/json_annotation.dart';

part 'fixed_session.g.dart';

/// Días de la semana con la convención del backend (0 = domingo … 6 = sábado).
const fixedSessionDayNames = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

/// Orden de lunes a domingo para mostrar y elegir días.
const fixedSessionWeekOrder = [1, 2, 3, 4, 5, 6, 0];

/// Lo mínimo de un turno fijo para cancelar un día o mostrarlo: lo usan la
/// lista de turnos fijos y el panel del turno en la agenda.
class FixedSessionRef {
  const FixedSessionRef({required this.id, required this.dayOfWeek, required this.startTime, required this.clientName});

  final int id;
  final int dayOfWeek;
  final String startTime;
  final String clientName;

  String get dayName => fixedSessionDayNames[dayOfWeek];
}

/// Turno libre que quedó porque se canceló ese día de un turno fijo.
@JsonSerializable()
class SessionCancelledFixed {
  SessionCancelledFixed({required this.id, this.clientId, required this.clientName});

  @JsonKey(name: "client_subscription_id")
  final int id;
  @JsonKey(name: "client_id")
  final int? clientId;
  @JsonKey(name: "client_name")
  final String clientName;

  factory SessionCancelledFixed.fromJson(Map<String, dynamic> json) => _$SessionCancelledFixedFromJson(json);
  Map<String, dynamic> toJson() => _$SessionCancelledFixedToJson(this);
}

/// `fixed_session` de un turno de la agenda.
@JsonSerializable()
class SessionFixedInfo {
  SessionFixedInfo({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    this.ownerClientId,
    this.ownerName,
    this.participants = const [],
    this.nextDates = const [],
    this.cancelledDates = const [],
  });

  @JsonKey(name: "client_subscription_id")
  final int id;
  @JsonKey(name: "day_of_week")
  final int dayOfWeek;
  @JsonKey(name: "start_time")
  final String startTime;
  @JsonKey(name: "owner_client_id")
  final int? ownerClientId;
  @JsonKey(name: "owner_name")
  final String? ownerName;
  final List<SessionFixedMember> participants;

  /// Próximos turnos generados después de este (hasta 3).
  @JsonKey(name: "next_dates")
  final List<DateTime> nextDates;

  /// Días cancelados de acá en adelante ("YYYY-MM-DD").
  @JsonKey(name: "cancelled_dates")
  final List<String> cancelledDates;

  String get dayName => fixedSessionDayNames[dayOfWeek];

  factory SessionFixedInfo.fromJson(Map<String, dynamic> json) => _$SessionFixedInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SessionFixedInfoToJson(this);
}

/// Integrante de un turno fijo, tal como viene en el `fixed_session` de la agenda.
@JsonSerializable()
class SessionFixedMember {
  SessionFixedMember({this.clientId, required this.fullName});

  @JsonKey(name: "client_id")
  final int? clientId;
  @JsonKey(name: "full_name")
  final String fullName;

  factory SessionFixedMember.fromJson(Map<String, dynamic> json) => _$SessionFixedMemberFromJson(json);
  Map<String, dynamic> toJson() => _$SessionFixedMemberToJson(this);
}

@JsonSerializable()
class FixedSessionPerson {
  FixedSessionPerson({required this.clientId, required this.name, this.lastName = ''});

  @JsonKey(name: "client_id")
  final int clientId;
  final String name;
  @JsonKey(name: "last_name")
  final String lastName;

  String get fullName => [name, lastName].where((p) => p.trim().isNotEmpty).join(' ');

  factory FixedSessionPerson.fromJson(Map<String, dynamic> json) => _$FixedSessionPersonFromJson(json);
  Map<String, dynamic> toJson() => _$FixedSessionPersonToJson(this);
}

@JsonSerializable()
class FixedSessionUpcoming {
  FixedSessionUpcoming({required this.sessionId, required this.startTime});

  @JsonKey(name: "session_id")
  final int sessionId;
  @JsonKey(name: "start_time")
  final DateTime startTime;

  factory FixedSessionUpcoming.fromJson(Map<String, dynamic> json) => _$FixedSessionUpcomingFromJson(json);
  Map<String, dynamic> toJson() => _$FixedSessionUpcomingToJson(this);
}

/// Turno fijo (`GET /admin/fixed-sessions`): el titular y sus integrantes
/// tienen reservado todas las semanas el mismo día, hora y cancha.
@JsonSerializable()
class FixedSession {
  FixedSession({
    required this.id,
    required this.client,
    this.participants = const [],
    required this.partitionPhysicalId,
    required this.courtName,
    required this.clubPartitionId,
    this.sport,
    this.clubName,
    required this.dayOfWeek,
    required this.startTime,
    required this.duration,
    required this.startDate,
    this.endDate,
    this.active = true,
    this.cancelledDates = const [],
    this.upcoming = const [],
    this.missingDates = const [],
  });

  @JsonKey(name: "client_subscription_id")
  final int id;
  final FixedSessionPerson client;
  final List<FixedSessionPerson> participants;
  @JsonKey(name: "partition_physical_id")
  final int partitionPhysicalId;
  @JsonKey(name: "court_name")
  final String courtName;
  @JsonKey(name: "club_partition_id")
  final int clubPartitionId;
  final String? sport;
  @JsonKey(name: "club_name")
  final String? clubName;

  /// 0 = domingo … 6 = sábado.
  @JsonKey(name: "day_of_week")
  final int dayOfWeek;

  /// "HH:mm", hora del club.
  @JsonKey(name: "start_time")
  final String startTime;
  final int duration;
  @JsonKey(name: "start_date")
  final String startDate;
  @JsonKey(name: "end_date")
  final String? endDate;
  final bool active;
  @JsonKey(name: "cancelled_dates")
  final List<String> cancelledDates;
  final List<FixedSessionUpcoming> upcoming;

  /// Días ya generados en los que no tiene turno (el horario estaba ocupado).
  @JsonKey(name: "missing_dates")
  final List<String> missingDates;

  String get dayName => fixedSessionDayNames[dayOfWeek];

  bool get hasConflicts => missingDates.isNotEmpty;

  /// "Martes 15:00 · 90 min".
  String get scheduleLabel => '$dayName $startTime · $duration min';

  /// Titular e integrantes.
  List<FixedSessionPerson> get members => [client, ...participants];

  FixedSessionRef get ref => FixedSessionRef(id: id, dayOfWeek: dayOfWeek, startTime: startTime, clientName: client.fullName);

  factory FixedSession.fromJson(Map<String, dynamic> json) => _$FixedSessionFromJson(json);
  Map<String, dynamic> toJson() => _$FixedSessionToJson(this);
}

/// Un día de la vista previa: qué pasaría con ese turno al cargar el fijo.
enum FixedSessionOccurrenceStatus {
  /// Se crea un turno nuevo.
  @JsonValue('NEW')
  created,

  /// Se usa el turno libre que ya había en ese horario.
  @JsonValue('FREE_SESSION')
  freeSession,
  @JsonValue('BOOKED')
  booked,
  @JsonValue('PENDING')
  pending,
  @JsonValue('PAID')
  paid,
  @JsonValue('OCCUPIED')
  occupied;

  bool get isConflict => this != created && this != freeSession;
}

@JsonSerializable()
class FixedSessionOccurrence {
  FixedSessionOccurrence({required this.date, required this.status, this.clientName, this.price});

  final String date;

  /// Precio según la tarifa de la cancha (solo en la vista previa).
  final double? price;
  @JsonKey(unknownEnumValue: FixedSessionOccurrenceStatus.occupied)
  final FixedSessionOccurrenceStatus status;
  @JsonKey(name: "client_name")
  final String? clientName;

  factory FixedSessionOccurrence.fromJson(Map<String, dynamic> json) => _$FixedSessionOccurrenceFromJson(json);
  Map<String, dynamic> toJson() => _$FixedSessionOccurrenceToJson(this);
}

/// Datos para cargar un turno fijo.
class FixedSessionDraft {
  FixedSessionDraft({
    required this.clientId,
    this.participantIds = const [],
    required this.partitionPhysicalId,
    required this.dayOfWeek,
    required this.startTime,
    required this.duration,
    this.startDate,
  });

  final int clientId;
  final List<int> participantIds;
  final int partitionPhysicalId;
  final int dayOfWeek;
  final String startTime;
  final int duration;
  final String? startDate;

  Map<String, dynamic> toJson() => {
        'client_id': clientId,
        'participant_ids': participantIds,
        'partition_physical_id': partitionPhysicalId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'duration': duration,
        if (startDate != null) 'start_date': startDate,
      };
}

/// Resultado de cargar un turno fijo: los días que no se pudieron ocupar.
class FixedSessionCreated {
  FixedSessionCreated({required this.fixedSession, required this.created, required this.assigned, required this.conflicts});

  final FixedSession fixedSession;
  final int created;
  final int assigned;
  final List<FixedSessionOccurrence> conflicts;

  factory FixedSessionCreated.fromJson(Map<String, dynamic> json) {
    final generation = json['generation'] as Map<String, dynamic>? ?? const {};
    return FixedSessionCreated(
      fixedSession: FixedSession.fromJson(json['fixed_session'] as Map<String, dynamic>),
      created: (generation['created'] as num?)?.toInt() ?? 0,
      assigned: (generation['assigned'] as num?)?.toInt() ?? 0,
      conflicts: ((generation['conflicts'] as List?) ?? const [])
          .map((c) => FixedSessionOccurrence.fromJson({
                'date': (c as Map)['date'],
                'status': c['reason'],
                'client_name': c['client_name'],
              }))
          .toList(),
    );
  }
}
