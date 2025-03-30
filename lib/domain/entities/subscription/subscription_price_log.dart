import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/value_transformers.dart';

part 'subscription_price_log.freezed.dart';
part 'subscription_price_log.g.dart';

@freezed
class SubscriptionPriceLog with _$SubscriptionPriceLog {

  factory SubscriptionPriceLog({
    @JsonKey(name: "subscription_price_log_id")
    required int subscriptionPriceLogId,
    @JsonKey(fromJson: ValueTransformers.fromJsonDouble)
    required double price,
    @JsonKey(name: "start_date", fromJson: ValueTransformers.fromJsonDateTimeLocale)
    required DateTime startDate,
    @JsonKey(name: "end_date", fromJson: ValueTransformers.fromJsonDateTimeLocaleNullable)
    DateTime? endDate,
  }) = _SubscriptionPriceLog;

  factory SubscriptionPriceLog.fromJson(Map<String, dynamic> json) => _$SubscriptionPriceLogFromJson(json);
}


/* {
  "subscription_price_log_id": 2,
  "subscription_id": 1,
  "price": "2500",
  "start_date": "2025-01-11T00:00:00.000Z",
  "end_date": null,
  "created_by_admin": 1
} */