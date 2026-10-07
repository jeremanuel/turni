import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turni/core/config/router/route_permissions.dart';
import 'package:turni/core/utils/permissions.dart';
import 'package:turni/domain/entities/admin_access.dart';
import 'package:turni/domain/entities/admin_roles.dart';
import 'package:turni/presentation/admin/users/users_access.dart';
import 'package:turni/presentation/admin/users/widgets/role_form_dialog.dart';

import '../../../helpers/logged_admin.dart';

final _catalog = [
  PermissionScreen(code: 'agenda', name: 'Turnos', actions: [
    PermissionAction(code: 'agenda.ver', name: 'Ver la agenda'),
    PermissionAction(code: 'agenda.reservar', name: 'Reservar y cancelar reservas'),
    PermissionAction(code: 'agenda.eliminar', name: 'Eliminar turnos'),
  ]),
  PermissionScreen(code: 'pagos', name: 'Pagos', actions: [
    PermissionAction(code: 'pagos.ver', name: 'Ver pagos'),
  ]),
];

Future<void> _openRoleDialog(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () => showDialog(context: context, builder: (_) => RoleFormDialog(catalog: _catalog)),
        child: const Text('abrir'),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

bool? _checked(WidgetTester tester, String label) =>
    tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, label)).value;

bool _enabled(WidgetTester tester, String label) =>
    tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, label)).onChanged != null;

void main() {
  group('RoutePermissions', () {
    test('cada sección pide su permiso de ver', () {
      expect(RoutePermissions.requiredFor('/session_manager'), [Permissions.AGENDA_VER]);
      expect(RoutePermissions.requiredFor('/session_manager/add/3'), [Permissions.AGENDA_CREAR]);
      expect(RoutePermissions.requiredFor('/clients'), [Permissions.CLIENTES_VER]);
      expect(RoutePermissions.requiredFor('/client/12'), [Permissions.CLIENTES_VER]);
      expect(RoutePermissions.requiredFor('/client'), [Permissions.CLIENTES_EDITAR]);
      expect(RoutePermissions.requiredFor('/users'), [Permissions.ADMINISTRADORES_VER, Permissions.ROLES_VER]);
      expect(RoutePermissions.requiredFor('/dashboard'), isNull);
    });
  });

  group('AdminAccess', () {
    test('el super administrador puede todo; un rol común solo lo suyo', () {
      final superAdmin = AdminAccess(
        adminId: 1,
        active: true,
        role: AdminRoleSummary(roleId: 1, name: 'Super', isSuperAdmin: true),
      );
      final recepcion = AdminAccess(
        adminId: 2,
        active: true,
        role: AdminRoleSummary(roleId: 2, name: 'Recepción'),
        permissions: ['agenda.ver', 'agenda.reservar'],
      );

      expect(superAdmin.can(Permissions.ADMINISTRADORES_EDITAR), isTrue);
      expect(recepcion.can(Permissions.AGENDA_RESERVAR), isTrue);
      expect(recepcion.can(Permissions.AGENDA_ELIMINAR), isFalse);
      expect(recepcion.canAny([Permissions.PAGOS_VER, Permissions.AGENDA_VER]), isTrue);
    });
  });

  group('UsersAccess', () {
    test('un rol común no edita su rol, ni al super administrador, ni roles con más permisos', () {
      registerLoggedAdmin(permissions: ['agenda.ver', 'agenda.reservar', 'roles.ver', 'roles.editar']);
      final access = UsersAccess.current();
      final propio = AdminRole(roleId: 1, name: 'Rol de prueba', permissions: ['agenda.ver']);
      final menor = AdminRole(roleId: 2, name: 'Recepción', permissions: ['agenda.ver', 'agenda.reservar']);
      final mayor = AdminRole(roleId: 3, name: 'Caja', permissions: ['pagos.ver']);
      final superRole = AdminRole(roleId: 4, name: 'Super administrador', isSuperAdmin: true);

      expect(access.canEditRole(propio), isFalse);
      expect(access.canEditRole(menor), isTrue);
      expect(access.canEditRole(mayor), isFalse);
      expect(access.canEditRole(superRole), isFalse);
      expect(access.assignableRoles([propio, menor, mayor, superRole]).map((r) => r.roleId), [1, 2]);
    });
  });

  group('RoleFormDialog', () {
    testWidgets('marcar una acción marca "ver"; desmarcar "ver" desmarca la pantalla', (tester) async {
      registerLoggedAdmin();
      await _openRoleDialog(tester);

      await tester.tap(find.text('Reservar y cancelar reservas'));
      await tester.pump();
      expect(_checked(tester, 'Ver la agenda'), isTrue);
      expect(_checked(tester, 'Reservar y cancelar reservas'), isTrue);

      await tester.tap(find.text('Ver la agenda'));
      await tester.pump();
      expect(_checked(tester, 'Ver la agenda'), isFalse);
      expect(_checked(tester, 'Reservar y cancelar reservas'), isFalse);
    });

    testWidgets('un rol común no puede marcar acciones que no tiene', (tester) async {
      registerLoggedAdmin(permissions: ['agenda.ver', 'agenda.reservar', 'roles.editar']);
      await _openRoleDialog(tester);

      expect(_enabled(tester, 'Reservar y cancelar reservas'), isTrue);
      expect(_enabled(tester, 'Eliminar turnos'), isFalse);
      expect(_enabled(tester, 'Ver pagos'), isFalse);
      expect(find.text('Solo podés dar permisos que tu rol tiene.'), findsOneWidget);
    });
  });
}
