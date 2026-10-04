import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/price_rule.dart';
import '../../../domain/entities/price_tariff.dart';
import '../../../domain/repositories/price_tariff_repository.dart';

class PriceTariffRepositoryImpl implements PriceTariffRepository {
  final dioInstance = sl<Dio>();

  /// Como `BaseRepository.safeCall`, pero además extrae el `message` real de
  /// un 409 de conflicto (`{error: 'OVERLAP', message: '...'}`) -- el shape
  /// no matchea lo que espera `DomainError.fromErrorResponse` (que busca
  /// `message` en `error` y un código numérico en `code`), así que sin esto
  /// el usuario vería "Unknown Error" en vez del mensaje de solapamiento.
  Future<RepositoryResponse<T>> _safeCall<T>(Future<T> Function() fn) async {
    try {
      final data = await fn();
      return Either.right(data);
    } on DioException catch (err) {
      final response = err.response?.data;

      if (err.response?.statusCode == 409 && response is Map && response['message'] != null) {
        return Either.left(DomainError(
          message: response['message'].toString(),
          internalCode: 409,
          date: DateTime.now(),
        ));
      }

      if (response == null) return Either.left(DomainError.unknownError());

      return Either.left(DomainError.fromErrorResponse(response));
    }
  }

  @override
  Future<RepositoryResponse<List<PriceTariff>>> listByClubPartition(int clubPartitionId) {
    return _safeCall(() async {
      final response = await dioInstance.get(
        '/admin/price_tariff',
        queryParameters: {'club_partition_id': clubPartitionId},
      );

      return (response.data as List)
          .map((row) => PriceTariff.fromJson(row as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<RepositoryResponse<PriceTariff>> create(int clubPartitionId, String name) {
    return _safeCall(() async {
      final response = await dioInstance.post('/admin/price_tariff', data: {
        'club_partition_id': clubPartitionId,
        'name': name,
      });

      return PriceTariff.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<PriceTariff>> rename(int priceTariffId, String name) {
    return _safeCall(() async {
      final response = await dioInstance.put('/admin/price_tariff/$priceTariffId', data: {
        'name': name,
      });

      return PriceTariff.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<PriceTariff>> setActive(int priceTariffId, bool active) {
    return _safeCall(() async {
      final response = await dioInstance.patch(
        '/admin/price_tariff/$priceTariffId/active',
        data: {'active': active},
      );

      return PriceTariff.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<bool>> delete(int priceTariffId) {
    return _safeCall(() async {
      await dioInstance.delete('/admin/price_tariff/$priceTariffId');
      return true;
    });
  }

  @override
  Future<RepositoryResponse<PriceTariff>> addMember(int priceTariffId, int partitionPhysicalId) {
    return _safeCall(() async {
      final response = await dioInstance.post(
        '/admin/price_tariff/$priceTariffId/members',
        data: {'partition_physical_id': partitionPhysicalId},
      );

      return PriceTariff.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<PriceTariff>> removeMember(int priceTariffId, int partitionPhysicalId) {
    return _safeCall(() async {
      final response = await dioInstance.delete(
        '/admin/price_tariff/$priceTariffId/members/$partitionPhysicalId',
      );

      return PriceTariff.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<PriceRule>> createRule(
    int priceTariffId, {
    required List<int> daysOfWeek,
    required String startTime,
    required String endTime,
    required double price,
  }) {
    return _safeCall(() async {
      final response = await dioInstance.post('/admin/price_tariff/$priceTariffId/rules', data: {
        'days_of_week': daysOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'price': price,
      });

      return PriceRule.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<PriceRule>> updateRule(
    int priceRuleId, {
    List<int>? daysOfWeek,
    String? startTime,
    String? endTime,
    double? price,
  }) {
    return _safeCall(() async {
      final response = await dioInstance.put('/admin/price_tariff/rules/$priceRuleId', data: {
        if (daysOfWeek != null) 'days_of_week': daysOfWeek,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (price != null) 'price': price,
      });

      return PriceRule.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<PriceRule>> setRuleActive(int priceRuleId, bool active) {
    return _safeCall(() async {
      final response = await dioInstance.patch(
        '/admin/price_tariff/rules/$priceRuleId/active',
        data: {'active': active},
      );

      return PriceRule.fromJson(response.data as Map<String, dynamic>);
    });
  }
}
