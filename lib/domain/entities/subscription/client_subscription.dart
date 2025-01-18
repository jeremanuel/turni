import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/value_transformers.dart';
import 'subscription.dart';

part 'client_subscription.freezed.dart';
part 'client_subscription.g.dart';

@freezed
class ClientSubscription with _$ClientSubscription {

  factory ClientSubscription({
    @JsonKey(name: "client_subscription_id")
    required int clientSubscriptionId,
    @JsonKey(name: "start_date", fromJson: ValueTransformers.fromJsonDateTimeLocale)
    required DateTime startDate,
    @JsonKey(name: "end_date", fromJson: ValueTransformers.fromJsonDateTimeLocaleNullable)
    DateTime? endDate,
    required Subscription subscription
  }) = _ClientSubscription;

  ClientSubscription._();

  bool get isActive => endDate == null;

  factory ClientSubscription.fromJson(Map<String, dynamic> json) => _$ClientSubscriptionFromJson(json);
}