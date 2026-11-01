import '../../../core/utils/value_transformers.dart';
import 'payment_provider_status.dart';

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
  /// Solo para pagos online; null en los cargados a mano por el admin.
  final PaymentProviderStatus? providerStatus;

  /// Qué se pagó: MEMBERSHIP (abono), SESSION (turno), PRODUCT, OTHER.
  final String conceptKind;

  /// "Abono 3 veces por semana", "Turno · Pádel", "Agua 500 ml".
  final String conceptLabel;

  /// "Cuota de octubre", "Cancha 2 · 18:00".
  final String? conceptDetail;

  /// Quién lo registró (null en pagos online).
  final String? adminName;

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
    this.providerStatus,
    this.conceptKind = 'OTHER',
    this.conceptLabel = 'Pago',
    this.conceptDetail,
    this.adminName,
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
    final concept = json['concept'] as Map<String, dynamic>?;

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
      providerStatus: PaymentProviderStatus.fromApiValue(json['provider_status']),
      conceptKind: concept?['kind']?.toString() ?? (sessionId != null ? 'SESSION' : 'OTHER'),
      conceptLabel: concept?['label']?.toString() ?? subscription?['name']?.toString() ?? (sessionId != null ? 'Turno' : 'Pago'),
      conceptDetail: concept?['detail']?.toString(),
      adminName: json['admin_name']?.toString(),
    );
  }
}
