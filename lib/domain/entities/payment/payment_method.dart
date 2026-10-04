import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_method.freezed.dart';
part 'payment_method.g.dart';

@freezed
sealed class PaymentMethod with _$PaymentMethod {

  

  factory PaymentMethod({
    @JsonKey(name: "payment_method_id")
    required int paymentMethodId,
    required String name,
    /// Proveedor que respalda el medio (ej. "MERCADOPAGO"); null para los
    /// manuales (Efectivo, Transferencia).
    @JsonKey(name: "provider_type")
    String? providerType,
  }) = _PaymentMethod;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => _$PaymentMethodFromJson(json);
}