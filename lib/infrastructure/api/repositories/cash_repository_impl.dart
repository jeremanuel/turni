import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/cash/cash.dart';
import '../../../domain/entities/cash/cash_reconciliation.dart';
import '../../../domain/repositories/cash_repository.dart';

class CashRepositoryImpl implements CashRepository {
  final dioInstance = sl<Dio>();

  static const _path = '/admin/cash';

  Future<RepositoryResponse<T>> _safeCall<T>(Future<T> Function() fn) async {
    try {
      return Either.right(await fn());
    } on DioException catch (err) {
      final response = err.response?.data;
      if (response == null) return Either.left(DomainError.unknownError());
      return Either.left(DomainError.fromErrorResponse(response));
    }
  }

  Map<String, dynamic> _map(Response response) => response.data as Map<String, dynamic>;

  String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _query(CashListFilters filters) => {
        if (filters.cashAccountId != null) 'cash_account_id': filters.cashAccountId,
        if (filters.shiftId != null) 'shift_id': filters.shiftId,
        if (filters.kind != null) 'kind': filters.kind,
        if (filters.from != null) 'from': _day(filters.from!),
        if (filters.to != null) 'to': _day(filters.to!),
        if (filters.withDifference) 'with_difference': 'true',
        if (filters.cursor != null) 'cursor': filters.cursor,
      };

  @override
  Future<RepositoryResponse<CashSettings>> getSettings() =>
      _safeCall(() async => CashSettings.fromJson(_map(await dioInstance.get('$_path/settings'))));

  @override
  Future<RepositoryResponse<CashSettings>> saveSettings(CashSettings settings) =>
      _safeCall(() async => CashSettings.fromJson(_map(await dioInstance.put('$_path/settings', data: settings.toJson()))));

  @override
  Future<RepositoryResponse<CashOverview>> getOverview() =>
      _safeCall(() async => CashOverview.fromJson(_map(await dioInstance.get('$_path/accounts'))));

  @override
  Future<RepositoryResponse<void>> savePoint({int? id, required String name, required List<int> partitionPhysicalIds, required bool isPrimary, bool? active}) =>
      _safeCall(() async {
        final body = {
          'name': name,
          'partition_physical_ids': partitionPhysicalIds,
          'is_primary': isPrimary,
          if (active != null) 'active': active,
        };
        if (id == null) {
          await dioInstance.post('$_path/accounts', data: body);
        } else {
          await dioInstance.put('$_path/accounts/$id', data: body);
        }
      });

  @override
  Future<RepositoryResponse<void>> openShift(int accountId, double openingAmount) => _safeCall(() async {
        await dioInstance.post('$_path/accounts/$accountId/open', data: {'opening_amount': openingAmount});
      });

  @override
  Future<RepositoryResponse<CashShift>> getShift(String id) =>
      _safeCall(() async => CashShift.fromJson(_map(await dioInstance.get('$_path/shifts/$id'))));

  @override
  Future<RepositoryResponse<CashReconciliation>> getReconciliation({required DateTime from, required DateTime to}) =>
      _safeCall(() async => CashReconciliation.fromJson(_map(await dioInstance.get('$_path/reconciliation', queryParameters: {'from': _day(from), 'to': _day(to)}))));

  @override
  Future<RepositoryResponse<CashShiftsPage>> getClosedShifts(CashListFilters filters) =>
      _safeCall(() async => CashShiftsPage.fromJson(_map(await dioInstance.get('$_path/shifts', queryParameters: _query(filters)))));

  @override
  Future<RepositoryResponse<CashShift>> closeShift(String id, {required double countedAmount, required double leftAmount, List<Map<String, dynamic>>? denominations, String? note}) =>
      _safeCall(() async => CashShift.fromJson(_map(await dioInstance.post('$_path/shifts/$id/close', data: {
            'counted_amount': countedAmount,
            'left_amount': leftAmount,
            'denominations': denominations,
            'note': note,
          }))));

  @override
  Future<RepositoryResponse<void>> addMovement(String shiftId, {required String kind, required double amount, required String concept, String? reason, required String clientRequestId}) =>
      _safeCall(() async {
        await dioInstance.post('$_path/shifts/$shiftId/movements', data: {
          'kind': kind,
          'amount': amount,
          'concept': concept,
          if (reason != null) 'reason': reason,
          'client_request_id': clientRequestId,
        });
      });

  @override
  Future<RepositoryResponse<CashMovementsPage>> getMovements(CashListFilters filters) =>
      _safeCall(() async => CashMovementsPage.fromJson(_map(await dioInstance.get('$_path/movements', queryParameters: _query(filters)))));

  @override
  Future<RepositoryResponse<CashResolution>> resolveAccount({int? sessionId}) => _safeCall(() async => CashResolution.fromJson(
      _map(await dioInstance.get('$_path/resolve-account', queryParameters: {if (sessionId != null) 'session_id': sessionId}))));
}
