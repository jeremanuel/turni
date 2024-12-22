
import '../../../domain/entities/club_partition.dart';

class BrowserOptions {

  /// En caso de que el browser acepte ClubPartitions en su busqueda.
  final List<ClubPartition>? clubPartitions;


  const BrowserOptions({this.clubPartitions});
}