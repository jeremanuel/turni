import '../../core/utils/repository_response.dart';
import '../entities/fiscal/fiscal.dart';

/// Códigos con los que la API frena una operación de facturación.
class FiscalErrors {
  FiscalErrors._();

  static const profileLocked = 'FISCAL_PROFILE_LOCKED';
  static const notConnected = 'FISCAL_NOT_CONNECTED';
  static const notEnabled = 'FISCAL_NOT_ENABLED';
  static const documentState = 'FISCAL_DOCUMENT_STATE';
}

/// Facturación electrónica con ARCA (`/admin/fiscal`).
abstract class FiscalRepository {
  Future<RepositoryResponse<FiscalSettings>> getSettings();

  /// Solo manda lo que viene; el servidor completa con lo guardado.
  Future<RepositoryResponse<FiscalProfile>> saveSettings(Map<String, dynamic> changes);

  /// El club dice que ya delegó el servicio en ARCA.
  Future<RepositoryResponse<FiscalProfile>> markDelegated();

  /// Prueba la conexión y trae los puntos de venta habilitados.
  Future<RepositoryResponse<(FiscalProfile, List<int>)>> verifyConnection();

  Future<RepositoryResponse<FiscalDocumentsPage>> getDocuments(FiscalDocumentFilters filters);

  Future<RepositoryResponse<FiscalDocument>> getDocument(String id);

  Future<RepositoryResponse<FiscalDocument>> issue(String id);

  Future<RepositoryResponse<FiscalDocument>> correct(String id, FiscalReceiverInput receiver, {bool saveToClient = false});

  Future<RepositoryResponse<FiscalDocument>> retry(String id);

  Future<RepositoryResponse<FiscalDocument>> cancel(String id, String reason);

  /// CSV de los autorizados del período (separado por ";").
  Future<RepositoryResponse<String>> exportCsv(FiscalDocumentFilters filters);

  Future<RepositoryResponse<ClientFiscalData>> getClientData(int clientId);

  Future<RepositoryResponse<ClientFiscalData>> saveClientData(int clientId, FiscalReceiverInput receiver);

  Future<RepositoryResponse<FiscalPreview>> preview({int? clientId, double? amount});
}
