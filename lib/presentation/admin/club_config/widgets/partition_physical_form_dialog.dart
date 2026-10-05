import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/repositories/club_partition_admin_repository.dart';
import 'duration_minutes_field.dart';
import 'price_field.dart';

/// Diálogo de alta/edición de una cancha (`partition_physical`) dentro de un
/// deporte/sector. Devuelve la `PhysicalPartition` creada/actualizada por
/// `Navigator.pop`, o `null` si se cancela.
class PartitionPhysicalFormDialog extends StatefulWidget {
  const PartitionPhysicalFormDialog({
    super.key,
    required this.clubPartitionId,
    this.existing,
    this.suggestedIdentifier,
  });

  final int clubPartitionId;
  final PhysicalPartition? existing;
  /// Próximo número sugerido para "Identificador" al crear (ej: si ya hay
  /// canchas 1-4, sugiere 5). Se ignora si `existing` no es null.
  final int? suggestedIdentifier;

  @override
  State<PartitionPhysicalFormDialog> createState() =>
      _PartitionPhysicalFormDialogState();
}

class _PartitionPhysicalFormDialogState
    extends State<PartitionPhysicalFormDialog> {
  final _repository = sl<ClubPartitionAdminRepository>();
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minPlayersController = TextEditingController(text: '2');
  final _maxPlayersController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isCover = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    if (existing != null) {
      _identifierController.text = existing.physicalIdentifier?.toString() ?? '';
      _descriptionController.text = existing.description ?? '';
      _minPlayersController.text = existing.minPlayers.toString();
      _maxPlayersController.text = existing.maxPlayers?.toString() ?? '';
      _durationController.text = existing.defaultSessionDuration?.toString() ?? '';
      _priceController.text = existing.defaultSessionPrice != null
          ? ThousandsFormat.formatPrice(existing.defaultSessionPrice!)
          : '';
      _isCover = existing.isCover == '1';
    } else if (widget.suggestedIdentifier != null) {
      _identifierController.text = widget.suggestedIdentifier.toString();
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _descriptionController.dispose();
    _minPlayersController.dispose();
    _maxPlayersController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final minPlayers = int.parse(_minPlayersController.text.trim());
    final maxPlayersText = _maxPlayersController.text.trim();
    final identifierText = _identifierController.text.trim();
    final durationText = _durationController.text.trim();
    final priceText = _priceController.text.trim();
    final descriptionText = _descriptionController.text.trim();

    final maxPlayers = maxPlayersText.isEmpty ? null : int.tryParse(maxPlayersText);
    final identifier = identifierText.isEmpty ? null : int.tryParse(identifierText);
    final duration = durationText.isEmpty ? null : int.tryParse(durationText);
    final price = priceText.isEmpty ? null : ThousandsFormat.parsePrice(priceText);
    final description = descriptionText.isEmpty ? null : descriptionText;

    final result = _isEditing
        ? await _repository.updatePartitionPhysical(
            widget.existing!.partitionPhysicalId,
            minPlayers: minPlayers,
            maxPlayers: maxPlayers,
            physicalIdentifier: identifier,
            isCover: _isCover,
            description: description,
            defaultSessionDuration: duration,
            defaultSessionPrice: price,
          )
        : await _repository.createPartitionPhysical(
            widget.clubPartitionId,
            minPlayers: minPlayers,
            maxPlayers: maxPlayers,
            physicalIdentifier: identifier,
            isCover: _isCover,
            description: description,
            defaultSessionDuration: duration,
            defaultSessionPrice: price,
          );

    if (!mounted) return;

    result.when(
      left: (failure) {
        setState(() {
          _errorMessage = failure.message;
          _isSaving = false;
        });
      },
      right: (partition) => Navigator.of(context).pop(partition),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar cancha' : 'Nueva cancha'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _identifierController,
                        decoration: const InputDecoration(
                          labelText: 'Identificador',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minPlayersController,
                        decoration: const InputDecoration(
                          labelText: 'Min. jugadores',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          return (parsed == null || parsed < 1)
                              ? 'Requerido, >= 1.'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxPlayersController,
                        decoration: const InputDecoration(
                          labelText: 'Max. jugadores',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DurationMinutesField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duración (min)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PriceField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Precio default',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('¿Cancha cubierta?'),
                  value: _isCover,
                  onChanged: (value) => setState(() => _isCover = value),
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
