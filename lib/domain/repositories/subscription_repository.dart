import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../entities/subscription/client_subscription.dart';

abstract class SubscriptionRepository {

  Future<Either<DomainError, ClientSubscription>> subscribeClient(Map<String, dynamic> clientSubscriptionData, int clientId);

  Future<Either<DomainError, bool>> unSubscribeClient(int clientSubscription, int clientId);


}