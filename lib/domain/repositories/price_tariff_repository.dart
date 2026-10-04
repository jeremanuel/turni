import '../../core/utils/repository_response.dart';
import '../entities/price_rule.dart';
import '../entities/price_tariff.dart';

abstract class PriceTariffRepository {
  Future<RepositoryResponse<List<PriceTariff>>> listByClubPartition(int clubPartitionId);
  Future<RepositoryResponse<PriceTariff>> create(int clubPartitionId, String name);
  Future<RepositoryResponse<PriceTariff>> rename(int priceTariffId, String name);
  Future<RepositoryResponse<PriceTariff>> setActive(int priceTariffId, bool active);
  Future<RepositoryResponse<bool>> delete(int priceTariffId);

  Future<RepositoryResponse<PriceTariff>> addMember(int priceTariffId, int partitionPhysicalId);
  Future<RepositoryResponse<PriceTariff>> removeMember(int priceTariffId, int partitionPhysicalId);

  Future<RepositoryResponse<PriceRule>> createRule(
    int priceTariffId, {
    required List<int> daysOfWeek,
    required String startTime,
    required String endTime,
    required double price,
  });

  Future<RepositoryResponse<PriceRule>> updateRule(
    int priceRuleId, {
    List<int>? daysOfWeek,
    String? startTime,
    String? endTime,
    double? price,
  });

  Future<RepositoryResponse<PriceRule>> setRuleActive(int priceRuleId, bool active);
}
