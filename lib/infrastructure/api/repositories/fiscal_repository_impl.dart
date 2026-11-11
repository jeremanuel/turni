import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/fiscal/fiscal.dart';
import '../../../domain/repositories/fiscal_repository.dart';

class FiscalRepositoryImpl implements FiscalRepository {
  final dioInstance = sl<Dio>();

  static const _path = '/admin/fiscal';

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

  Map<String, dynamic> _query(FiscalDocumentFilters filters) => {
        if (filters.status != null) 'status': filters.status,
        if (filters.from != null) 'from': _day(filters.from!),
        if (filters.to != null) 'to': _day(filters.to!),
        if (filters.clientId != null) 'client_id': filters.clientId,
        if (filters.sessionId != null) 'session_id': filters.sessionId,
        if (filters.cursor != null) 'cursor': filters.cursor,
      };

  Future<FiscalDocument> _document(Future<Response> request) async => FiscalDocument.fromJson(_map(await request));

  @override
  Future<RepositoryResponse<FiscalSettings>> getSettings() =>
      _safeCall(() async => FiscalSettings.fromJson(_map(await dioInstance.get('$_path/settings'))));

  @override
  Future<RepositoryResponse<FiscalProfile>> saveSettings(Map<String, dynamic> changes) =>
      _safeCall(() async => FiscalProfile.fromJson(_map(await dioInstance.put('$_path/settings', data: changes))));

  @override
  Future<RepositoryResponse<FiscalProfile>> markDelegated() =>
      _safeCall(() async => FiscalProfile.fromJson(_map(await dioInstance.post('$_path/connection/delegated'))));

  @override
  Future<RepositoryResponse<(FiscalProfile, List<int>)>> verifyConnection() => _safeCall(() async {
        final json = _map(await dioInstance.post('$_path/connection/verify'));
        final points = (json['points_of_sale'] as List? ?? const []).map((point) => point as int).toList();
        return (FiscalProfile.fromJson(json['profile'] as Map<String, dynamic>), points);
      });

  @override
  Future<RepositoryResponse<FiscalDocumentsPage>> getDocuments(FiscalDocumentFilters filters) =>
      _safeCall(() async => FiscalDocumentsPage.fromJson(_map(await dioInstance.get('$_path/documents', queryParameters: _query(filters)))));

  @override
  Future<RepositoryResponse<FiscalDocument>> getDocument(String id) => _safeCall(() => _document(dioInstance.get('$_path/documents/$id')));

  @override
  Future<RepositoryResponse<FiscalDocument>> issue(String id) => _safeCall(() => _document(dioInstance.post('$_path/documents/$id/issue')));

  @override
  Future<RepositoryResponse<FiscalDocument>> correct(String id, FiscalReceiverInput receiver, {bool saveToClient = false}) => _safeCall(
      () => _document(dioInstance.put('$_path/documents/$id/receiver', data: {...receiver.toJson(), 'save_to_client': saveToClient})));

  @override
  Future<RepositoryResponse<FiscalDocument>> retry(String id) => _safeCall(() => _document(dioInstance.post('$_path/documents/$id/retry')));

  @override
  Future<RepositoryResponse<FiscalDocument>> cancel(String id, String reason) =>
      _safeCall(() => _document(dioInstance.post('$_path/documents/$id/cancel', data: {'reason': reason})));

  @override
  Future<RepositoryResponse<String>> exportCsv(FiscalDocumentFilters filters) => _safeCall(() async {
        final response = await dioInstance.get<String>(
          '$_path/documents/export',
          queryParameters: _query(filters),
          options: Options(responseType: ResponseType.plain),
        );
        return response.data ?? '';
      });

  @override
  Future<RepositoryResponse<ClientFiscalData>> getClientData(int clientId) =>
      _safeCall(() async => ClientFiscalData.fromJson(_map(await dioInstance.get('$_path/clients/$clientId'))));

  @override
  Future<RepositoryResponse<ClientFiscalData>> saveClientData(int clientId, FiscalReceiverInput receiver) =>
      _safeCall(() async => ClientFiscalData.fromJson(_map(await dioInstance.put('$_path/clients/$clientId', data: receiver.toJson()))));

  @override
  Future<RepositoryResponse<FiscalPreview>> preview({int? clientId, double? amount}) => _safeCall(() async => FiscalPreview.fromJson(_map(
      await dioInstance.get('$_path/preview', queryParameters: {'client_id': ?clientId, 'amount': ?amount}))));
}
