import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/utils/admin_invite_link.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../domain/entities/admin_roles.dart';
import '../../../../domain/repositories/admin_access_repository.dart';
import '../../club_config/widgets/admin_data_table.dart';
import '../users_access.dart';
import '../widgets/invite_admin_dialog.dart';

/// Administradores del club: cambiar rol, habilitar/deshabilitar, invitar y
/// los links de invitación pendientes.
class AdminsTab extends StatefulWidget {
  const AdminsTab({super.key});

  @override
  State<AdminsTab> createState() => _AdminsTabState();
}

class _AdminsTabState extends State<AdminsTab> {
  final _repository = sl<AdminAccessRepository>();
  final _access = UsersAccess.current();

  bool _isLoading = true;
  String? _errorMessage;
  List<ClubAdmin> _admins = [];
  List<AdminRole> _roles = [];
  List<AdminInvitation> _invitations = [];

  bool get _canEdit => Permissions.can(Permissions.ADMINISTRADORES_EDITAR);
  bool get _canInvite => Permissions.can(Permissions.ADMINISTRADORES_INVITAR);

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

    final results = await Future.wait([
      _repository.listAdmins(),
      _repository.listRoles(),
      _repository.listInvitations(),
    ]);
    if (!mounted) return;

    String? error;
    T? valueOf<T>(Either<DomainError, dynamic> result) => result.when(
          left: (failure) {
            error ??= failure.message;
            return null;
          },
          right: (value) => value as T,
        );

    final admins = valueOf<List<ClubAdmin>>(results[0]);
    final roles = valueOf<List<AdminRole>>(results[1]);
    final invitations = valueOf<List<AdminInvitation>>(results[2]);

    setState(() {
      _isLoading = false;
      _errorMessage = error;
      _admins = admins ?? [];
      _roles = roles ?? [];
      _invitations = invitations ?? [];
    });
  }

  Future<void> _invite() async {
    final invitation = await showDialog<AdminInvitation>(
      context: context,
      builder: (_) => InviteAdminDialog(roles: _access.assignableRoles(_roles)),
    );
    if (invitation == null || !mounted) return;

    setState(() => _invitations = [invitation, ..._invitations]);
    await showDialog<void>(context: context, builder: (_) => InviteLinkDialog(invitation: invitation));
  }

  Future<void> _changeRole(ClubAdmin admin) async {
    final roles = _access.assignableRoles(_roles);
    int? selected = roles.any((r) => r.roleId == admin.role?.roleId) ? admin.role?.roleId : null;

    final roleId = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Rol de ${admin.fullName}'),
          content: SizedBox(
            width: 360,
            child: DropdownButtonFormField<int>(
              value: selected,
              decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
              items: [for (final role in roles) DropdownMenuItem(value: role.roleId, child: Text(role.name))],
              onChanged: (value) => setDialogState(() => selected = value),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            FilledButton(
              onPressed: selected == null ? null : () => Navigator.of(context).pop(selected),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (roleId == null || roleId == admin.role?.roleId) return;

    await _update(admin, roleId: roleId);
  }

  Future<void> _toggleActive(ClubAdmin admin) async {
    if (admin.active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Deshabilitar a ${admin.fullName}?'),
          content: const Text('No va a poder entrar al panel ni usar nada del club hasta que lo vuelvas a habilitar.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Deshabilitar')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await _update(admin, active: !admin.active);
  }

  Future<void> _update(ClubAdmin admin, {int? roleId, bool? active}) async {
    final result = await _repository.updateAdmin(admin.adminId, roleId: roleId, active: active);
    if (!mounted) return;

    result.when(
      left: (failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (updated) => setState(() {
        _admins = [for (final a in _admins) a.adminId == updated.adminId ? updated : a];
      }),
    );
  }

  Future<void> _revoke(AdminInvitation invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Anular la invitación?'),
        content: Text('El link que le pasaste a ${invitation.fullName} deja de funcionar.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Anular')),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await _repository.revokeInvitation(invitation.token);
    if (!mounted) return;

    result.when(
      left: (failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (_) => setState(() => _invitations = _invitations.where((i) => i.token != invitation.token).toList()),
    );
  }

  Future<void> _copyLink(AdminInvitation invitation) async {
    await Clipboard.setData(ClipboardData(text: adminInviteLink(invitation.token)));
    if (mounted) SnackbarsFunctions.showSuccessSnackbar(context, 'Link copiado');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final textTheme = Theme.of(context).textTheme;

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
                  'Quiénes pueden entrar al panel del club y con qué rol.',
                  style: textTheme.bodyMedium,
                ),
              ),
              if (_canInvite)
                FilledButton.icon(
                  onPressed: _invite,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Invitar administrador'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: AdminDataTable(
                  columns: const ['Administrador', 'Email', 'Rol', 'Estado', ''],
                  rows: [for (final admin in _admins) _adminRow(admin)],
                ),
              ),
            ),
          ),
          if (_invitations.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invitaciones pendientes', style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Cada link sirve una sola vez. Quien lo abra entra con su cuenta de Google y queda con el rol elegido.',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: AdminDataTable(
                        columns: const ['Nombre', 'Rol', 'Vence', ''],
                        rows: [for (final invitation in _invitations) _invitationRow(invitation)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _adminRow(ClubAdmin admin) {
    final scheme = Theme.of(context).colorScheme;
    final isMe = admin.adminId == _access.adminId;
    final editable = _canEdit && _access.canEditAdmin(admin, _roles);

    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: scheme.primaryContainer,
            foregroundImage: (admin.picture ?? '').isNotEmpty ? NetworkImage(admin.picture!) : null,
            child: Text(
              admin.name.isEmpty ? '?' : admin.name.substring(0, 1).toUpperCase(),
              style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 10),
          Text(isMe ? '${admin.fullName} (vos)' : admin.fullName),
        ],
      ),
      Text(admin.email ?? '—'),
      Text(admin.role?.name ?? 'Sin rol'),
      Chip(
        label: Text(admin.active ? 'Activo' : 'Deshabilitado'),
        labelStyle: TextStyle(color: admin.active ? null : scheme.error),
        visualDensity: VisualDensity.compact,
      ),
      editable
          ? PopupMenuButton<String>(
              tooltip: 'Acciones',
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'role') _changeRole(admin);
                if (value == 'active') _toggleActive(admin);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'role', child: Text('Cambiar rol')),
                PopupMenuItem(value: 'active', child: Text(admin.active ? 'Deshabilitar' : 'Habilitar')),
              ],
            )
          : const SizedBox(width: 40),
    ];
  }

  List<Widget> _invitationRow(AdminInvitation invitation) {
    return [
      Text(invitation.fullName),
      Text(invitation.role.name),
      Text(DateFormat('dd/MM/yyyy HH:mm').format(invitation.expiresAt.toLocal())),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Copiar link',
            icon: const Icon(Icons.link),
            onPressed: () => _copyLink(invitation),
          ),
          if (_canInvite)
            IconButton(
              tooltip: 'Anular',
              icon: const Icon(Icons.link_off),
              onPressed: () => _revoke(invitation),
            ),
        ],
      ),
    ];
  }
}
