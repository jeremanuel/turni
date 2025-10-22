import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../entities/payment/payment.dart';
import '../entities/request/page_response.dart';
import '../entities/request/payment/payment_list_response.dart';

abstract class PaymentRepository {
    Future<Either<DomainError, PageResponse<Payment>>> getClientPayments(int clientId, int page);

    Future<Either<DomainError, Payment>> createPayment(Map<String, dynamic> paymentData);

    Future<Either<DomainError, PaymentListResponse>> getPayments(int page, {DateTime? fechaDesde, DateTime? fechaHasta});
}