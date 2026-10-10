import 'package:json_annotation/json_annotation.dart';

import 'admin_access.dart';

part 'admin_roles.g.dart';

/// Pantalla del catálogo de permisos (`GET /admin/roles/catalog`).
@JsonSerializable()
class PermissionScreen {
  PermissionScreen({required this.code, required this.name, required this.actions});

  final String code;
  final String name;
  final List<PermissionAction> actions;

  factory PermissionScreen.fromJson(Map<String, dynamic> json) => _$PermissionScreenFromJson(json);
  Map<String, dynamic> toJson() => _$PermissionScreenToJson(this);
}

@JsonSerializable()
class PermissionAction {
  PermissionAction({required this.code, required this.name, this.description});

  /// Código completo, ej. "agenda.reservar".
  final String code;
  final String name;
  final String? description;

  /// La acción `ver` de cada pantalla: sin ella la pantalla no aparece.
  bool get isView => code.endsWith('.ver');

  factory PermissionAction.fromJson(Map<String, dynamic> json) => _$PermissionActionFromJson(json);
  Map<String, dynamic> toJson() => _$PermissionActionToJson(this);
}

/// Rol del club (`GET /admin/roles`).
@JsonSerializable()
class AdminRole {
  AdminRole({
    required this.roleId,
    required this.name,
    this.description,
    this.isSuperAdmin = false,
    this.permissions = const [],
    this.adminsCount = 0,
  });

  @JsonKey(name: "role_id")
  final int roleId;
  final String name;
  final String? description;
  @JsonKey(name: "is_super_admin")
  final bool isSuperAdmin;

  /// Vacío para el super administrador: tiene todas.
  final List<String> permissions;
  @JsonKey(name: "admins_count")
  final int adminsCount;

  factory AdminRole.fromJson(Map<String, dynamic> json) => _$AdminRoleFromJson(json);
  Map<String, dynamic> toJson() => _$AdminRoleToJson(this);
}

/// Admin del club (`GET /admin/admins`).
@JsonSerializable()
class ClubAdmin {
  ClubAdmin({
    required this.adminId,
    required this.name,
    this.lastName = '',
    this.email,
    this.picture,
    required this.active,
    this.role,
  });

  @JsonKey(name: "admin_id")
  final int adminId;
  final String name;
  @JsonKey(name: "last_name")
  final String lastName;
  final String? email;
  final String? picture;
  final bool active;
  final AdminRoleSummary? role;

  String get fullName => [name, lastName].where((part) => part.trim().isNotEmpty).join(' ');

  factory ClubAdmin.fromJson(Map<String, dynamic> json) => _$ClubAdminFromJson(json);
  Map<String, dynamic> toJson() => _$ClubAdminToJson(this);
}

/// Link pendiente para sumar un admin (`GET /admin/admins/invitations`).
@JsonSerializable()
class AdminInvitation {
  AdminInvitation({
    required this.token,
    required this.name,
    this.lastName = '',
    required this.role,
    required this.createdAt,
    required this.expiresAt,
  });

  final String token;
  final String name;
  @JsonKey(name: "last_name")
  final String lastName;
  final AdminRoleSummary role;
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @JsonKey(name: "expires_at")
  final DateTime expiresAt;

  String get fullName => [name, lastName].where((part) => part.trim().isNotEmpty).join(' ');

  factory AdminInvitation.fromJson(Map<String, dynamic> json) => _$AdminInvitationFromJson(json);
  Map<String, dynamic> toJson() => _$AdminInvitationToJson(this);
}

enum AdminInvitationStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('ACCEPTED')
  accepted,
  @JsonValue('EXPIRED')
  expired,
  @JsonValue('REVOKED')
  revoked,
}

/// Lo que ve quien abre el link (`GET /admin_invitation/:token`).
@JsonSerializable()
class AdminInvitationPreview {
  AdminInvitationPreview({
    this.clubName,
    required this.roleName,
    required this.name,
    this.lastName = '',
    required this.expiresAt,
    required this.status,
  });

  @JsonKey(name: "club_name")
  final String? clubName;
  @JsonKey(name: "role_name")
  final String roleName;
  final String name;
  @JsonKey(name: "last_name")
  final String lastName;
  @JsonKey(name: "expires_at")
  final DateTime expiresAt;
  final AdminInvitationStatus status;

  factory AdminInvitationPreview.fromJson(Map<String, dynamic> json) => _$AdminInvitationPreviewFromJson(json);
  Map<String, dynamic> toJson() => _$AdminInvitationPreviewToJson(this);
}
