import 'package:freezed_annotation/freezed_annotation.dart';

import '../../payment/payment.dart';
import 'payment_list_extra_data.dart';

part 'payment_list_response.freezed.dart';
part 'payment_list_response.g.dart';

@freezed
sealed class PaymentListResponse with _$PaymentListResponse {

  factory PaymentListResponse({
    List<Payment>? payments,
    PaymentListExtraData? extraData
  }) = _PaymentListResponse;

  factory PaymentListResponse.fromJson(Map<String, dynamic> json) => _$PaymentListResponseFromJson(json);
}