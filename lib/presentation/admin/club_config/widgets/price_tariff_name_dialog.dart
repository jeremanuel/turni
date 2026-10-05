import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/price_tariff.dart';
import '../../../../domain/repositories/price_tariff_repository.dart';

/// Diálogo de alta/rename de una tarifa (solo el nombre). Devuelve la
/// `PriceTariff` creada/actualizada por `Navigator.pop`, o `null` si se cancela.
class PriceTariffNameDialog extends StatefulWidget {
  const PriceTariffNameDialog({
    super.key,
    required this.clubPartitionId,
    this.existing,
  });

  final int clubPartitionId;
  final PriceTariff? existing;

  @override
  State<PriceTariffNameDialog> createState() => _PriceTariffNameDialogState();
}

class _PriceTariffNameDialogState extends State<PriceTariffNameDialog> {
  final _repository = sl<PriceTariffRepository>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.existing?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();

    final result = _isEditing
        ? await _repository.rename(widget.existing!.priceTariffId, name)
        : await _repository.create(widget.clubPartitionId, name);

    if (!mounted) return;

    result.when(
      left: (DomainError failure) {
        setState(() {
          _errorMessage = failure.message;
          _isSaving = false;
        });
      },
      right: (PriceTariff tariff) => Navigator.of(context).pop(tariff),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Renombrar tarifa' : 'Nueva tarifa'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la tarifa',
                  hintText: 'Canchas 1 y 2',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Ingresá un nombre.' : null,
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
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
