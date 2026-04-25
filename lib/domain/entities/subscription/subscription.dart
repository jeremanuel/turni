import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/utils/value_transformers.dart';

import 'subscription_price_log.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

@freezed
sealed class Subscription with _$Subscription {

  factory Subscription({
    @JsonKey(name: "club_partition_id")
    required int clubPartitionId,
    @JsonKey(name: "created_at", fromJson: ValueTransformers.fromJsonDateTimeLocale)
    required DateTime createdAt,
    required String name,
    @JsonKey(name: "subscription_id")
    required int subscriptionId,
    @JsonKey(fromJson: Subscription.fromJsonSubscriptionsPriceLog, name: "subscription_price_log")
    List<SubscriptionPriceLog>? subscriptionsPriceLog
    
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);

  Subscription._();

  SubscriptionPriceLog? getCurrentPrice(){

    if(subscriptionsPriceLog == null || subscriptionsPriceLog!.isEmpty) return null;


    return subscriptionsPriceLog!.first;
  }

  static List<SubscriptionPriceLog>? fromJsonSubscriptionsPriceLog(value){
    if(value == null) return null;

    if(value is List){
      return value.map((e) => SubscriptionPriceLog.fromJson(e)).toList();
    }

    if(value is Map<String, dynamic>){
      return [SubscriptionPriceLog.fromJson(value)];
    }

    return null;
  }
}