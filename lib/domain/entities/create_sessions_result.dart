/// Resultado de una operación de carga masiva de turnos.
class CreateSessionsResult {
  final int createdCount;
  final List<SkippedSession> skipped;

  const CreateSessionsResult({
    required this.createdCount,
    required this.skipped,
  });

  factory CreateSessionsResult.fromJson(Map<String, dynamic> json) {
    return CreateSessionsResult(
      createdCount: (json['created_count'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as List<dynamic>?)
              ?.map((e) => SkippedSession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get hasSkipped => skipped.isNotEmpty;
}

/// Motivo por el que un turno fue descartado en la carga masiva.
enum SkipReason {
  overlap('OVERLAP', 'Superposición con turno existente');

  const SkipReason(this.backendKey, this.label);

  final String backendKey;
  final String label;

  static SkipReason fromString(String value) {
    return SkipReason.values.firstWhere(
      (e) => e.backendKey == value,
      orElse: () => SkipReason.overlap,
    );
  }
}

/// Slot de tiempo que fue descartado durante la carga masiva.
class SkippedSession {
  final int partitionPhysicalId;
  final DateTime startTime;
  final int duration;
  final SkipReason reason;
  final List<int> conflictingSessionIds;

  const SkippedSession({
    required this.partitionPhysicalId,
    required this.startTime,
    required this.duration,
    required this.reason,
    required this.conflictingSessionIds,
  });

  factory SkippedSession.fromJson(Map<String, dynamic> json) {
    return SkippedSession(
      partitionPhysicalId: (json['partition_physical_id'] as num).toInt(),
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      duration: (json['duration'] as num?)?.toInt() ?? 60,
      reason: SkipReason.fromString(json['reason'] as String? ?? ''),
      conflictingSessionIds: (json['conflicting_session_ids'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
    );
  }

  /// Formatea el rango del turno para mostrar en UI.
  String get timeRangeLabel {
    final end = startTime.add(Duration(minutes: duration));
    final sh = startTime.hour.toString().padLeft(2, '0');
    final sm = startTime.minute.toString().padLeft(2, '0');
    final eh = end.hour.toString().padLeft(2, '0');
    final em = end.minute.toString().padLeft(2, '0');
    return '$sh:$sm – $eh:$em';
  }
}
