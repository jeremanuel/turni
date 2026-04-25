import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../domain/entities/payment/payment.dart';
import '../../../domain/entities/request/page_response.dart';
import '../../../domain/entities/request/payment/payment_list_response.dart';
import '../../../domain/repositories/payment_repository.dart';
import 'base/base_repository.dart';

class PaymentRepositoryImpl extends BaseRepository implements PaymentRepository {
  
  final dioInstance = sl<Dio>();

  @override
  Future<Either<DomainError, PageResponse<Payment>>> getClientPayments(int clientId, int page) {  

    return safeCall(() async {
 
      final response = await dioInstance.get("/admin/payments", queryParameters: {"client_id":clientId, "page":page });

      return PageResponse(response.data['total'], response.data['data'].map<Payment>((el) => Payment.fromJson(el)).toList());

    });

  }
  
  @override
  Future<Either<DomainError, Payment>> createPayment(Map<String, dynamic> paymentData) {

    return safeCall<Payment>(() async {
      final response = await dioInstance.post("/admin/payment", data: {"payment":paymentData});	

      return Payment.fromJson(response.data['payment']);

    });

  }

  @override
  Future<Either<DomainError, PaymentListResponse>> getPayments(int page, {DateTime? fechaDesde, DateTime? fechaHasta}) {
    return safeCall<PaymentListResponse>(() async {
      final queryParams = <String, dynamic>{
        'page': page,
      };
      
      if (fechaDesde != null) {
        queryParams['fechaDesde'] = fechaDesde.toIso8601String();
      }
      
      if (fechaHasta != null) {
        queryParams['fechaHasta'] = fechaHasta.toIso8601String();
      }

      final response = await dioInstance.get("/payments", queryParameters: queryParams);

      return PaymentListResponse.fromJson(response.data);
    });
  }
}
  
