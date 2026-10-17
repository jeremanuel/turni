import '../../domain/entities/club_partition.dart';
import '../../domain/entities/partition_vocabulary.dart';
import '../../presentation/core/cubit/auth/auth_cubit.dart';
import '../config/service_locator.dart';

/// Vocabulario común a las modalidades activas del admin logueado, para los
/// textos que no son de una modalidad puntual ("Elegí titular, cancha, día y
/// hora"). Si todas se llaman igual usa ese nombre; si no, "espacio".
PartitionVocabulary adminVocabulary() {
  // Sin sesión cargada (tests, arranque): vocabulario de cancha.
  if (!sl.isRegistered<AuthCubit>()) return PartitionVocabulary.court;
  final partitions = sl<AuthCubit>().state.userCredential?.admin?.clubPartitions ?? const <ClubPartition>[];
  return PartitionVocabulary.common(partitions.where((p) => p.active));
}
