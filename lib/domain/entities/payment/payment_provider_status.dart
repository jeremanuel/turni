import 'package:flutter/material.dart';

/// Estado de un pago online (`provider_status` de `GET /payments`), tal como
/// lo informa el proveedor (Mercado Pago). Los pagos cargados a mano por el
/// admin no tienen estado (`null`).
enum PaymentProviderStatus {
  pending('Pendiente', Color(0xFFE0A100)),
  approved('Aprobado', Color(0xFF2E9E5B)),
  rejected('Rechazado', Color(0xFFD64545)),
  refunded('Devuelto', Color(0xFF7A7A7A));

  const PaymentProviderStatus(this.label, this.color);

  final String label;
  final Color color;

  static PaymentProviderStatus? fromApiValue(dynamic value) {
    switch (value?.toString()) {
      case 'PENDING':
      case 'IN_PROCESS':
        return PaymentProviderStatus.pending;
      case 'APPROVED':
        return PaymentProviderStatus.approved;
      case 'REJECTED':
      case 'CANCELLED':
      case 'EXPIRED':
        return PaymentProviderStatus.rejected;
      case 'REFUNDED':
      case 'CHARGED_BACK':
        return PaymentProviderStatus.refunded;
      default:
        return null;
    }
  }
}
