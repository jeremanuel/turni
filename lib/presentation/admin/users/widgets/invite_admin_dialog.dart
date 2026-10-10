import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/admin_invite_link.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/admin_roles.dart';
import '../../../../domain/repositories/admin_access_repository.dart';

/// Pide nombre y rol del nuevo admin y genera el link. Devuelve la invitación
/// creada (o null si se cancela).
class InviteAdminDialog extends StatefulWidget {
  const InviteAdminDialog({super.key, required this.roles});

  /// Roles que quien invita puede asignar.
  final List<AdminRole> roles;

  @override
  State<InviteAdminDialog> createState() => _InviteAdminDialogState();
}

class _InviteAdminDialogState extends State<InviteAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  int? _roleId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await sl<AdminAccessRepository>().createInvitation(
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      roleId: _roleId!,
    );
    if (!mounted) return;

    result.when(
      left: (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      right: (invitation) => Navigator.of(context).pop(invitation),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invitar administrador'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Se genera un link para compartirle. Al abrirlo entra con su cuenta de Google y queda como administrador con este rol.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                validator: (value) => (value ?? '').trim().isEmpty ? 'Ingresá el nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Apellido (opcional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _roleId,
                decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                items: [for (final role in widget.roles) DropdownMenuItem(value: role.roleId, child: Text(role.name))],
                onChanged: (value) => setState(() => _roleId = value),
                validator: (value) => value == null ? 'Elegí un rol' : null,
              ),
              if (widget.roles.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Todavía no hay roles para asignar. Creá uno en "Roles y permisos".',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: const Text('Generar link'),
        ),
      ],
    );
  }
}

/// Muestra el link recién generado para copiarlo y compartirlo.
class InviteLinkDialog extends StatefulWidget {
  const InviteLinkDialog({super.key, required this.invitation});

  final AdminInvitation invitation;

  @override
  State<InviteLinkDialog> createState() => _InviteLinkDialogState();
}

class _InviteLinkDialogState extends State<InviteLinkDialog> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final link = adminInviteLink(widget.invitation.token);
    final expires = DateFormat('dd/MM/yyyy HH:mm').format(widget.invitation.expiresAt.toLocal());
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('Link para ${widget.invitation.fullName}'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compartile este link. Sirve una sola vez y vence el $expires. '
              'Lo podés volver a copiar desde "Invitaciones pendientes".',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(link, style: textTheme.bodySmall),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: link));
            if (mounted) setState(() => _copied = true);
          },
          icon: Icon(_copied ? Icons.check : Icons.copy),
          label: Text(_copied ? 'Copiado' : 'Copiar link'),
        ),
      ],
    );
  }
}
