import '../entities/club_partition.dart';
import '../entities/physical_partition.dart';
import '../entities/session.dart';

abstract class SessionRepository {
  
  Future<List<Session>> getSessions(DateTime date);
  
  List<ClubPartition> getPhysicalPartitions();

}


