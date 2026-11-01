import 'package:flutter_test/flutter_test.dart';
import 'package:turni/domain/entities/membership/membership.dart';
import 'package:turni/presentation/admin/memberships/widgets/membership_widgets.dart';

Map<String, dynamic> _membership({String status = 'LATE', List<Map<String, dynamic>> pauses = const []}) => {
      'client_subscription_id': 7,
      'client_id': 15,
      'client_name': 'Mai Vera',
      'has_app': true,
      'plan': {
        'subscription_id': 3, 'name': '3 veces por semana', 'partition_name': 'Gimnasio', 'club_partition_id': 800007,
        'days_per_week': 3, 'billing_mode': 'ANNIVERSARY', 'billing_day': 10, 'grace_days': 5, 'price': 36000,
      },
      'start_date': '2026-03-23',
      'end_date': null,
      'status': status,
      'paid_until': '2026-09-23',
      'next_due': {'date': '2026-09-23', 'amount': 32000},
      'debt': 32000,
      'unpaid_count': 1,
      'overdue_since': '2026-09-23',
      'days_overdue': 28,
      'in_grace': false,
      'pause': null,
      'pauses': pauses,
      'periods': [
        {'start': '2026-07-23', 'end': '2026-08-23', 'amount': 32000, 'prorated': false, 'paid': true, 'payment_date': '2026-07-23', 'method': 'Efectivo'},
        {'start': '2026-08-23', 'end': '2026-09-23', 'amount': 32000, 'prorated': false, 'paid': true, 'payment_date': '2026-08-24', 'method': 'Mercado Pago'},
        {'start': '2026-09-23', 'end': '2026-10-23', 'amount': 32000, 'prorated': false, 'paid': false, 'payment_date': null, 'method': null},
      ],
      'upcoming': [
        {'start': '2026-09-23', 'end': '2026-10-23', 'amount': 32000, 'prorated': false},
        {'start': '2026-10-23', 'end': '2026-11-23', 'amount': 36000, 'prorated': false},
      ],
      'last_payment': {'date': '2026-08-24', 'amount': 36000, 'method': 'Mercado Pago'},
      'last_reminder': null,
    };

void main() {
  test('lee el abono de un cliente', () {
    final m = Membership.fromJson(_membership());
    expect(m.status, MembershipStatus.late);
    expect(m.plan.partitionName, 'Gimnasio');
    expect(m.plan.frequencyLabel, '3 días por semana');
    expect(m.plan.dueLabel, 'A un mes del alta');
    expect(m.upcoming.fold<double>(0, (s, p) => s + p.amount), 68000);
    expect(m.owes, isTrue);
  });

  test('la tira de cuotas marca la vencida y mete las pausas en orden', () {
    final m = Membership.fromJson(_membership(pauses: [
      {'client_subscription_pause_id': 1, 'start_date': '2026-08-01', 'end_date': '2026-08-10', 'reason': 'Lesión'},
    ]));
    final strip = membershipStrip(m, count: 7);
    expect(strip.map((s) => s.state).toList(), ['Pagada', 'Pausa', 'Pagada', 'Vencida']);
    expect(strip.last.detail, 'Debe \$ 32.000');
  });

  test('estado de cuotas', () {
    final board = MembershipBoard.fromJson({
      'counts': {'OK': 1, 'SOON': 1, 'LATE': 1, 'PENDING_FIRST': 1, 'PAUSED': 1},
      'late_debt': 32000,
      'soon_from': '2026-10-22',
      'soon_to': '2026-10-28',
      'collected_this_month': 36000,
      'rows': [_membership()],
    });
    expect(board.counts[MembershipStatus.paused], 1);
    expect(board.rows.single.clientName, 'Mai Vera');
  });
}
