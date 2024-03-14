import 'dart:math';

import '../../../domain/entities/physical_partition.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/repositories/session_repository.dart';

class SessionRepositoryTest extends SessionRepository {
  @override
  List<PhysicalPartition> getPhysicalPartitions() {
    // TODO: implement getPhysicalPartitions
    return [
      PhysicalPartition(
          partitionPhysicalId: 1,
          clubPartitionId: 1,
          minPlayers: 5,
          maxPlayers: 2,
          physicalIdentifier: 25,
          isCover: "false",
          description: "description"),
      PhysicalPartition(
          partitionPhysicalId: 2,
          clubPartitionId: 1,
          minPlayers: 5,
          maxPlayers: 2,
          physicalIdentifier: 14,
          isCover: "false",
          description: "description"),
      PhysicalPartition(
          partitionPhysicalId: 3,
          clubPartitionId: 1,
          minPlayers: 5,
          maxPlayers: 2,
          physicalIdentifier: 12,
          isCover: "false",
          description: "description"),
      PhysicalPartition(
          partitionPhysicalId: 4,
          clubPartitionId: 1,
          minPlayers: 5,
          maxPlayers: 2,
          physicalIdentifier: 13,
          isCover: "false",
          description: "description")
    ];
  }

  @override
  Future<List<Session>> getSessions(DateTime date) async {

    await Future.delayed(Duration(seconds: 1));
    return [
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 10), "01:30", null,
            1500, 1, 1),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 11, 30), "01:30", null,
            1500, 1, 1),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 13), "01:30", 1, 1500,
            1, 1),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 14, 30), "01:30", 1,
            1500, 1, 1),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 16), "01:30", 1, 1500,
            1, 1),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 17, 45), "01:30", null,
            1500, 1, 1),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 19, 30), "01:30", 1,
            1500, 1, 1),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 9), "01:30", null,
            1500, 1, 2),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 10, 45), "01:30", null,
            1500, 1, 2),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 13), "01:30", 1, 1500,
            1, 2),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 14, 30), "01:30", 1,
            1500, 1, 2),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 16), "01:30", 1, 1500,
            1, 2),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 17, 45), "01:30", null,
            1500, 1, 2),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 19, 30), "01:30", 1,
            1500, 1, 2),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 15), "01:30", 2, 1500,
            1, 3),
      if (Random().nextBool())
        Session(1, DateTime.now(), DateTime(2024, 3, 12, 15), "01:30", 2, 1500,
            1, 4)
    ];
  }
}
