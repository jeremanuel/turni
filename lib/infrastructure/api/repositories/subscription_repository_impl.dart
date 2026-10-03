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
                    final response = await dioInstance.post(
                        "/client/subscribe/$clientId",
                        data: {
                            "clientSubscription": clientSubscriptionData,
                            "overrideDates": clientSubscriptionData["overrideDates"] ?? const <String>[],
                        },
                    );

          return ClientSubscription.fromJson(response.data['newSubscription']);
      });
  }

    @override
    Future<Either<DomainError, Map<String, dynamic>>> previewFixedSessions(Map<String, dynamic> previewData) {
        return safeCall(() async {
            final response = await dioInstance.post(
                "/client/subscription/fixed-preview",
                data: previewData,
            );

            final rawPreview = (response.data['preview'] as List?) ?? const [];
            final preview = rawPreview
                    .whereType<Map>()
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList();

            final rawFixedConflict = response.data['fixedConflict'];
            final fixedConflict = rawFixedConflict is Map
                ? Map<String, dynamic>.from(rawFixedConflict)
                : null;

            return {
              'preview': preview,
              'fixedConflict': fixedConflict,
            };
        });
    }
  
  @override
    Future<Either<DomainError, int>> previewUnsubscribeLinkedSessions(int clientSubscription, int clientId) {
            return safeCall(() async {
                    final response = await dioInstance.post(
                        "/client/unsubscribe-preview/$clientId/$clientSubscription",
                    );

                    return (response.data['futureLinkedSessions'] as num?)?.toInt() ?? 0;
            });
    }

    @override
    Future<Either<DomainError, bool>> unSubscribeClient(
        int clientSubscription,
        int clientId, {
        bool unlinkFutureSessions = false,
    }) {
      return safeCall(() async {

                    await dioInstance.post(
                        "/client/unsubscribe/$clientId/$clientSubscription",
                        data: {
                            "unlinkFutureSessions": unlinkFutureSessions,
                        },
                    );

          return true;
      });
  }
}