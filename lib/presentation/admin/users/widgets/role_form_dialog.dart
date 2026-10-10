import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/admin_roles.dart';
import '../../../../domain/repositories/admin_access_repository.dart';
import '../users_access.dart';

/// Alta o edición de un rol: nombre, descripción y, por pantalla, qué acciones
/// puede hacer. Marcar cualquier acción marca "ver" de esa pantalla; desmarcar
/// "ver" desmarca todas (sin ver la pantalla no se puede hacer nada en ella).
/// Devuelve el rol guardado.
class RoleFormDialog extends StatefulWidget {
  const RoleFormDialog({super.key, required this.catalog, this.role});

  final List<PermissionScreen> catalog;

  /// null = rol nuevo.
  final AdminRole? role;

  @override
  State<RoleFormDialog> createState() => _RoleFormDialogState();
}

class _RoleFormDialogState extends State<RoleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _access = UsersAccess.current();
  late final _nameController = TextEditingController(text: widget.role?.name ?? '');
  late final _descriptionController = TextEditingController(text: widget.role?.description ?? '');
  late final Set<String> _selected = {...?widget.role?.permissions};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  PermissionAction? _viewOf(PermissionScreen screen) {
    final view = screen.actions.where((action) => action.isView);
    return view.isEmpty ? null : view.first;
  }

  void _toggle(PermissionScreen screen, PermissionAction action, bool checked) {
    setState(() {
      if (checked) {
        _selected.add(action.code);
        final view = _viewOf(screen);
        if (view != null) _selected.add(view.code);
      } else if (action.isView) {
        _selected.removeAll(screen.actions.map((a) => a.code));
      } else {
        _selected.remove(action.code);
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selected.isEmpty) {
      setState(() => _error = 'Elegí al menos un permiso.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final repository = sl<AdminAccessRepository>();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final permissions = [
      for (final screen in widget.catalog)
        for (final action in screen.actions)
          if (_selected.contains(action.code)) action.code,
    ];

    final result = widget.role == null
        ? await repository.createRole(name: name, description: description, permissions: permissions)
        : await repository.updateRole(widget.role!.roleId, name: name, description: description, permissions: permissions);
    if (!mounted) return;

    result.when(
      left: (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      right: (role) => Navigator.of(context).pop(role),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.role == null ? 'Nuevo rol' : 'Editar rol'),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: widget.role == null,
                  maxLength: 60,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  validator: (value) => (value ?? '').trim().isEmpty ? 'Ingresá un nombre' : null,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Text('Permisos', style: textTheme.titleMedium),
                if (!_access.isSuperAdmin)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Solo podés dar permisos que tu rol tiene.',
                      style: textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 8),
                for (final screen in widget.catalog) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          color: scheme.surfaceContainerHighest,
                          child: Text(screen.name, style: textTheme.titleSmall),
                        ),
                        for (final action in screen.actions)
                          CheckboxListTile(
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _selected.contains(action.code),
                            title: Text(action.name),
                            subtitle: action.description == null ? null : Text(action.description!),
                            onChanged: _access.canGrant(action.code)
                                ? (checked) => _toggle(screen, action, checked ?? false)
                                : null,
                          ),
                      ],
                    ),
                  ),
                ],
                if (_error != null)
                  Text(_error!, style: TextStyle(color: scheme.error)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(widget.role == null ? 'Crear rol' : 'Guardar'),
        ),
      ],
    );
  }
}
