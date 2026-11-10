import '../../../core/utils/value_transformers.dart';

double _money(dynamic value) => value == null ? 0 : ValueTransformers.fromJsonDouble(value);
double? _moneyOrNull(dynamic value) => value == null ? null : ValueTransformers.fromJsonDouble(value);
DateTime? _dateOrNull(dynamic value) => ValueTransformers.fromJsonDateTimeLocaleNullable(value);
List<Map<String, dynamic>> _list(dynamic value) => (value as List? ?? const []).cast<Map<String, dynamic>>();

/// Cómo usa la caja el establecimiento.
class CashSettings {
  const CashSettings({required this.enabled, required this.requireOpenForCash, required this.blindClose, required this.tolerance});

  final bool enabled;

  /// El efectivo no se cobra sin una caja abierta.
  final bool requireOpenForCash;

  /// Quien cierra cuenta sin ver cuánto se esperaba.
  final bool blindClose;

  /// Diferencia de cierre que se acepta sin pedir explicación.
  final double tolerance;

  factory CashSettings.fromJson(Map<String, dynamic> json) => CashSettings(
        enabled: json['enabled'] == true,
        requireOpenForCash: json['require_open_for_cash'] == true,
        blindClose: json['blind_close'] == true,
        tolerance: _money(json['tolerance']),
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'require_open_for_cash': requireOpenForCash,
        'blind_close': blindClose,
        'tolerance': tolerance,
      };
}

class CashSpace {
  const CashSpace({required this.partitionPhysicalId, required this.name});

  final int partitionPhysicalId;
  final String name;

  factory CashSpace.fromJson(Map<String, dynamic> json) =>
      CashSpace(partitionPhysicalId: json['partition_physical_id'] as int, name: json['name']?.toString() ?? '');
}

/// La plata de una caja por tipo de movimiento (los egresos vienen negativos).
class CashTotals {
  const CashTotals(this._byKind);

  final Map<String, double> _byKind;

  double of(String kind) => _byKind[kind] ?? 0;

  /// Cobros menos anulaciones, devoluciones y contracargos.
  double get collected => of('SALE') + of('REVERSAL') + of('REFUND') + of('CHARGEBACK');
  double get expenses => of('EXPENSE');
  double get withdrawals => of('WITHDRAWAL');
  double get deposits => of('DEPOSIT');
  double get adjustments => of('ADJUSTMENT');

  static CashTotals? fromJson(dynamic json) {
    if (json is! Map) return null;
    return CashTotals({for (final entry in json.entries) '${entry.key}': _money(entry.value)});
  }
}

class CashOpenShift {
  const CashOpenShift({
    required this.id,
    required this.openedAt,
    required this.openedByName,
    required this.openingAmount,
    required this.expectedAmount,
    required this.totals,
  });

  /// Va como texto: es un BIGINT en la base.
  final String id;
  final DateTime openedAt;
  final String? openedByName;
  final double openingAmount;

  /// null si quien mira no puede ver el esperado (arqueo ciego).
  final double? expectedAmount;
  final CashTotals? totals;

  factory CashOpenShift.fromJson(Map<String, dynamic> json) => CashOpenShift(
        id: '${json['id']}',
        openedAt: ValueTransformers.fromJsonDateTimeLocale(json['opened_at']),
        openedByName: json['opened_by_name']?.toString(),
        openingAmount: _money(json['opening_amount']),
        expectedAmount: _moneyOrNull(json['expected_amount']),
        totals: CashTotals.fromJson(json['totals']),
      );
}

class CashLastClose {
  const CashLastClose({required this.closedAt, required this.closedByName, required this.leftAmount});

  final DateTime? closedAt;
  final String? closedByName;
  final double leftAmount;

  factory CashLastClose.fromJson(Map<String, dynamic> json) => CashLastClose(
        closedAt: _dateOrNull(json['closed_at']),
        closedByName: json['closed_by_name']?.toString(),
        leftAmount: _money(json['left_amount']),
      );
}

/// Un puesto de cobro (u otra cuenta del club, sin caja).
class CashPoint {
  const CashPoint({
    required this.id,
    required this.type,
    required this.name,
    required this.isPrimary,
    required this.active,
    required this.spaces,
    this.openShift,
    this.lastClose,
  });

  final int id;
  final String type;
  final String name;
  final bool isPrimary;
  final bool active;
  final List<CashSpace> spaces;
  final CashOpenShift? openShift;
  final CashLastClose? lastClose;

  bool get isOpen => openShift != null;

  factory CashPoint.fromJson(Map<String, dynamic> json) => CashPoint(
        id: json['id'] as int,
        type: json['type']?.toString() ?? 'CASH_POINT',
        name: json['name']?.toString() ?? '',
        isPrimary: json['is_primary'] == true,
        active: json['active'] != false,
        spaces: _list(json['spaces']).map(CashSpace.fromJson).toList(),
        openShift: json['open_shift'] == null ? null : CashOpenShift.fromJson(json['open_shift'] as Map<String, dynamic>),
        lastClose: json['last_close'] == null ? null : CashLastClose.fromJson(json['last_close'] as Map<String, dynamic>),
      );
}

/// Lo cobrado por otro medio: se muestra para control y no suma al efectivo.
class CashOtherMethod {
  const CashOtherMethod({required this.name, required this.amount, required this.count});

  final String name;
  final double amount;
  final int count;

  factory CashOtherMethod.fromJson(Map<String, dynamic> json) => CashOtherMethod(
        name: json['name']?.toString() ?? '',
        amount: _money(json['amount']),
        count: (json['count'] as num? ?? 0).toInt(),
      );
}

class CashOverview {
  const CashOverview({required this.settings, required this.canSeeExpected, required this.points, required this.todayOtherMethods});

  final CashSettings settings;
  final bool canSeeExpected;
  final List<CashPoint> points;
  final List<CashOtherMethod> todayOtherMethods;

  List<CashPoint> get activePoints => points.where((point) => point.active).toList();

  factory CashOverview.fromJson(Map<String, dynamic> json) => CashOverview(
        settings: CashSettings.fromJson(json['settings'] as Map<String, dynamic>),
        canSeeExpected: json['can_see_expected'] == true,
        points: _list(json['points']).map(CashPoint.fromJson).toList(),
        todayOtherMethods: _list(json['today_other_methods']).map(CashOtherMethod.fromJson).toList(),
      );
}

/// Una caja: abierta o ya cerrada.
class CashShift {
  const CashShift({
    required this.id,
    required this.cashAccountId,
    required this.accountName,
    required this.status,
    required this.openedAt,
    required this.openedByName,
    required this.openingAmount,
    required this.closedAt,
    required this.closedByName,
    required this.expectedAmount,
    required this.countedAmount,
    required this.difference,
    required this.leftAmount,
    required this.withdrawnAmount,
    required this.totals,
    required this.note,
    required this.statusLabel,
    required this.otherMethods,
    required this.canSeeExpected,
  });

  final String id;
  final int cashAccountId;
  final String accountName;
  final String status;
  final DateTime openedAt;
  final String? openedByName;
  final double openingAmount;
  final DateTime? closedAt;
  final String? closedByName;
  final double? expectedAmount;
  final double? countedAmount;
  final double? difference;
  final double? leftAmount;
  final double? withdrawnAmount;
  final CashTotals? totals;
  final String? note;

  /// BALANCED, WITHIN_TOLERANCE o REVIEW (solo en la lista de cierres).
  final String? statusLabel;
  final List<CashOtherMethod> otherMethods;
  final bool canSeeExpected;

  bool get isOpen => status == 'OPEN';

  factory CashShift.fromJson(Map<String, dynamic> json) => CashShift(
        id: '${json['id']}',
        cashAccountId: json['cash_account_id'] as int,
        accountName: json['account_name']?.toString() ?? '',
        status: json['status']?.toString() ?? 'OPEN',
        openedAt: ValueTransformers.fromJsonDateTimeLocale(json['opened_at']),
        openedByName: json['opened_by_name']?.toString(),
        openingAmount: _money(json['opening_amount']),
        closedAt: _dateOrNull(json['closed_at']),
        closedByName: json['closed_by_name']?.toString(),
        expectedAmount: _moneyOrNull(json['expected_amount']),
        countedAmount: _moneyOrNull(json['counted_amount']),
        difference: _moneyOrNull(json['difference']),
        leftAmount: _moneyOrNull(json['left_amount']),
        withdrawnAmount: _moneyOrNull(json['withdrawn_amount']),
        totals: CashTotals.fromJson(json['totals_by_kind']),
        note: json['note']?.toString(),
        statusLabel: json['status_label']?.toString(),
        otherMethods: _list(json['other_methods']).map(CashOtherMethod.fromJson).toList(),
        canSeeExpected: json['can_see_expected'] != false,
      );
}

class CashPersonDifference {
  const CashPersonDifference({required this.name, required this.difference});

  final String? name;
  final double difference;

  factory CashPersonDifference.fromJson(Map<String, dynamic> json) =>
      CashPersonDifference(name: json['name']?.toString(), difference: _money(json['difference']));
}

class CashShiftsPage {
  const CashShiftsPage({
    required this.shifts,
    required this.nextCursor,
    required this.count,
    required this.withDifference,
    required this.overTolerance,
    required this.totalDifference,
    required this.byPerson,
  });

  final List<CashShift> shifts;
  final String? nextCursor;
  final int count;
  final int withDifference;
  final int overTolerance;
  final double totalDifference;

  /// null si quien mira no supervisa.
  final List<CashPersonDifference>? byPerson;

  factory CashShiftsPage.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? const {};
    return CashShiftsPage(
      shifts: _list(json['shifts']).map(CashShift.fromJson).toList(),
      nextCursor: json['next_cursor']?.toString(),
      count: (summary['count'] as num? ?? 0).toInt(),
      withDifference: (summary['with_difference'] as num? ?? 0).toInt(),
      overTolerance: (summary['over_tolerance'] as num? ?? 0).toInt(),
      totalDifference: _money(summary['total_difference']),
      byPerson: summary['by_person'] == null ? null : _list(summary['by_person']).map(CashPersonDifference.fromJson).toList(),
    );
  }
}

class CashMovement {
  const CashMovement({
    required this.id,
    required this.createdAt,
    required this.kind,
    required this.amount,
    required this.concept,
    required this.reason,
    required this.needsReview,
    required this.clientId,
    required this.clientName,
    required this.accountName,
    required this.paymentMethodName,
    required this.actorName,
  });

  final String id;
  final DateTime createdAt;
  final String kind;

  /// Con signo: los egresos vienen negativos.
  final double amount;
  final String? concept;
  final String? reason;
  final bool needsReview;
  final int? clientId;
  final String? clientName;
  final String? accountName;
  final String? paymentMethodName;
  final String? actorName;

  factory CashMovement.fromJson(Map<String, dynamic> json) => CashMovement(
        id: '${json['id']}',
        createdAt: ValueTransformers.fromJsonDateTimeLocale(json['created_at']),
        kind: json['kind']?.toString() ?? '',
        amount: _money(json['amount']),
        concept: json['concept']?.toString(),
        reason: json['reason']?.toString(),
        needsReview: json['needs_review'] == true,
        clientId: json['client_id'] as int?,
        clientName: json['client_name']?.toString(),
        accountName: json['account_name']?.toString(),
        paymentMethodName: json['payment_method_name']?.toString(),
        actorName: json['actor_name']?.toString(),
      );
}

class CashMovementsPage {
  const CashMovementsPage({required this.movements, required this.nextCursor});

  final List<CashMovement> movements;
  final String? nextCursor;

  factory CashMovementsPage.fromJson(Map<String, dynamic> json) => CashMovementsPage(
        movements: _list(json['movements']).map(CashMovement.fromJson).toList(),
        nextCursor: json['next_cursor']?.toString(),
      );
}

/// Un puesto como opción al cobrar.
class CashPointRef {
  const CashPointRef({required this.id, required this.name, this.openedByName});

  final int id;
  final String name;
  final String? openedByName;

  factory CashPointRef.fromJson(Map<String, dynamic> json) =>
      CashPointRef(id: json['id'] as int, name: json['name']?.toString() ?? '', openedByName: json['opened_by_name']?.toString());
}

/// A qué puesto entraría un cobro en efectivo.
class CashResolution {
  const CashResolution({
    required this.enabled,
    required this.requireOpenForCash,
    required this.point,
    required this.open,
    required this.openedByName,
    required this.bySpace,
    required this.alternatives,
  });

  final bool enabled;
  final bool requireOpenForCash;
  final CashPointRef? point;
  final bool open;
  final String? openedByName;

  /// true si el puesto sale del espacio del turno (y no del principal).
  final bool bySpace;
  final List<CashPointRef> alternatives;

  factory CashResolution.fromJson(Map<String, dynamic> json) => CashResolution(
        enabled: json['enabled'] == true,
        requireOpenForCash: json['require_open_for_cash'] == true,
        point: json['point'] == null ? null : CashPointRef.fromJson(json['point'] as Map<String, dynamic>),
        open: json['open'] == true,
        openedByName: json['opened_by_name']?.toString(),
        bySpace: json['by_space'] == true,
        alternatives: _list(json['alternatives']).map(CashPointRef.fromJson).toList(),
      );
}
