import '../../core/utils/repository_response.dart';
import '../entities/cash/cash.dart';
import '../entities/cash/cash_reconciliation.dart';

/// Filtros comunes de los listados de caja.
class CashListFilters {
  const CashListFilters({this.cashAccountId, this.shiftId, this.kind, this.from, this.to, this.withDifference = false, this.cursor});

  final int? cashAccountId;
  final String? shiftId;
  final String? kind;
  final DateTime? from;
  final DateTime? to;
  final bool withDifference;
  final String? cursor;
}

/// Códigos con los que la API frena una operación de caja.
class CashErrors {
  CashErrors._();

  static const shiftRequired = 'CASH_SHIFT_REQUIRED';
  static const closeNoteRequired = 'CASH_CLOSE_NOTE_REQUIRED';
  static const shiftClosed = 'CASH_SHIFT_CLOSED';
  static const alreadyOpen = 'CASH_SHIFT_ALREADY_OPEN';
  static const shiftsOpen = 'CASH_SHIFTS_OPEN';
}

abstract class CashRepository {
  Future<RepositoryResponse<CashSettings>> getSettings();

  Future<RepositoryResponse<CashSettings>> saveSettings(CashSettings settings);

  Future<RepositoryResponse<CashOverview>> getOverview();

  Future<RepositoryResponse<void>> savePoint({int? id, required String name, required List<int> partitionPhysicalIds, required bool isPrimary, bool? active});

  Future<RepositoryResponse<void>> openShift(int accountId, double openingAmount);

  Future<RepositoryResponse<CashShift>> getShift(String id);

  Future<RepositoryResponse<CashShiftsPage>> getClosedShifts(CashListFilters filters);

  /// Devuelve el cierre ya guardado, con la diferencia que calculó el servidor.
  Future<RepositoryResponse<CashShift>> closeShift(String id, {required double countedAmount, required double leftAmount, List<Map<String, dynamic>>? denominations, String? note});

  Future<RepositoryResponse<void>> addMovement(String shiftId, {required String kind, required double amount, required String concept, String? reason, required String clientRequestId});

  Future<RepositoryResponse<CashMovementsPage>> getMovements(CashListFilters filters);

  /// A qué puesto entraría el efectivo de [sessionId] (o el principal, sin turno).
  Future<RepositoryResponse<CashResolution>> resolveAccount({int? sessionId});

  /// Cobros online del período contra lo que informó Mercado Pago (`caja.conciliar`).
  Future<RepositoryResponse<CashReconciliation>> getReconciliation({required DateTime from, required DateTime to});
}
