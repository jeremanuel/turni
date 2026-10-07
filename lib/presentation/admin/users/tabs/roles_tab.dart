import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../domain/entities/admin_roles.dart';
import '../../../../domain/repositories/admin_access_repository.dart';
import '../../club_config/widgets/admin_data_table.dart';
import '../users_access.dart';
import '../widgets/role_form_dialog.dart';

/// Roles del club: qué pantallas ve y qué puede hacer cada uno.
class RolesTab extends StatefulWidget {
  const RolesTab({super.key});

  @override
  State<RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<RolesTab> {
  final _repository = sl<AdminAccessRepository>();
  final _access = UsersAccess.current();

  bool _isLoading = true;
  String? _errorMessage;
  List<PermissionScreen> _catalog = [];
  List<AdminRole> _roles = [];

  bool get _canEdit => Permissions.can(Permissions.ROLES_EDITAR);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final catalogResult = await _repository.getCatalog();
    final rolesResult = await _repository.listRoles();
    if (!mounted) return;

    String? error;
    List<PermissionScreen> catalog = [];
    List<AdminRole> roles = [];
    catalogResult.when(left: (failure) => error = failure.message, right: (value) => catalog = value);
    rolesResult.when(left: (failure) => error ??= failure.message, right: (value) => roles = value);

    setState(() {
      _isLoading = false;
      _errorMessage = error;
      _catalog = catalog;
      _roles = roles;
    });
  }

  Future<void> _openForm([AdminRole? role]) async {
    final saved = await showDialog<AdminRole>(
      context: context,
      builder: (_) => RoleFormDialog(catalog: _catalog, role: role),
    );
    if (saved == null || !mounted) return;

    setState(() {
      _roles = role == null
          ? [..._roles, saved]
          : [for (final r in _roles) r.roleId == saved.roleId ? saved : r];
    });
  }

  /// "Turnos (3), Clientes (1)": pantallas que ve y cuántas acciones tiene en cada una.
  String _summary(AdminRole role) {
    if (role.isSuperAdmin) return 'Todos los permisos';
    final parts = <String>[];
    for (final screen in _catalog) {
      final count = screen.actions.where((action) => role.permissions.contains(action.code)).length;
      if (count > 0) parts.add('${screen.name} ($count)');
    }
    return parts.isEmpty ? 'Sin permisos' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null) ...[
            Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cada rol define qué pantallas ve un administrador y qué puede hacer en ellas. '
                  'El super administrador es quien arrancó el club y puede todo.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (_canEdit) ...[
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _catalog.isEmpty ? null : () => _openForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo rol'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: AdminDataTable(
                      columns: const ['Rol', 'Permisos', 'Administradores', ''],
                      columnWidths: const {
                        0: IntrinsicColumnWidth(),
                        1: FlexColumnWidth(),
                        2: IntrinsicColumnWidth(),
                        3: IntrinsicColumnWidth(),
                      },
                      rows: [for (final role in _roles) _roleRow(role)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _roleRow(AdminRole role) {
    final textTheme = Theme.of(context).textTheme;
    final editable = _canEdit && _access.canEditRole(role);

    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(role.name),
          if ((role.description ?? '').isNotEmpty) Text(role.description!, style: textTheme.bodySmall),
        ],
      ),
      Text(_summary(role)),
      Text('${role.adminsCount}'),
      editable
          ? IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openForm(role),
            )
          : const SizedBox(width: 40),
    ];
  }
}
