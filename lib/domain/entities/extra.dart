import 'package:freezed_annotation/freezed_annotation.dart';
import 'payment/payment.dart';

part 'extra.freezed.dart';
part 'extra.g.dart';

@freezed
abstract class Extra with _$Extra {
  const factory Extra({
    @JsonKey(name: "extra_id") int? extraId,
    @JsonKey(name: "product_id") int? productId,
    required String name,
    required double amount,
    Payment? payment,
  }) = _Extra;

  const Extra._();
  bool get payed => payment != null;

  factory Extra.fromJson(Map<String, dynamic> json) => _$ExtraFromJson(json);
}
