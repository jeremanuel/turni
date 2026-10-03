import '../../../core/utils/value_transformers.dart';

enum PaymentListItemType {
  payment,
  sessionPayment,
}

class PaymentListItem {
  final int paymentId;
  final int? clientId;
  final String clientName;
  final DateTime paymentDate;
  final double amount;
  final String paymentMethodName;
  final String? subscriptionName;
  final String? observation;
  final int? sessionId;
  final PaymentListItemType type;

  const PaymentListItem({
    required this.paymentId,
    required this.clientId,
    required this.clientName,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethodName,
    required this.subscriptionName,
    required this.observation,
    required this.sessionId,
    required this.type,
  });

  bool get isSessionPayment => type == PaymentListItemType.sessionPayment;

  factory PaymentListItem.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    final person = client?['person'] as Map<String, dynamic>?;

    final clientName = [
      person?['name']?.toString(),
      person?['last_name']?.toString(),
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ').trim();

    final paymentMethod = json['payment_method'] as Map<String, dynamic>?;
    final clientSubscription = json['client_subscription'] as Map<String, dynamic>?;
    final subscription = clientSubscription?['subscription'] as Map<String, dynamic>?;

    final sessionId = ValueTransformers.fromJsonIntNullable(json['session_id']);

    return PaymentListItem(
      paymentId: ValueTransformers.fromJsonInt(json['payment_id']),
      clientId: ValueTransformers.fromJsonIntNullable(json['client_id']),
      clientName: clientName.isEmpty ? 'Sin cliente' : clientName,
      paymentDate: json['payment_date'] != null
          ? ValueTransformers.fromJsonDateTimeLocale(json['payment_date'])
          : DateTime.now(),
      amount: ValueTransformers.fromJsonDouble(json['amount']),
      paymentMethodName: paymentMethod?['name']?.toString() ?? 'Sin metodo',
      subscriptionName: subscription?['name']?.toString(),
      observation: json['observation']?.toString(),
      sessionId: sessionId,
      type: sessionId != null
          ? PaymentListItemType.sessionPayment
          : PaymentListItemType.payment,
    );
  }
}
