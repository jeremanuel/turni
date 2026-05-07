import '../../../../core/utils/value_transformers.dart';
import '../../payment/payment_list_item.dart';

class PaymentListPageResponse {
  final List<PaymentListItem> items;
  final int totalCount;
  final double totalAmount;

  const PaymentListPageResponse({
    required this.items,
    required this.totalCount,
    required this.totalAmount,
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
    );
  }
}
