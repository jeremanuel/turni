import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../domain/entities/payment/payment.dart';
import '../../../domain/entities/request/page_response.dart';
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
}
  
