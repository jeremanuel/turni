import '../../../core/utils/value_transformers.dart';

/// Cifras de un cobro online: bruto, devuelto, comisiones y neto.
class ReconciliationFigures {
  const ReconciliationFigures({required this.gross, required this.refunded, required this.providerFee, required this.platformFee, required this.net});

  final double gross;
  final double refunded;
  final double providerFee;
  final double platformFee;
  final double net;

  double get fees => providerFee + platformFee;

  static ReconciliationFigures? fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    return ReconciliationFigures(
      gross: ValueTransformers.fromJsonDouble(json['gross']),
      refunded: ValueTransformers.fromJsonDouble(json['refunded']),
      providerFee: ValueTransformers.fromJsonDouble(json['provider_fee']),
      platformFee: ValueTransformers.fromJsonDouble(json['platform_fee']),
      net: ValueTransformers.fromJsonDouble(json['net']),
    );
  }

  static const zero = ReconciliationFigures(gross: 0, refunded: 0, providerFee: 0, platformFee: 0, net: 0);
}

/// Qué no cuadra de un cobro entre el libro y Mercado Pago.
enum ReconciliationDifference {
  gross('GROSS', 'Monto'),
  refunded('REFUNDED', 'Devolución'),
  providerFee('PROVIDER_FEE', 'Comisión de Mercado Pago'),
  platformFee('PLATFORM_FEE', 'Comisión de Turni'),
  noProviderData('NO_PROVIDER_DATA', 'Sin datos de Mercado Pago');

  const ReconciliationDifference(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ReconciliationDifference? fromApiValue(dynamic value) {
    for (final difference in values) {
      if (difference.apiValue == value) return difference;
    }
    return null;
  }
}

class ReconciliationRow {
  const ReconciliationRow({
    required this.sessionId,
    required this.clientId,
    required this.clientName,
    required this.status,
    required this.date,
    required this.lastSyncedAt,
    required this.provider,
    required this.ledger,
    required this.differences,
  });

  final int? sessionId;
  final int clientId;
  final String clientName;
  final String status;
  final DateTime date;
  final DateTime? lastSyncedAt;
  final ReconciliationFigures? provider;
  final ReconciliationFigures ledger;
  final List<ReconciliationDifference> differences;

  bool get matches => differences.isEmpty;

  factory ReconciliationRow.fromJson(Map<String, dynamic> json) => ReconciliationRow(
        sessionId: ValueTransformers.fromJsonIntNullable(json['session_id']),
        clientId: ValueTransformers.fromJsonInt(json['client_id']),
        clientName: json['client_name']?.toString() ?? 'Sin nombre',
        status: json['status']?.toString() ?? '',
        date: ValueTransformers.fromJsonDateTimeLocale(json['date']),
        lastSyncedAt: json['last_synced_at'] == null ? null : ValueTransformers.fromJsonDateTimeLocale(json['last_synced_at']),
        provider: ReconciliationFigures.fromJson(json['provider']),
        ledger: ReconciliationFigures.fromJson(json['ledger']) ?? ReconciliationFigures.zero,
        differences: [
          for (final value in (json['differences'] as List?) ?? const []) ?ReconciliationDifference.fromApiValue(value),
        ],
      );
}

/// `GET /admin/cash/reconciliation`: el libro contra Mercado Pago, cobro por cobro.
class CashReconciliation {
  const CashReconciliation({required this.provider, required this.ledger, required this.payments, required this.withDifferences, required this.rows});

  final ReconciliationFigures provider;
  final ReconciliationFigures ledger;
  final int payments;
  final int withDifferences;
  final List<ReconciliationRow> rows;

  factory CashReconciliation.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? const {};
    return CashReconciliation(
      provider: ReconciliationFigures.fromJson(totals['provider']) ?? ReconciliationFigures.zero,
      ledger: ReconciliationFigures.fromJson(totals['ledger']) ?? ReconciliationFigures.zero,
      payments: ValueTransformers.fromJsonInt(totals['payments'] ?? 0),
      withDifferences: ValueTransformers.fromJsonInt(totals['with_differences'] ?? 0),
      rows: [for (final row in (json['rows'] as List?) ?? const []) if (row is Map<String, dynamic>) ReconciliationRow.fromJson(row)],
    );
  }
}
