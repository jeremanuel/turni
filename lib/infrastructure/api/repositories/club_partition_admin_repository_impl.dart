import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/club_partition.dart';
import '../../../domain/entities/club_type.dart';
import '../../../domain/entities/physical_partition.dart';
import '../../../domain/repositories/club_partition_admin_repository.dart';
import 'base/base_repository.dart';

class ClubPartitionAdminRepositoryImpl extends BaseRepository
    implements ClubPartitionAdminRepository {
  final dioInstance = sl<Dio>();

  @override
  Future<RepositoryResponse<List<ClubType>>> listClubTypes() {
    return safeCall(() async {
      final response = await dioInstance.get('/admin/club_type');

      return (response.data as List)
          .map((row) => ClubType.fromJson(row as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<RepositoryResponse<List<ClubPartition>>> listClubPartitions({
    bool includeInactive = true,
  }) {
    return safeCall(() async {
      final response = await dioInstance.get(
        '/admin/club_partition',
        queryParameters: {'includeInactive': includeInactive},
      );

      return (response.data as List)
          .map((row) => ClubPartition.fromJson(row as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<RepositoryResponse<ClubPartition>> createClubPartition({
    required int clubTypeId,
    String? phone,
    String? physicalPartitionName,
  }) {
    return safeCall(() async {
      final response = await dioInstance.post('/admin/club_partition', data: {
        'club_type_id': clubTypeId,
        if (phone != null) 'phone': phone,
        if (physicalPartitionName != null)
          'physical_partition_name': physicalPartitionName,
      });

      return ClubPartition.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<ClubPartition>> updateClubPartition(
    int clubPartitionId, {
    int? clubTypeId,
    String? phone,
    String? physicalPartitionName,
  }) {
    return safeCall(() async {
      final response = await dioInstance.put(
        '/admin/club_partition/$clubPartitionId',
        data: {
          if (clubTypeId != null) 'club_type_id': clubTypeId,
          if (phone != null) 'phone': phone,
          if (physicalPartitionName != null)
            'physical_partition_name': physicalPartitionName,
        },
      );

      return ClubPartition.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<ClubPartition>> setClubPartitionActive(
    int clubPartitionId,
    bool active,
  ) {
    return safeCall(() async {
      final response = await dioInstance.patch(
        '/admin/club_partition/$clubPartitionId/active',
        data: {'active': active},
      );

      return ClubPartition.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<List<PhysicalPartition>>> listPartitionPhysical(
    int clubPartitionId, {
    bool includeInactive = true,
  }) {
    return safeCall(() async {
      final response = await dioInstance.get(
        '/admin/partition_physical',
        queryParameters: {
          'club_partition_id': clubPartitionId,
          'includeInactive': includeInactive,
        },
      );

      return (response.data as List)
          .map((row) => PhysicalPartition.fromJson(row as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<RepositoryResponse<PhysicalPartition>> createPartitionPhysical(
    int clubPartitionId, {
    required int minPlayers,
    int? maxPlayers,
    int? physicalIdentifier,
    bool? isCover,
    String? description,
    int? defaultSessionDuration,
    double? defaultSessionPrice,
  }) {
    return safeCall(() async {
      final response = await dioInstance.post('/admin/partition_physical', data: {
        'club_partition_id': clubPartitionId,
        'min_players': minPlayers,
        if (maxPlayers != null) 'max_players': maxPlayers,
        if (physicalIdentifier != null)
          'physical_identifier': physicalIdentifier,
        if (isCover != null) 'is_cover': isCover,
        if (description != null) 'description': description,
        if (defaultSessionDuration != null)
          'default_session_duration': defaultSessionDuration,
        if (defaultSessionPrice != null)
          'default_session_price': defaultSessionPrice,
      });

      return PhysicalPartition.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<PhysicalPartition>> updatePartitionPhysical(
    int partitionPhysicalId, {
    int? minPlayers,
    int? maxPlayers,
    int? physicalIdentifier,
    bool? isCover,
    String? description,
    int? defaultSessionDuration,
    double? defaultSessionPrice,
  }) {
    return safeCall(() async {
      final response = await dioInstance.put(
        '/admin/partition_physical/$partitionPhysicalId',
        data: {
          if (minPlayers != null) 'min_players': minPlayers,
          if (maxPlayers != null) 'max_players': maxPlayers,
          if (physicalIdentifier != null)
            'physical_identifier': physicalIdentifier,
          if (isCover != null) 'is_cover': isCover,
          if (description != null) 'description': description,
          if (defaultSessionDuration != null)
            'default_session_duration': defaultSessionDuration,
          if (defaultSessionPrice != null)
            'default_session_price': defaultSessionPrice,
        },
      );

      return PhysicalPartition.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<PhysicalPartition>> setPartitionPhysicalActive(
    int partitionPhysicalId,
    bool active,
  ) {
    return safeCall(() async {
      final response = await dioInstance.patch(
        '/admin/partition_physical/$partitionPhysicalId/active',
        data: {'active': active},
      );

      return PhysicalPartition.fromJson(response.data as Map<String, dynamic>);
    });
  }
}
