import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../domain/entities/subscription/client_subscription.dart';
import '../../../domain/repositories/subscription_repository.dart';
import 'base/base_repository.dart';

class SubscriptionRepositoryImpl extends BaseRepository implements SubscriptionRepository {

  final dioInstance = sl<Dio>();

  @override
  Future<Either<DomainError, ClientSubscription>> subscribeClient(Map<String, dynamic> clientSubscriptionData, int clientId) {
      return safeCall(() async {
          final response = await dioInstance.post("/client/subscribe/$clientId", data: {"clientSubscription":clientSubscriptionData });

          return ClientSubscription.fromJson(response.data['newSubscription']);
      });
  }
  
  @override
  Future<Either<DomainError, bool>> unSubscribeClient(int clientSubscription, int clientId) {
      return safeCall(() async {

          await dioInstance.post("/client/unsubscribe/$clientId/$clientSubscription");

          return true;
      });
  }
}