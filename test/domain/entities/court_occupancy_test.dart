import 'package:flutter_test/flutter_test.dart';

import 'package:turni/domain/entities/club_map/court_occupancy.dart';
import 'package:turni/domain/entities/session.dart';
import 'package:turni/domain/entities/session_status.dart';

Session _session(int id, int courtId, DateTime start, {int duration = 60, int? clientId, SessionStatus? status}) => Session(
      sessionId: id,
      createdAt: DateTime(2026, 10, 5),
      startTime: start,
      duration: duration,
      price: 1000,
      partitionPhysicalId: courtId,
      clientId: clientId,
      status: status,
    );

void main() {
  final now = DateTime(2026, 10, 5, 19, 30);

  test('turno reservado en curso: ocupada, y el próximo es el siguiente reservado', () {
    final occupancy = computeCourtOccupancy([
      _session(1, 31, DateTime(2026, 10, 5, 19), clientId: 7),
      _session(2, 31, DateTime(2026, 10, 5, 20), duration: 60),
      _session(3, 31, DateTime(2026, 10, 5, 21), clientId: 8),
    ], now);

    final court = occupancy[31]!;
    expect(court.isOccupied, isTrue);
    expect(court.current!.sessionId, 1);
    expect(court.freeNow, isNull);
    // El turno de las 20 está libre: no cuenta como próximo.
    expect(court.next!.sessionId, 3);
    expect(court.sessionToOpen!.sessionId, 1);
  });

  test('turno libre en curso: libre y se puede reservar ahora', () {
    final court = computeCourtOccupancy([
      _session(1, 31, DateTime(2026, 10, 5, 19)),
      _session(2, 31, DateTime(2026, 10, 5, 22), clientId: 7),
    ], now)[31]!;

    expect(court.isOccupied, isFalse);
    expect(court.freeNow!.sessionId, 1);
    expect(court.next!.sessionId, 2);
    expect(court.sessionToOpen!.sessionId, 1);
  });

  test('el final del turno no ocupa: a las 19:30 un turno de 18:30 a 19:30 ya terminó', () {
    final court = computeCourtOccupancy([
      _session(1, 31, DateTime(2026, 10, 5, 18, 30), clientId: 7),
    ], now)[31]!;

    expect(court.isOccupied, isFalse);
    expect(court.next, isNull);
    expect(court.sessionToOpen, isNull);
  });

  test('una solicitud pendiente también ocupa la cancha', () {
    final court = computeCourtOccupancy([
      _session(1, 31, DateTime(2026, 10, 5, 19), clientId: 7, status: SessionStatus.pending),
    ], now)[31]!;

    expect(court.isOccupied, isTrue);
    expect(court.current!.isPending, isTrue);
  });

  test('cada cancha por separado, y los turnos desordenados', () {
    final occupancy = computeCourtOccupancy([
      _session(3, 32, DateTime(2026, 10, 5, 23), clientId: 9),
      _session(2, 32, DateTime(2026, 10, 5, 21), clientId: 8),
      _session(1, 31, DateTime(2026, 10, 5, 19, 15), clientId: 7),
    ], now);

    expect(occupancy[31]!.isOccupied, isTrue);
    expect(occupancy[32]!.isOccupied, isFalse);
    expect(occupancy[32]!.next!.sessionId, 2);
    expect(occupancy.containsKey(33), isFalse);
  });
}
