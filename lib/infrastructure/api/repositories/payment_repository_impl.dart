import '../../../domain/entities/payment/payment_list_item.dart';
import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../domain/entities/payment/payment.dart';
import '../../../domain/entities/payment/payment_method.dart';
import '../../../domain/entities/request/page_response.dart';
import '../../../domain/entities/request/payment/payment_list_page_response.dart';
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

      // El pago ya se guardó: si la respuesta no trae el medio (pago sin
      // medio, o un backend viejo), no lo convierte en error.
      final json = Map<String, dynamic>.from(response.data['payment'] as Map);
      json['payment_method'] ??= {'payment_method_id': json['payment_method_id'] ?? 0, 'name': 'Sin método'};
      return Payment.fromJson(json);

    });

  }

  @override
  Future<Either<DomainError, PaymentListPageResponse>> getPayments(int page, {DateTime? fechaDesde, DateTime? fechaHasta, String? kind, int? paymentMethodId, String? search}) {
    return safeCall<PaymentListPageResponse>(() async {
      final queryParams = <String, dynamic>{
        'page': page,
      };
      
      if (fechaDesde != null) {
        queryParams['fechaDesde'] = fechaDesde.toIso8601String();
      }
      
      if (fechaHasta != null) {
        queryParams['fechaHasta'] = fechaHasta.toIso8601String();
      }

      if (kind != null) queryParams['kind'] = kind;
      if (paymentMethodId != null) queryParams['payment_method_id'] = paymentMethodId;
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

      final response = await dioInstance.get("/payments", queryParameters: queryParams);

      return PaymentListPageResponse.fromJson(response.data);
    });
  }

  @override
  Future<Either<DomainError, ClientPaymentsPage>> getClientPaymentRows(int clientId, int page, {String? kind}) {
    return safeCall<ClientPaymentsPage>(() async {
      final response = await dioInstance.get("/admin/payments", queryParameters: {"client_id": clientId, "page": page, if (kind != null) "kind": kind});
      final data = response.data as Map<String, dynamic>;
      final extra = data['extra'] as Map<String, dynamic>? ?? const {};
      return ClientPaymentsPage(
        items: ((data['data'] as List?) ?? const []).whereType<Map<String, dynamic>>().map(PaymentListItem.fromJson).toList(),
        total: (data['total'] as num?)?.toInt() ?? 0,
        yearTotal: (extra['year_total'] as num?)?.toDouble() ?? 0,
        lastPaymentDate: extra['last_payment_date'] == null ? null : DateTime.tryParse('${extra['last_payment_date']}')?.toLocal(),
      );
    });
  }

  @override
  Future<Either<DomainError, List<PaymentMethod>>> getPaymentMethods() {
    return safeCall<List<PaymentMethod>>(() async {
      final response = await dioInstance.get("/payments/methods");

      return (response.data as List)
          .map((el) => PaymentMethod.fromJson(el as Map<String, dynamic>))
          .toList();
    });
  }
}
  
