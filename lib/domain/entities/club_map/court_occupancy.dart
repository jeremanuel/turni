import '../session.dart';

/// Qué pasa en una cancha en un momento dado, según los turnos del día.
class CourtOccupancy {
  /// Turno reservado (o con solicitud pendiente) que se está jugando ahora.
  final Session? current;

  /// Turno libre que está corriendo ahora: se puede reservar en el momento.
  final Session? freeNow;

  /// Próximo turno reservado que todavía no empezó.
  final Session? next;

  const CourtOccupancy({this.current, this.freeNow, this.next});

  static const empty = CourtOccupancy();

  bool get isOccupied => current != null;

  /// Turno que se abre en el gestor al tocar la cancha: el que se está
  /// jugando, si no el libre de ahora, si no el próximo.
  Session? get sessionToOpen => current ?? freeNow ?? next;
}

/// Ocupación de cada cancha (`partition_physical_id`) en [now].
///
/// Un turno ocupa la cancha desde que empieza hasta que termina (sin incluir
/// el final). Ocupado = tiene cliente ([Session.isReserved]), igual que en el
/// gestor de turnos: las solicitudes pendientes también ocupan.
Map<int, CourtOccupancy> computeCourtOccupancy(List<Session> sessions, DateTime now) {
  final byCourt = <int, List<Session>>{};
  for (final session in sessions) {
    byCourt.putIfAbsent(session.partitionPhysicalId, () => []).add(session);
  }

  return byCourt.map((courtId, courtSessions) {
    courtSessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    bool isRunning(Session s) => !s.startTime.isAfter(now) && (s.endTime as DateTime).isAfter(now);

    Session? current;
    Session? freeNow;
    Session? next;
    for (final session in courtSessions) {
      if (isRunning(session)) {
        if (session.isReserved) {
          current ??= session;
        } else {
          freeNow ??= session;
        }
      } else if (session.startTime.isAfter(now) && session.isReserved) {
        next ??= session;
      }
    }

    return MapEntry(courtId, CourtOccupancy(current: current, freeNow: current == null ? freeNow : null, next: next));
  });
}
