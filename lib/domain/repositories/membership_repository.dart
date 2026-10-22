import '../../core/utils/repository_response.dart';
import '../entities/membership/membership.dart';

/// Abonos con cuotas (`/memberships`). Todo lo de acá aplica solo a servicios
/// con abonos que el admin ve (ver `AdminFeatures.memberships`).
abstract class MembershipRepository {
  Future<RepositoryResponse<List<MembershipPlansPartition>>> plans();

  /// [body]: `{club_partition_id, name, days_per_week, billing_mode, billing_day, grace_days, price}`.
  Future<RepositoryResponse<void>> savePlan(Map<String, dynamic> body, {int? planId});
  Future<RepositoryResponse<void>> archivePlan(int planId, {required bool archived});

  Future<RepositoryResponse<ClientMemberships>> clientMemberships(int clientId);

  /// [startDate]/[endDate]: día de inicio y de vuelta (null = hasta que vuelva).
  Future<RepositoryResponse<Membership>> pause(int membershipId, {required DateTime startDate, DateTime? endDate, String? reason});
  Future<RepositoryResponse<Membership>> updatePause(int membershipId, int pauseId, {DateTime? startDate, DateTime? endDate, String? reason, bool clearEnd = false});

  Future<RepositoryResponse<Membership>> registerPayment(
    int membershipId, {
    required int periods,
    required double amount,
    int? paymentMethodId,
    DateTime? paymentDate,
    String? observation,
  });

  Future<RepositoryResponse<Membership>> changePlan(int membershipId, int planId);

  Future<RepositoryResponse<MembershipBoard>> board();

  /// Devuelve `(sent, withoutApp)`.
  Future<RepositoryResponse<(int, int)>> sendReminders(List<int> membershipIds, {String channel = 'APP', String? message});

  Future<RepositoryResponse<MembershipSettings>> settings();
  Future<RepositoryResponse<MembershipSettings>> saveSettings(MembershipSettings settings);
}
