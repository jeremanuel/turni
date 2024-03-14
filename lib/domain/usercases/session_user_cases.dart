import '../entities/physical_partition.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

class SessionUserCases {
  
  final SessionRepository _sessionRepository;

  SessionUserCases(this._sessionRepository);

  Future<List<Session>> getSessions(DateTime date) async {
    return _sessionRepository.getSessions(date);
  }
  Future<List<PhysicalPartition>> getPhysicalPartitions() async {
    return _sessionRepository.getPhysicalPartitions();
  }
}