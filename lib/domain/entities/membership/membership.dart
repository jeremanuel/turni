/// Abonos con cuotas (backend `/memberships`): cómo se vende cada servicio de
/// gimnasio, el estado de las cuotas de cada cliente, pausas y avisos.
library;

int _int(dynamic value) => (value as num?)?.toInt() ?? 0;
double _double(dynamic value) => (value as num?)?.toDouble() ?? double.tryParse('$value') ?? 0;

/// "2026-10-15" → fecha local sin hora.
DateTime parseDay(String value) {
  final parts = value.substring(0, 10).split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

DateTime? _day(dynamic value) => value == null ? null : parseDay('$value');

String dayToJson(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

enum BillingMode { fixedDay, anniversary }

BillingMode _billingMode(dynamic value) => value == 'ANNIVERSARY' ? BillingMode.anniversary : BillingMode.fixedDay;
String billingModeToJson(BillingMode mode) => mode == BillingMode.anniversary ? 'ANNIVERSARY' : 'FIXED_DAY';

/// Estado de un abono: al día, por vencer (o en gracia), vencido, sin primer pago, en pausa o terminado.
enum MembershipStatus { ok, soon, late, pendingFirst, paused, ended }

MembershipStatus _status(dynamic value) => switch (value) {
      'SOON' => MembershipStatus.soon,
      'LATE' => MembershipStatus.late,
      'PENDING_FIRST' => MembershipStatus.pendingFirst,
      'PAUSED' => MembershipStatus.paused,
      'ENDED' => MembershipStatus.ended,
      _ => MembershipStatus.ok,
    };

extension MembershipStatusLabel on MembershipStatus {
  String get label => switch (this) {
        MembershipStatus.ok => 'Al día',
        MembershipStatus.soon => 'Por vencer',
        MembershipStatus.late => 'Vencido',
        MembershipStatus.pendingFirst => 'Sin primer pago',
        MembershipStatus.paused => 'En pausa',
        MembershipStatus.ended => 'Terminado',
      };
}

/// Servicio con abonos con cuotas que ve el admin.
class MembershipPartition {
  const MembershipPartition({required this.id, required this.name, required this.typeName});

  final int id;
  final String name;
  final String typeName;

  factory MembershipPartition.fromJson(Map<String, dynamic> json) => MembershipPartition(
        id: _int(json['club_partition_id']),
        name: json['name'] as String? ?? 'Servicio',
        typeName: json['club_type_name'] as String? ?? '',
      );
}

/// Un abono (lo que se le vende al cliente): "3 veces por semana".
class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.partitionId,
    required this.name,
    this.daysPerWeek,
    required this.billingMode,
    required this.billingDay,
    required this.graceDays,
    required this.price,
    this.priceSince,
    this.previousPrice,
    this.archived = false,
    this.clients = 0,
    this.counts = const {},
    this.partitionName = '',
  });

  final int id;
  final int partitionId;

  /// El servicio ("Sala de musculación"); solo viene dentro de un abono de cliente.
  final String partitionName;
  final String name;

  /// null = libre.
  final int? daysPerWeek;
  final BillingMode billingMode;
  final int billingDay;
  final int graceDays;
  final double price;
  final DateTime? priceSince;
  final double? previousPrice;
  final bool archived;
  final int clients;
  final Map<MembershipStatus, int> counts;

  String get frequencyLabel => daysPerWeek == null ? 'Libre' : '$daysPerWeek ${daysPerWeek == 1 ? 'día' : 'días'} por semana';

  String get dueLabel => billingMode == BillingMode.anniversary ? 'A un mes del alta' : 'Día $billingDay de cada mes';

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    final rawCounts = (json['counts'] as Map?) ?? const {};
    return MembershipPlan(
      id: _int(json['subscription_id']),
      partitionId: _int(json['club_partition_id']),
      name: json['name'] as String? ?? 'Abono',
      daysPerWeek: (json['days_per_week'] as num?)?.toInt(),
      billingMode: _billingMode(json['billing_mode']),
      billingDay: _int(json['billing_day']),
      graceDays: _int(json['grace_days']),
      price: _double(json['price']),
      priceSince: _day(json['price_since']),
      previousPrice: json['previous_price'] == null ? null : _double(json['previous_price']),
      archived: json['archived_at'] != null,
      clients: _int(json['clients']),
      counts: {for (final entry in rawCounts.entries) _status(entry.key): _int(entry.value)},
      partitionName: json['partition_name'] as String? ?? '',
    );
  }
}

class MembershipPlansPartition {
  const MembershipPlansPartition({required this.partition, required this.clients, required this.late, required this.plans});

  final MembershipPartition partition;
  final int clients;
  final int late;
  final List<MembershipPlan> plans;

  factory MembershipPlansPartition.fromJson(Map<String, dynamic> json) => MembershipPlansPartition(
        partition: MembershipPartition.fromJson(json),
        clients: _int(json['clients']),
        late: _int(json['late']),
        plans: ((json['plans'] as List?) ?? const []).map((p) => MembershipPlan.fromJson(p as Map<String, dynamic>)).toList(),
      );
}

/// Una cuota: cubre [start, end) y vence el día que arranca.
class MembershipPeriod {
  const MembershipPeriod({
    required this.start,
    required this.end,
    required this.amount,
    this.prorated = false,
    this.paid = false,
    this.paymentDate,
    this.method,
  });

  final DateTime start;
  final DateTime end;
  final double amount;
  final bool prorated;
  final bool paid;
  final DateTime? paymentDate;
  final String? method;

  factory MembershipPeriod.fromJson(Map<String, dynamic> json) => MembershipPeriod(
        start: parseDay(json['start'] as String),
        end: parseDay(json['end'] as String),
        amount: _double(json['amount']),
        prorated: json['prorated'] == true,
        paid: json['paid'] == true,
        paymentDate: _day(json['payment_date']),
        method: json['method'] as String?,
      );
}

class MembershipPause {
  const MembershipPause({required this.id, required this.start, this.end, this.reason, this.adminName});

  final int id;
  final DateTime start;

  /// Vuelta (o vuelta prevista). null = hasta que vuelva.
  final DateTime? end;
  final String? reason;
  final String? adminName;

  factory MembershipPause.fromJson(Map<String, dynamic> json) => MembershipPause(
        id: _int(json['client_subscription_pause_id']),
        start: parseDay(json['start_date'] as String),
        end: _day(json['end_date']),
        reason: json['reason'] as String?,
        adminName: json['admin_name'] as String?,
      );
}

/// El abono de un cliente con su estado.
class Membership {
  const Membership({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.hasApp,
    required this.plan,
    required this.startDate,
    this.endDate,
    required this.status,
    this.paidUntil,
    this.nextDueDate,
    this.nextDueAmount,
    required this.debt,
    required this.unpaidCount,
    this.overdueSince,
    required this.daysOverdue,
    required this.inGrace,
    this.pause,
    this.pauses = const [],
    this.periods = const [],
    this.upcoming = const [],
    this.lastPaymentDate,
    this.lastPaymentAmount,
    this.lastPaymentMethod,
    this.lastReminderAt,
  });

  /// `client_subscription_id`.
  final int id;
  final int clientId;
  final String clientName;
  final bool hasApp;
  final MembershipPlan plan;
  final DateTime startDate;
  final DateTime? endDate;
  final MembershipStatus status;
  final DateTime? paidUntil;
  final DateTime? nextDueDate;
  final double? nextDueAmount;
  final double debt;
  final int unpaidCount;
  final DateTime? overdueSince;
  final int daysOverdue;
  final bool inGrace;
  final MembershipPause? pause;
  final List<MembershipPause> pauses;
  final List<MembershipPeriod> periods;
  final List<MembershipPeriod> upcoming;
  final DateTime? lastPaymentDate;
  final double? lastPaymentAmount;
  final String? lastPaymentMethod;
  final DateTime? lastReminderAt;

  /// Debe algo (vencido o en gracia).
  bool get owes => debt > 0;

  factory Membership.fromJson(Map<String, dynamic> json) {
    final planJson = json['plan'] as Map<String, dynamic>;
    final nextDue = json['next_due'] as Map<String, dynamic>?;
    final last = json['last_payment'] as Map<String, dynamic>?;
    final reminder = json['last_reminder'] as Map<String, dynamic>?;
    return Membership(
      id: _int(json['client_subscription_id']),
      clientId: _int(json['client_id']),
      clientName: json['client_name'] as String? ?? 'Cliente',
      hasApp: json['has_app'] == true,
      plan: MembershipPlan.fromJson(planJson),
      startDate: parseDay(json['start_date'] as String),
      endDate: _day(json['end_date']),
      status: _status(json['status']),
      paidUntil: _day(json['paid_until']),
      nextDueDate: _day(nextDue?['date']),
      nextDueAmount: nextDue == null ? null : _double(nextDue['amount']),
      debt: _double(json['debt']),
      unpaidCount: _int(json['unpaid_count']),
      overdueSince: _day(json['overdue_since']),
      daysOverdue: _int(json['days_overdue']),
      inGrace: json['in_grace'] == true,
      pause: json['pause'] == null ? null : MembershipPause.fromJson(json['pause'] as Map<String, dynamic>),
      pauses: ((json['pauses'] as List?) ?? const []).map((p) => MembershipPause.fromJson(p as Map<String, dynamic>)).toList(),
      periods: ((json['periods'] as List?) ?? const []).map((p) => MembershipPeriod.fromJson(p as Map<String, dynamic>)).toList(),
      upcoming: ((json['upcoming'] as List?) ?? const []).map((p) => MembershipPeriod.fromJson(p as Map<String, dynamic>)).toList(),
      lastPaymentDate: _day(last?['date']),
      lastPaymentAmount: last == null ? null : _double(last['amount']),
      lastPaymentMethod: last?['method'] as String?,
      lastReminderAt: reminder == null ? null : DateTime.tryParse('${reminder['sent_at']}')?.toLocal(),
    );
  }
}

class ClientMemberships {
  const ClientMemberships({required this.active, required this.previous});

  final List<Membership> active;
  final List<Membership> previous;

  factory ClientMemberships.fromJson(Map<String, dynamic> json) => ClientMemberships(
        active: ((json['active'] as List?) ?? const []).map((m) => Membership.fromJson(m as Map<String, dynamic>)).toList(),
        previous: ((json['previous'] as List?) ?? const []).map((m) => Membership.fromJson(m as Map<String, dynamic>)).toList(),
      );
}

/// Estado de cuotas de todos los abonos activos.
class MembershipBoard {
  const MembershipBoard({
    required this.counts,
    required this.lateDebt,
    required this.soonFrom,
    required this.soonTo,
    required this.collectedThisMonth,
    required this.rows,
  });

  final Map<MembershipStatus, int> counts;
  final double lateDebt;
  final DateTime soonFrom;
  final DateTime soonTo;
  final double collectedThisMonth;
  final List<Membership> rows;

  factory MembershipBoard.fromJson(Map<String, dynamic> json) => MembershipBoard(
        counts: {for (final entry in ((json['counts'] as Map?) ?? const {}).entries) _status(entry.key): _int(entry.value)},
        lateDebt: _double(json['late_debt']),
        soonFrom: parseDay(json['soon_from'] as String),
        soonTo: parseDay(json['soon_to'] as String),
        collectedThisMonth: _double(json['collected_this_month']),
        rows: ((json['rows'] as List?) ?? const []).map((m) => Membership.fromJson(m as Map<String, dynamic>)).toList(),
      );
}

class MembershipSettings {
  const MembershipSettings({required this.beforeDue, required this.dueDay, required this.overdue});

  final bool beforeDue;
  final bool dueDay;
  final bool overdue;

  MembershipSettings copyWith({bool? beforeDue, bool? dueDay, bool? overdue}) =>
      MembershipSettings(beforeDue: beforeDue ?? this.beforeDue, dueDay: dueDay ?? this.dueDay, overdue: overdue ?? this.overdue);

  factory MembershipSettings.fromJson(Map<String, dynamic> json) => MembershipSettings(
        beforeDue: json['remind_before_due'] == true,
        dueDay: json['remind_due_day'] == true,
        overdue: json['remind_overdue'] == true,
      );

  Map<String, dynamic> toJson() => {'remind_before_due': beforeDue, 'remind_due_day': dueDay, 'remind_overdue': overdue};
}

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
const _monthsLong = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
const _weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

/// "15 oct".
String dayLabel(DateTime date) => '${date.day} ${_months[date.month - 1]}';

/// "mié 21 oct".
String weekdayLabel(DateTime date) => '${_weekdays[date.weekday - 1]} ${dayLabel(date)}';

/// "Oct".
String monthShort(DateTime date) {
  final m = _months[date.month - 1];
  return m[0].toUpperCase() + m.substring(1);
}

/// "octubre".
String monthLong(DateTime date) => _monthsLong[date.month - 1];

/// Días desde [date] hasta hoy (positivo si ya pasó).
int daysSince(DateTime date, [DateTime? now]) {
  final today = now ?? DateTime.now();
  return DateTime(today.year, today.month, today.day).difference(DateTime(date.year, date.month, date.day)).inDays;
}
