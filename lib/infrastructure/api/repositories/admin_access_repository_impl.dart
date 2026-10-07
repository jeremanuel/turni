import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/admin_roles.dart';
import '../../../domain/repositories/admin_access_repository.dart';

class AdminAccessRepositoryImpl implements AdminAccessRepository {
  final dioInstance = sl<Dio>();

  Future<RepositoryResponse<T>> _safeCall<T>(Future<T> Function() fn) async {
    try {
      final data = await fn();
      return Either.right(data);
    } on DioException catch (err) {
      final response = err.response?.data;
      if (response == null) return Either.left(DomainError.unknownError());
      return Either.left(DomainError.fromErrorResponse(response));
    }
  }

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) =>
      (data as List).map((row) => fromJson(row as Map<String, dynamic>)).toList();

  @override
  Future<RepositoryResponse<List<PermissionScreen>>> getCatalog() {
    return _safeCall(() async {
      final response = await dioInstance.get('/admin/roles/catalog');
      return _list(response.data, PermissionScreen.fromJson);
    });
  }

  @override
  Future<RepositoryResponse<List<AdminRole>>> listRoles() {
    return _safeCall(() async {
      final response = await dioInstance.get('/admin/roles');
      return _list(response.data, AdminRole.fromJson);
    });
  }

  @override
  Future<RepositoryResponse<AdminRole>> createRole({
    required String name,
    String? description,
    required List<String> permissions,
  }) {
    return _safeCall(() async {
      final response = await dioInstance.post('/admin/roles', data: {
        'name': name,
        'description': description,
        'permissions': permissions,
      });
      return AdminRole.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<AdminRole>> updateRole(
    int roleId, {
    required String name,
    String? description,
    required List<String> permissions,
  }) {
    return _safeCall(() async {
      final response = await dioInstance.put('/admin/roles/$roleId', data: {
        'name': name,
        'description': description,
        'permissions': permissions,
      });
      return AdminRole.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<List<ClubAdmin>>> listAdmins() {
    return _safeCall(() async {
      final response = await dioInstance.get('/admin/admins');
      return _list(response.data, ClubAdmin.fromJson);
    });
  }

  @override
  Future<RepositoryResponse<ClubAdmin>> updateAdmin(int adminId, {int? roleId, bool? active}) {
    return _safeCall(() async {
      final response = await dioInstance.patch('/admin/admins/$adminId', data: {
        if (roleId != null) 'role_id': roleId,
        if (active != null) 'active': active,
      });
      return ClubAdmin.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<List<AdminInvitation>>> listInvitations() {
    return _safeCall(() async {
      final response = await dioInstance.get('/admin/admins/invitations');
      return _list(response.data, AdminInvitation.fromJson);
    });
  }

  @override
  Future<RepositoryResponse<AdminInvitation>> createInvitation({
    required String name,
    String lastName = '',
    required int roleId,
  }) {
    return _safeCall(() async {
      final response = await dioInstance.post('/admin/admins/invitations', data: {
        'name': name,
        'last_name': lastName,
        'role_id': roleId,
      });
      return AdminInvitation.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<void>> revokeInvitation(String token) {
    return _safeCall(() async {
      await dioInstance.delete('/admin/admins/invitations/$token');
    });
  }

  @override
  Future<RepositoryResponse<AdminInvitationPreview>> getInvitation(String token) {
    return _safeCall(() async {
      final response = await dioInstance.get('/admin_invitation/$token');
      return AdminInvitationPreview.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<void>> acceptInvitation(String token) {
    return _safeCall(() async {
      await dioInstance.post('/admin_invitation/$token/accept');
    });
  }
}
