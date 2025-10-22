import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/value_transformers.dart';

part 'payment_list_extra_data.freezed.dart';
part 'payment_list_extra_data.g.dart';

@freezed
sealed class PaymentListExtraData with _$PaymentListExtraData {

  factory PaymentListExtraData({

    @JsonKey(
      fromJson: ValueTransformers.fromJsonDoubleNullable
    )
    double? totalAmount,
    int? totalCount
  }) = _PaymentListExtraData;

  factory PaymentListExtraData.fromJson(Map<String, dynamic> json) => _$PaymentListExtraDataFromJson(json);
}