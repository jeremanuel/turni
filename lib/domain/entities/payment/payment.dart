import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/value_transformers.dart';
import '../client.dart';
import '../subscription/client_subscription.dart';
import 'payment_method.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

@freezed
sealed class Payment with _$Payment {

  factory Payment({
    @JsonKey(name: "payment_id")
    int? paymentId,
    @JsonKey(name: "client_id")
    required int clientId,
    // Client? client,
    @JsonKey(name: "client_subscription_id")
    int? clientSubscriptionId,
    @JsonKey(fromJson: ValueTransformers.fromJsonDouble)
    required double amount,
    @JsonKey(name: "payment_method")
    required PaymentMethod paymentMethod,
    String? observation,
    @JsonKey(name: "payment_date", fromJson: ValueTransformers.fromJsonDateTimeLocale)
    required DateTime paymentDate,
    @JsonKey(name: "created_by_admin")  
    required int createdByAdmin,
    @JsonKey(name: "client_subscription")  
    ClientSubscription? clientSubscription,
    bool? isExtra,
    /// Puesto elegido a mano para un cobro en efectivo; sin esto va al del espacio.
    @JsonKey(name: "cash_account_id", includeIfNull: false)
    int? cashAccountId,
    /// Lo ya devuelto o anulado de este cobro: en el panel del turno `amount` es lo que quedó.
    @JsonKey(name: "reversed_amount", includeToJson: false, fromJson: ValueTransformers.fromJsonDouble)
    @Default(0) double reversedAmount,
  }) = _Payment;

  Payment._();

  /// Cobro online (Mercado Pago): se devuelve, no se anula.
  bool get isOnline => paymentMethod.providerType != null;

  factory Payment.fromExtra({
    required double amount,
    required PaymentMethod method,
    int? cashAccountId,
  }) => Payment(
    createdByAdmin: 1, // Assuming the admin ID is 1 for simplicity
    clientId: -1,
    amount: amount,
    paymentMethod: method,
    paymentDate: DateTime.now(),
    cashAccountId: cashAccountId,
  );

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}