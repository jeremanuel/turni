import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/payment/club_payment_account_status.dart';
import '../../../domain/repositories/club_payment_account_repository.dart';
import 'base/base_repository.dart';

class ClubPaymentAccountRepositoryImpl extends BaseRepository implements ClubPaymentAccountRepository {
  final dioInstance = sl<Dio>();

  static const _basePath = "/admin/payment-account/mercadopago";

  @override
  Future<RepositoryResponse<ClubPaymentAccountStatus>> getMercadoPagoStatus() {
    return safeCall(() async {
      final response = await dioInstance.get(_basePath);

      return ClubPaymentAccountStatus.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<String>> startMercadoPagoLink() {
    return safeCall(() async {
      final response = await dioInstance.post("$_basePath/link");

      return response.data['authorizationUrl'] as String;
    });
  }

  @override
  Future<RepositoryResponse<void>> unlinkMercadoPago() {
    return safeCall(() async {
      await dioInstance.delete(_basePath);
    });
  }
}
