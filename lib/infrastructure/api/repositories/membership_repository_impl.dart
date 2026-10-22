import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/membership/membership.dart';
import '../../../domain/repositories/membership_repository.dart';

class MembershipRepositoryImpl implements MembershipRepository {
  final dioInstance = sl<Dio>();

  Future<RepositoryResponse<T>> _safeCall<T>(Future<T> Function() fn) async {
    try {
      return Either.right(await fn());
    } on DioException catch (err) {
      final response = err.response?.data;
      if (response == null) return Either.left(DomainError.unknownError());
      return Either.left(DomainError.fromErrorResponse(response));
    }
  }

  Membership _membership(dynamic data) => Membership.fromJson(data as Map<String, dynamic>);

  @override
  Future<RepositoryResponse<List<MembershipPlansPartition>>> plans() => _safeCall(() async {
        final response = await dioInstance.get('/memberships/plans');
        return ((response.data as Map<String, dynamic>)['partitions'] as List)
            .map((p) => MembershipPlansPartition.fromJson(p as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<RepositoryResponse<void>> savePlan(Map<String, dynamic> body, {int? planId}) => _safeCall(() async {
        if (planId == null) {
          await dioInstance.post('/memberships/plans', data: body);
        } else {
          await dioInstance.put('/memberships/plans/$planId', data: body);
        }
      });

  @override
  Future<RepositoryResponse<void>> archivePlan(int planId, {required bool archived}) =>
      _safeCall(() async => dioInstance.post('/memberships/plans/$planId/archive', data: {'archived': archived}));

  @override
  Future<RepositoryResponse<ClientMemberships>> clientMemberships(int clientId) => _safeCall(() async {
        final response = await dioInstance.get('/memberships/clients/$clientId');
        return ClientMemberships.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<RepositoryResponse<Membership>> pause(int membershipId, {required DateTime startDate, DateTime? endDate, String? reason}) =>
      _safeCall(() async => _membership((await dioInstance.post('/memberships/client-subscriptions/$membershipId/pauses', data: {
            'start_date': dayToJson(startDate),
            'end_date': endDate == null ? null : dayToJson(endDate),
            'reason': reason,
          }))
              .data));

  @override
  Future<RepositoryResponse<Membership>> updatePause(int membershipId, int pauseId, {DateTime? startDate, DateTime? endDate, String? reason, bool clearEnd = false}) =>
      _safeCall(() async => _membership((await dioInstance.put('/memberships/client-subscriptions/$membershipId/pauses/$pauseId', data: {
            if (startDate != null) 'start_date': dayToJson(startDate),
            if (endDate != null) 'end_date': dayToJson(endDate),
            if (clearEnd) 'end_date': null,
            if (reason != null) 'reason': reason,
          }))
              .data));

  @override
  Future<RepositoryResponse<Membership>> registerPayment(int membershipId, {required int periods, required double amount, int? paymentMethodId, DateTime? paymentDate, String? observation}) =>
      _safeCall(() async => _membership((await dioInstance.post('/memberships/client-subscriptions/$membershipId/payments', data: {
            'periods_count': periods,
            'amount': amount,
            'payment_method_id': paymentMethodId,
            if (paymentDate != null) 'payment_date': dayToJson(paymentDate),
            'observation': observation,
          }))
              .data));

  @override
  Future<RepositoryResponse<Membership>> changePlan(int membershipId, int planId) => _safeCall(() async =>
      _membership((await dioInstance.post('/memberships/client-subscriptions/$membershipId/change', data: {'subscription_id': planId})).data));

  @override
  Future<RepositoryResponse<MembershipBoard>> board() =>
      _safeCall(() async => MembershipBoard.fromJson((await dioInstance.get('/memberships/board')).data as Map<String, dynamic>));

  @override
  Future<RepositoryResponse<(int, int)>> sendReminders(List<int> membershipIds, {String channel = 'APP', String? message}) => _safeCall(() async {
        final response = await dioInstance.post('/memberships/reminders', data: {'client_subscription_ids': membershipIds, 'channel': channel, 'message': message});
        final data = response.data as Map<String, dynamic>;
        return ((data['sent'] as num).toInt(), (data['without_app'] as num).toInt());
      });

  @override
  Future<RepositoryResponse<MembershipSettings>> settings() =>
      _safeCall(() async => MembershipSettings.fromJson((await dioInstance.get('/memberships/settings')).data as Map<String, dynamic>));

  @override
  Future<RepositoryResponse<MembershipSettings>> saveSettings(MembershipSettings settings) => _safeCall(() async =>
      MembershipSettings.fromJson((await dioInstance.put('/memberships/settings', data: settings.toJson())).data as Map<String, dynamic>));
}
