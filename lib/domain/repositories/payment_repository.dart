import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../entities/payment/payment.dart';
import '../entities/payment/payment_method.dart';
import '../entities/request/payment/payment_list_page_response.dart';
import '../entities/request/page_response.dart';
import '../entities/payment/payment_list_item.dart';

/// Una página de pagos de un cliente.
class ClientPaymentsPage {
  const ClientPaymentsPage({required this.items, required this.total, required this.yearTotal, this.lastPaymentDate});

  final List<PaymentListItem> items;
  final int total;
  final double yearTotal;
  final DateTime? lastPaymentDate;
}

abstract class PaymentRepository {
    Future<Either<DomainError, PageResponse<Payment>>> getClientPayments(int clientId, int page);

    Future<Either<DomainError, Payment>> createPayment(Map<String, dynamic> paymentData);

    /// [kind]: MEMBERSHIP, SESSION, PRODUCT u OTHER. [search]: nombre del cliente.
    Future<Either<DomainError, PaymentListPageResponse>> getPayments(int page, {DateTime? fechaDesde, DateTime? fechaHasta, String? kind, int? paymentMethodId, String? search});

    /// Pagos del cliente (a su nombre y de sus turnos) con su concepto. [kind]: MEMBERSHIP u OTHERS.
    Future<Either<DomainError, ClientPaymentsPage>> getClientPaymentRows(int clientId, int page, {String? kind});

    /// Catálogo de medios de pago del backend (`GET /payments/methods`).
    Future<Either<DomainError, List<PaymentMethod>>> getPaymentMethods();
}