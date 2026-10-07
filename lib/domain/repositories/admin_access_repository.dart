import '../../core/utils/repository_response.dart';
import '../entities/admin_roles.dart';

/// Roles y permisos (`/admin/roles`), administradores del club
/// (`/admin/admins`) e invitaciones (`/admin_invitation`).
abstract class AdminAccessRepository {
  Future<RepositoryResponse<List<PermissionScreen>>> getCatalog();

  Future<RepositoryResponse<List<AdminRole>>> listRoles();
  Future<RepositoryResponse<AdminRole>> createRole({
    required String name,
    String? description,
    required List<String> permissions,
  });
  Future<RepositoryResponse<AdminRole>> updateRole(
    int roleId, {
    required String name,
    String? description,
    required List<String> permissions,
  });

  Future<RepositoryResponse<List<ClubAdmin>>> listAdmins();
  Future<RepositoryResponse<ClubAdmin>> updateAdmin(int adminId, {int? roleId, bool? active});

  Future<RepositoryResponse<List<AdminInvitation>>> listInvitations();
  Future<RepositoryResponse<AdminInvitation>> createInvitation({
    required String name,
    String lastName = '',
    required int roleId,
  });
  Future<RepositoryResponse<void>> revokeInvitation(String token);

  /// Para quien abre el link (todavía no es admin).
  Future<RepositoryResponse<AdminInvitationPreview>> getInvitation(String token);
  Future<RepositoryResponse<void>> acceptInvitation(String token);
}
