// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:mocktail/mocktail.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/domain/entities/admin_access.dart';
import 'package:turni/domain/entities/user.dart';
import 'package:turni/domain/usercases/auth_user_cases.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';

class _FakeAuthUserCases extends Mock implements AuthUserCases {}

/// Registra un `AuthCubit` con un admin logueado. Por defecto es super
/// administrador (puede todo); con [permissions] es un rol común con esas
/// acciones. Las pantallas leen los permisos de acá (`Permissions.can`).
void registerLoggedAdmin({List<String>? permissions}) {
  if (sl.isRegistered<AuthCubit>()) sl.unregister<AuthCubit>();

  final superAdmin = permissions == null;
  final cubit = AuthCubit(_FakeAuthUserCases());
  cubit.emit(AuthLogged(
    userCredential: User(
      adminAccess: AdminAccess(
        adminId: 1,
        clubId: 1,
        active: true,
        role: AdminRoleSummary(roleId: 1, name: superAdmin ? 'Super administrador' : 'Rol de prueba', isSuperAdmin: superAdmin),
        permissions: permissions ?? const [],
      ),
    ),
  ));
  sl.registerSingleton<AuthCubit>(cubit);
}
