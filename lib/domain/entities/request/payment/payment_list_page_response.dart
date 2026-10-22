import '../../../../core/utils/value_transformers.dart';
import '../../payment/payment_list_item.dart';

class PaymentListPageResponse {
  final List<PaymentListItem> items;
  final int totalCount;
  final double totalAmount;

  /// Cobrado por medio de pago (con los filtros aplicados), de mayor a menor.
  final List<(String, double)> byMethod;

  /// Cobrado por tipo de concepto: MEMBERSHIP, SESSION, PRODUCT, OTHER → (monto, cantidad).
  final Map<String, (double, int)> byKind;

  const PaymentListPageResponse({
    required this.items,
    required this.totalCount,
    required this.totalAmount,
    this.byMethod = const [],
    this.byKind = const {},
  });

  factory PaymentListPageResponse.fromJson(Map<String, dynamic> json) {
    final payments = json['payments'] as List<dynamic>? ?? const [];
    final extraData = json['extraData'] as Map<String, dynamic>? ?? const {};

    return PaymentListPageResponse(
      items: payments
          .whereType<Map<String, dynamic>>()
          .map(PaymentListItem.fromJson)
          .toList(),
      totalCount: ValueTransformers.fromJsonIntNullable(extraData['totalCount']) ?? 0,
      totalAmount: ValueTransformers.fromJsonDoubleNullable(extraData['totalAmount']) ?? 0,
      byMethod: ((extraData['byMethod'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((m) => (m['name']?.toString() ?? 'Sin metodo', ValueTransformers.fromJsonDouble(m['amount'])))
          .toList(),
      byKind: {
        for (final entry in ((extraData['byKind'] as Map?) ?? const {}).entries)
          '${entry.key}': (ValueTransformers.fromJsonDouble((entry.value as Map)['amount']), ValueTransformers.fromJsonInt(entry.value['count'])),
      },
    );
  }
}
