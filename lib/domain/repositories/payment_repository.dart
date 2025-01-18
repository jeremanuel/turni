import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../entities/payment/payment.dart';
import '../entities/request/page_response.dart';

abstract class PaymentRepository {
      Future<Either<DomainError, PageResponse<Payment>>> getClientPayments(int clientId, int page);

}