import 'package:freezed_annotation/freezed_annotation.dart';

import 'price_rule.dart';

part 'price_tariff.g.dart';

@JsonSerializable()
class PriceTariff {
  PriceTariff({
    required this.priceTariffId,
    required this.clubPartitionId,
    required this.name,
    required this.active,
    required this.memberPartitionPhysicalIds,
    required this.rules,
  });

  @JsonKey(name: 'price_tariff_id')
  final int priceTariffId;
  @JsonKey(name: 'club_partition_id')
  final int clubPartitionId;
  final String name;
  final bool active;
  @JsonKey(name: 'member_partition_physical_ids')
  final List<int> memberPartitionPhysicalIds;
  final List<PriceRule> rules;

  Map<String, dynamic> toJson() => _$PriceTariffToJson(this);
  factory PriceTariff.fromJson(Map<String, dynamic> json) =>
      _$PriceTariffFromJson(json);
}
