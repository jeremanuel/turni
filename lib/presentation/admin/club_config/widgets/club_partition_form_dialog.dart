import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/club_type.dart';
import '../../../../domain/repositories/club_partition_admin_repository.dart';

/// Diálogo de alta/edición de un deporte/sector (`club_partition`).
/// Devuelve el `ClubPartition` creado/actualizado por `Navigator.pop`, o `null` si se cancela.
class ClubPartitionFormDialog extends StatefulWidget {
  const ClubPartitionFormDialog({
    super.key,
    required this.clubTypes,
    this.existing,
  });

  final List<ClubType> clubTypes;
  final ClubPartition? existing;

  @override
  State<ClubPartitionFormDialog> createState() =>
      _ClubPartitionFormDialogState();
}

class _ClubPartitionFormDialogState extends State<ClubPartitionFormDialog> {
  final _repository = sl<ClubPartitionAdminRepository>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  int? _clubTypeId;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    if (existing != null) {
      _clubTypeId = existing.club_type_id;
      _nameController.text = existing.physicalPartitionName ?? '';
      _phoneController.text = existing.phone ?? '';
    } else if (widget.clubTypes.isNotEmpty) {
      _clubTypeId = widget.clubTypes.first.clubTypeId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_clubTypeId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final result = _isEditing
        ? await _repository.updateClubPartition(
            widget.existing!.club_partition_id!,
            clubTypeId: _clubTypeId,
            phone: phone,
            physicalPartitionName: name,
          )
        : await _repository.createClubPartition(
            clubTypeId: _clubTypeId!,
            phone: phone.isEmpty ? null : phone,
            physicalPartitionName: name.isEmpty ? null : name,
          );

    if (!mounted) return;

    result.when(
      left: (failure) {
        setState(() {
          _errorMessage = failure.message;
          _isSaving = false;
        });
      },
      right: (clubPartition) => Navigator.of(context).pop(clubPartition),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar deporte/sector' : 'Nuevo deporte/sector'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _clubTypeId,
                decoration: const InputDecoration(
                  labelText: 'Tipo de actividad',
                  border: OutlineInputBorder(),
                ),
                items: widget.clubTypes
                    .map((type) => DropdownMenuItem(
                          value: type.clubTypeId,
                          child: Text(type.name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _clubTypeId = value),
                validator: (value) =>
                    value == null ? 'Seleccioná un tipo de actividad.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la partición física',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
