import 'package:json_annotation/json_annotation.dart';

part 'admin_access.g.dart';

/// Rol y permisos del admin logueado (`admin_access` en `/user/authenticate`
/// y `/user/signup`). Los códigos son los de [Permissions].
@JsonSerializable()
class AdminAccess {
  AdminAccess({
    required this.adminId,
    this.clubId,
    required this.active,
    this.role,
    this.permissions = const [],
  });

  @JsonKey(name: "admin_id")
  final int adminId;

  @JsonKey(name: "club_id")
  final int? clubId;

  final bool active;

  final AdminRoleSummary? role;

  final List<String> permissions;

  bool get isSuperAdmin => role?.isSuperAdmin ?? false;

  bool can(String permission) => isSuperAdmin || permissions.contains(permission);

  bool canAny(Iterable<String> permissions) => permissions.any(can);

  Map<String, dynamic> toJson() => _$AdminAccessToJson(this);
  factory AdminAccess.fromJson(Map<String, dynamic> json) => _$AdminAccessFromJson(json);
}

@JsonSerializable()
class AdminRoleSummary {
  AdminRoleSummary({required this.roleId, required this.name, this.isSuperAdmin = false});

  @JsonKey(name: "role_id")
  final int roleId;

  final String name;

  @JsonKey(name: "is_super_admin")
  final bool isSuperAdmin;

  Map<String, dynamic> toJson() => _$AdminRoleSummaryToJson(this);
  factory AdminRoleSummary.fromJson(Map<String, dynamic> json) => _$AdminRoleSummaryFromJson(json);
}
