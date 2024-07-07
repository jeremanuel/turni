import '../../../domain/entities/club_partition.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/repositories/session_repository.dart';
import '../providers/session_provider.dart';

class SessionRepositoryImplementation extends SessionRepository {
  final SessionProvider sessionProvider;

  SessionRepositoryImplementation({required this.sessionProvider});

  @override
  Future<List<ClubPartition>> getPhysicalPartitions() async {
    return sessionProvider.getClubPartitionsByAdmin();
  }

  @override
  Future<List<Session>> getSessions(DateTime date) {
    return sessionProvider.getSessionsByAdmin(date);
  }

  @override
  createSessions(List<Session> sessions, List<int> physicalPartitions,
      List<DateTime> dates) {
    return sessionProvider.createSessions(sessions, physicalPartitions, dates);
  }

  @override
  Future<Session> saveSession(Session session) {
    return sessionProvider.saveSession(session);
  }
}
