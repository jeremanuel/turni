import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/entities/coordinate.dart';
import '../../../core/utils/entities/range_date.dart';
import '../../../core/utils/types/time_interval.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/club_partition.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/repositories/session_repository.dart';
import '../providers/session_provider.dart';

class SessionRepositoryImplementation extends SessionRepository {

  final SessionProvider sessionProvider;
  final dioInstance = sl<Dio>();

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
  
  @override
  Future<Client?> reservateSession(int sessionId, Client client) {
    
    return sessionProvider.reservateSession(sessionId, client);

  }
  
  @override
  Future<List<Session>> getSessionsBySessionId(int sessionId) {
    return sessionProvider.getSessionsByAdminAndSessionId(sessionId);
  }
  
  @override
  Future deleteSession(int sessionId) async {
    try {
      await dioInstance.delete("/admin/session/$sessionId");

      return true;

    } catch (error) {

      return false;
    }
  }
  
}
