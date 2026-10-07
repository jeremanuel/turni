import '../../../core/config/service_locator.dart';
import '../../../domain/entities/admin_access.dart';
import '../../../domain/entities/admin_roles.dart';
import '../../core/cubit/auth/auth_cubit.dart';

/// Reglas que también aplica el backend, para no ofrecer acciones que va a
/// rechazar: un admin que no es super administrador solo reparte permisos que
/// él tiene, no edita su propio rol ni a sí mismo, y nadie toca al super
/// administrador.
class UsersAccess {
  UsersAccess._(this._access);

  factory UsersAccess.current() => UsersAccess._(sl<AuthCubit>().state.userCredential?.adminAccess);

  final AdminAccess? _access;

  bool get isSuperAdmin => _access?.isSuperAdmin ?? false;
  int? get adminId => _access?.adminId;
  int? get roleId => _access?.role?.roleId;

  /// Puede dar esta acción a un rol.
  bool canGrant(String permission) => isSuperAdmin || (_access?.permissions.contains(permission) ?? false);

  bool canGrantAll(Iterable<String> permissions) => permissions.every(canGrant);

  /// Roles que puede asignar a otro admin o a una invitación.
  List<AdminRole> assignableRoles(List<AdminRole> roles) =>
      roles.where((role) => !role.isSuperAdmin && canGrantAll(role.permissions)).toList();

  bool canEditRole(AdminRole role) =>
      !role.isSuperAdmin && (isSuperAdmin || (role.roleId != roleId && canGrantAll(role.permissions)));

  bool canEditAdmin(ClubAdmin admin, List<AdminRole> roles) {
    if (admin.adminId == adminId || (admin.role?.isSuperAdmin ?? false)) return false;
    if (isSuperAdmin || admin.role == null) return true;
    final role = roles.where((r) => r.roleId == admin.role!.roleId);
    return role.isNotEmpty && canGrantAll(role.first.permissions);
  }
}
