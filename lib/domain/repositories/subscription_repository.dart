import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../entities/subscription/client_subscription.dart';

abstract class SubscriptionRepository {

  Future<Either<DomainError, ClientSubscription>> subscribeClient(Map<String, dynamic> clientSubscriptionData, int clientId);

  Future<Either<DomainError, Map<String, dynamic>>> previewFixedSessions(Map<String, dynamic> previewData);

  Future<Either<DomainError, int>> previewUnsubscribeLinkedSessions(int clientSubscription, int clientId);

  Future<Either<DomainError, bool>> unSubscribeClient(
    int clientSubscription,
    int clientId, {
    bool unlinkFutureSessions,
  });


}