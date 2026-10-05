// Gestión masiva de turnos: editar o eliminar turnos existentes por reglas.
//
// Contrato con el backend (turni_mono_be):
//   POST /admin/sessions/bulk/preview  {filters, action, view, limit} -> BulkPreview
//   POST /admin/sessions/bulk/apply    {filters, action}              -> BulkApplyResult
//
// Las fechas/horas de los filtros son LOCALES del club (el backend las
// interpreta en America/Argentina/Buenos_Aires): `from`/`to` "yyyy-MM-dd"
// inclusive, `start_from`/`start_to` "HH:mm" inclusive sobre el INICIO del
// turno. Los turnos reservados, con solicitud pendiente o con pagos
// registrados nunca se tocan: vuelven en la vista previa como excluidos.

import 'package:intl/intl.dart';

class BulkSessionFilters {
  const BulkSessionFilters({
    required this.from,
    required this.to,
    required this.daysOfWeek,
    required this.startFrom,
    required this.startTo,
    required this.partitionPhysicalIds,
  });

  /// Día local (sin hora), inclusive.
  final DateTime from;
  final DateTime to;

  /// 1 = lunes ... 7 = domingo (ISO-8601).
  final Set<int> daysOfWeek;

  /// "HH:mm", inclusive.
  final String startFrom;
  final String startTo;
  final Set<int> partitionPhysicalIds;

  bool get isComplete =>
      daysOfWeek.isNotEmpty && partitionPhysicalIds.isNotEmpty && !to.isBefore(from);

  Map<String, dynamic> toJson() {
    final date = DateFormat('yyyy-MM-dd');
    return {
      'from': date.format(from),
      'to': date.format(to),
      'days_of_week': (daysOfWeek.toList()..sort()),
      'start_from': startFrom,
      'start_to': startTo,
      'partition_physical_ids': partitionPhysicalIds.toList()..sort(),
    };
  }
}

enum BulkActionType {
  priceFixed('price_fixed'),
  priceTariff('price_tariff'),
  priceAdjust('price_adjust'),
  duration('duration'),
  shift('shift'),
  delete('delete');

  const BulkActionType(this.wire);
  final String wire;

  bool get isPrice => this == priceFixed || this == priceTariff || this == priceAdjust;
}

class BulkSessionAction {
  const BulkSessionAction({
    required this.type,
    this.price,
    this.percent,
    this.roundTo,
    this.duration,
    this.shiftMinutes,
  });

  final BulkActionType type;

  /// [BulkActionType.priceFixed]
  final double? price;

  /// [BulkActionType.priceAdjust]: +10 sube 10 %, -10 baja 10 %.
  final double? percent;

  /// [BulkActionType.priceAdjust]: redondeo del resultado (ej. 500). Opcional.
  final double? roundTo;

  /// [BulkActionType.duration], en minutos.
  final int? duration;

  /// [BulkActionType.shift]: minutos a correr el inicio (+/-).
  final int? shiftMinutes;

  /// Si tiene los parámetros que su tipo necesita.
  bool get isComplete {
    switch (type) {
      case BulkActionType.priceFixed:
        return price != null && price! >= 0;
      case BulkActionType.priceTariff:
      case BulkActionType.delete:
        return true;
      case BulkActionType.priceAdjust:
        return percent != null && percent != 0;
      case BulkActionType.duration:
        return duration != null && duration! > 0;
      case BulkActionType.shift:
        return shiftMinutes != null && shiftMinutes != 0;
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.wire,
        if (price != null) 'price': price,
        if (percent != null) 'percent': percent,
        if (roundTo != null) 'round_to': roundTo,
        if (duration != null) 'duration': duration,
        if (shiftMinutes != null) 'shift_minutes': shiftMinutes,
      };
}

/// Por qué un turno que cumple las reglas queda afuera de la operación.
enum BulkRowResult {
  ok('ok'),
  booked('booked'),
  pending('pending'),
  paid('paid'),
  overlap('overlap'),

  /// Ya tiene el valor nuevo (ej. $1.200 -> $1.200): no hay nada que cambiar.
  unchanged('unchanged');

  const BulkRowResult(this.wire);
  final String wire;

  static BulkRowResult fromWire(String? value) =>
      BulkRowResult.values.firstWhere((r) => r.wire == value, orElse: () => BulkRowResult.ok);

  bool get isExcluded => this != ok;
}

class BulkExcluded {
  const BulkExcluded({this.booked = 0, this.pending = 0, this.paid = 0, this.overlap = 0, this.unchanged = 0});

  final int booked;
  final int pending;
  final int paid;
  final int overlap;

  /// Ya tenían el valor nuevo: no se tocan, pero no están "protegidos".
  final int unchanged;

  /// Todos los que no se modifican (protegidos + sin cambios).
  int get total => protectedTotal + unchanged;

  /// Los que quedan afuera por estar reservados, pendientes, pagos o superponerse.
  int get protectedTotal => booked + pending + paid + overlap;

  factory BulkExcluded.fromJson(Map<String, dynamic>? json) => BulkExcluded(
        booked: (json?['booked'] as num?)?.toInt() ?? 0,
        pending: (json?['pending'] as num?)?.toInt() ?? 0,
        paid: (json?['paid'] as num?)?.toInt() ?? 0,
        overlap: (json?['overlap'] as num?)?.toInt() ?? 0,
        unchanged: (json?['unchanged'] as num?)?.toInt() ?? 0,
      );
}

class BulkPreviewRow {
  const BulkPreviewRow({
    required this.sessionId,
    required this.partitionPhysicalId,
    required this.startTime,
    required this.duration,
    required this.price,
    required this.result,
    this.newStartTime,
    this.newDuration,
    this.newPrice,
  });

  final int sessionId;
  final int partitionPhysicalId;

  /// Local.
  final DateTime startTime;
  final int duration;
  final double price;
  final BulkRowResult result;
  final DateTime? newStartTime;
  final int? newDuration;
  final double? newPrice;

  factory BulkPreviewRow.fromJson(Map<String, dynamic> json) {
    DateTime? date(Object? v) => v == null ? null : DateTime.parse(v as String).toLocal();
    double? number(Object? v) => v == null ? null : double.parse(v.toString());
    return BulkPreviewRow(
      sessionId: (json['session_id'] as num).toInt(),
      partitionPhysicalId: (json['partition_physical_id'] as num).toInt(),
      startTime: date(json['start_time'])!,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      price: number(json['price']) ?? 0,
      result: BulkRowResult.fromWire(json['result'] as String?),
      newStartTime: date(json['new_start_time']),
      newDuration: (json['new_duration'] as num?)?.toInt(),
      newPrice: number(json['new_price']),
    );
  }
}

class BulkPreview {
  const BulkPreview({
    required this.matched,
    required this.affected,
    required this.excluded,
    required this.rows,
    required this.totalRows,
  });

  /// Turnos que cumplen las reglas (incluye los excluidos).
  final int matched;

  /// Los que la operación modificaría/eliminaría.
  final int affected;
  final BulkExcluded excluded;

  /// Primeras filas de la vista pedida (todas o solo excluidas).
  final List<BulkPreviewRow> rows;

  /// Total de filas de la vista pedida (para "Mostrando X de Y").
  final int totalRows;

  static const empty = BulkPreview(
    matched: 0,
    affected: 0,
    excluded: BulkExcluded(),
    rows: [],
    totalRows: 0,
  );

  factory BulkPreview.fromJson(Map<String, dynamic> json) => BulkPreview(
        matched: (json['matched'] as num).toInt(),
        affected: (json['affected'] as num).toInt(),
        excluded: BulkExcluded.fromJson(json['excluded'] as Map<String, dynamic>?),
        rows: (json['rows'] as List? ?? const [])
            .map((row) => BulkPreviewRow.fromJson(row as Map<String, dynamic>))
            .toList(),
        totalRows: (json['total_rows'] as num?)?.toInt() ?? 0,
      );
}

class BulkApplyResult {
  const BulkApplyResult({required this.affected, required this.excluded});

  final int affected;
  final BulkExcluded excluded;

  factory BulkApplyResult.fromJson(Map<String, dynamic> json) => BulkApplyResult(
        affected: (json['affected'] as num).toInt(),
        excluded: BulkExcluded.fromJson(json['excluded'] as Map<String, dynamic>?),
      );
}
