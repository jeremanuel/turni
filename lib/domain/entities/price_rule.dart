import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/value_transformers.dart';

part 'price_rule.g.dart';

@JsonSerializable()
class PriceRule {
  PriceRule({
    required this.priceRuleId,
    required this.priceTariffId,
    required this.daysOfWeek,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.active,
  });

  @JsonKey(name: 'price_rule_id')
  final int priceRuleId;
  @JsonKey(name: 'price_tariff_id')
  final int priceTariffId;
  /// 1 = lunes ... 7 = domingo (ISO-8601).
  @JsonKey(name: 'days_of_week')
  final List<int> daysOfWeek;
  /// "HH:mm"
  @JsonKey(name: 'start_time')
  final String startTime;
  /// "HH:mm"
  @JsonKey(name: 'end_time')
  final String endTime;
  @JsonKey(fromJson: ValueTransformers.fromJsonDouble)
  final double price;
  final bool active;

  Map<String, dynamic> toJson() => _$PriceRuleToJson(this);
  factory PriceRule.fromJson(Map<String, dynamic> json) =>
      _$PriceRuleFromJson(json);
}
