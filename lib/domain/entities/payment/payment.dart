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
    Client? client,
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
    ClientSubscription? clientSubscription
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}