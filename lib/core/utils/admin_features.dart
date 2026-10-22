import '../../domain/entities/club_partition.dart';
import '../../presentation/core/cubit/auth/auth_cubit.dart';
import '../config/service_locator.dart';

/// Qué secciones tienen sentido para el admin logueado según los servicios
/// que ve: sin ningún gimnasio no hay rutinas; sin ningún servicio con abonos
/// con cuotas no hay abonos, estado de cuotas ni avisos de pago. Cada lugar
/// que muestra algo de eso pregunta acá antes.
class AdminFeatures {
  AdminFeatures._();

  static List<ClubPartition> get _partitions =>
      sl<AuthCubit>().state.userCredential?.admin?.clubPartitions ?? const <ClubPartition>[];

  /// Servicios con abonos con cuotas que ve el admin.
  static List<ClubPartition> get membershipPartitions =>
      _partitions.where((partition) => partition.clubType?.usesMemberships == true).toList();

  static bool get memberships => membershipPartitions.isNotEmpty;

  /// true si ve algún servicio que arma rutinas (gimnasio, funcional).
  static bool get routines => _partitions.any((partition) => partition.clubType?.usesRoutines == true);

  /// true si ese servicio vende abonos con cuotas.
  static bool isMembershipPartition(int? clubPartitionId) =>
      clubPartitionId != null && membershipPartitions.any((partition) => partition.club_partition_id == clubPartitionId);
}
