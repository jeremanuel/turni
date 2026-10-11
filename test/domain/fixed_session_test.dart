import 'package:flutter_test/flutter_test.dart';
import 'package:turni/domain/entities/bulk_sessions.dart';
import 'package:turni/domain/entities/fixed_session.dart';

void main() {
  test('FixedSession.fromJson con integrantes, días cancelados y próximos turnos', () {
    final fixed = FixedSession.fromJson({
      'client_subscription_id': 7,
      'client': {'client_id': 1, 'name': 'Jeremías', 'last_name': 'P.'},
      'participants': [
        {'client_id': 3, 'name': 'Mailen', 'last_name': 'F.'},
      ],
      'partition_physical_id': 10,
      'court_name': 'Cancha 2',
      'club_partition_id': 4,
      'sport': 'Pádel',
      'club_name': 'Club Central',
      'day_of_week': 2,
      'start_time': '15:00',
      'duration': 90,
      'start_date': '2026-10-06',
      'end_date': null,
      'generated_until': '2026-11-30',
      'active': true,
      'cancelled_dates': ['2026-10-20'],
      'upcoming': [
        {'session_id': 50, 'start_time': '2026-10-13T18:00:00.000Z'},
      ],
    });

    expect(fixed.dayName, 'Martes');
    expect(fixed.scheduleLabel, 'Martes 15:00 · 90 min');
    expect(fixed.members.map((m) => m.fullName), ['Jeremías P.', 'Mailen F.']);
    expect(fixed.cancelledDates, ['2026-10-20']);
    expect(fixed.ref.clientName, 'Jeremías P.');
  });

  test('El resultado del alta trae los días que no se pudieron ocupar', () {
    final created = FixedSessionCreated.fromJson({
      'fixed_session': {
        'client_subscription_id': 7,
        'client': {'client_id': 1, 'name': 'Ana', 'last_name': ''},
        'partition_physical_id': 10,
        'court_name': 'Cancha 1',
        'club_partition_id': 4,
        'day_of_week': 0,
        'start_time': '10:00',
        'duration': 60,
        'start_date': '2026-10-11',
      },
      'generation': {
        'created': 6,
        'assigned': 1,
        'conflicts': [
          {'date': '2026-10-18', 'reason': 'BOOKED', 'client_name': 'Luis'},
        ],
      },
    });
    expect(created.fixedSession.dayName, 'Domingo');
    expect(created.created + created.assigned, 7);
    expect(created.conflicts.single.status, FixedSessionOccurrenceStatus.booked);
    expect(created.conflicts.single.clientName, 'Luis');
  });

  test('La gestión masiva cuenta los turnos fijos como excluidos', () {
    final excluded = BulkExcluded.fromJson({'fixed': 2, 'booked': 1, 'unchanged': 3});
    expect(excluded.protectedTotal, 3);
    expect(excluded.total, 6);
    expect(BulkRowResult.fromWire('fixed'), BulkRowResult.fixed);
  });
}
