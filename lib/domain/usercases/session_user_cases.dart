import '../../core/utils/types/time_interval.dart';
import '../entities/club_partition.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

class SessionUserCases {
  final SessionRepository _sessionRepository;

  SessionUserCases(this._sessionRepository);

  Future<List<Session>> getSessions(DateTime date) async {
    return _sessionRepository.getSessions(date);
  }

  Future<List<ClubPartition>> getClubPartitions() async {
    return _sessionRepository.getPhysicalPartitions();
  }
  createSessions(List<Session> sessions, List<int> physicalPartitions, TimeInterval interval) async {
   return _sessionRepository.createSessions(sessions, physicalPartitions, interval.generateDateRange());
  }

  Future<Session> saveSession(Session session) async {
   return _sessionRepository.saveSession(session);
  }


}
