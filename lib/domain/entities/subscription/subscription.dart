import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/utils/value_transformers.dart';

import '../club_partition.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

@freezed
class Subscription with _$Subscription {

  factory Subscription({
    @JsonKey(name: "club_partition_id")
    required int clubPartitionId,
    @JsonKey(name: "created_at", fromJson: ValueTransformers.fromJsonDateTimeLocale)
    required DateTime createdAt,
    required String name,
    @JsonKey(name: "subscription_id")
    required int subscriptionId
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);
}