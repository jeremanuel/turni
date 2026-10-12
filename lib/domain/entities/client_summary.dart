/// Resumen de la ficha del cliente (`GET /admin/clients/:id/summary`):
/// indicadores de los últimos 90 días, próximos turnos y actividad.
class ClientSummary {
  const ClientSummary({
    required this.sessionsLast90Days,
    required this.fixedSessionsLast90Days,
    required this.cancelledDaysLast90Days,
    required this.pendingBalance,
    required this.unpaidSessions,
    this.lastPayment,
    this.upcoming = const [],
    this.activity = const [],
  });

  final int sessionsLast90Days;
  final int fixedSessionsLast90Days;
  final int cancelledDaysLast90Days;
  final double pendingBalance;
  final int unpaidSessions;
  final ClientLastPayment? lastPayment;
  final List<ClientUpcomingSession> upcoming;
  final List<ClientActivity> activity;

  static double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

  factory ClientSummary.fromJson(Map<String, dynamic> json) => ClientSummary(
        sessionsLast90Days: (json['sessions_last_90_days'] as num?)?.toInt() ?? 0,
        fixedSessionsLast90Days: (json['fixed_sessions_last_90_days'] as num?)?.toInt() ?? 0,
        cancelledDaysLast90Days: (json['cancelled_days_last_90_days'] as num?)?.toInt() ?? 0,
        pendingBalance: _num(json['pending_balance']),
        unpaidSessions: (json['unpaid_sessions'] as num?)?.toInt() ?? 0,
        lastPayment: json['last_payment'] == null
            ? null
            : ClientLastPayment(
                date: DateTime.parse(json['last_payment']['date'] as String).toLocal(),
                amount: _num(json['last_payment']['amount']),
                method: json['last_payment']['method'] as String?,
              ),
        upcoming: ((json['upcoming'] as List?) ?? const [])
            .map((u) => ClientUpcomingSession.fromJson(u as Map<String, dynamic>))
            .toList(),
        activity: ((json['activity'] as List?) ?? const [])
            .map((a) => ClientActivity(
                  kind: (a as Map)['kind'] as String,
                  at: DateTime.parse(a['at'] as String).toLocal(),
                  text: a['text'] as String,
                ))
            .toList(),
      );
}

class ClientLastPayment {
  const ClientLastPayment({required this.date, required this.amount, this.method});

  final DateTime date;
  final double amount;
  final String? method;
}

class ClientUpcomingSession {
  const ClientUpcomingSession({
    required this.sessionId,
    required this.startTime,
    required this.duration,
    this.sport,
    required this.courtName,
    this.status,
    required this.isFixed,
    required this.isOwner,
    this.ownerClientId,
    this.ownerName,
    required this.membersCount,
    required this.price,
    required this.paid,
  });

  final int sessionId;
  final DateTime startTime;
  final int duration;
  final String? sport;
  final String courtName;
  final String? status;
  final bool isFixed;
  final bool isOwner;
  final int? ownerClientId;
  final String? ownerName;
  final int membersCount;
  final double price;
  final double paid;

  bool get isPending => status == 'PENDING';
  double get due => price - paid;

  factory ClientUpcomingSession.fromJson(Map<String, dynamic> json) => ClientUpcomingSession(
        sessionId: (json['session_id'] as num).toInt(),
        startTime: DateTime.parse(json['start_time'] as String).toLocal(),
        duration: (json['duration'] as num?)?.toInt() ?? 60,
        sport: json['sport'] as String?,
        courtName: json['court_name'] as String? ?? 'Cancha',
        status: json['status'] as String?,
        isFixed: json['is_fixed'] as bool? ?? false,
        isOwner: json['is_owner'] as bool? ?? true,
        ownerClientId: (json['owner_client_id'] as num?)?.toInt(),
        ownerName: json['owner_name'] as String?,
        membersCount: (json['members_count'] as num?)?.toInt() ?? 1,
        price: ClientSummary._num(json['price']),
        paid: ClientSummary._num(json['paid']),
      );
}

/// PAYMENT | FIXED_CREATED | FIXED_DAY_CANCELLED | FIXED_ENDED.
class ClientActivity {
  const ClientActivity({required this.kind, required this.at, required this.text});

  final String kind;
  final DateTime at;
  final String text;
}
