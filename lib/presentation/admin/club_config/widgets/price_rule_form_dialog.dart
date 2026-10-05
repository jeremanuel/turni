import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/price_rule.dart';
import '../../../../domain/repositories/price_tariff_repository.dart';
import 'price_field.dart';
import 'time_field.dart';

const _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// Diálogo de alta/edición de una franja horaria+precio de una tarifa.
/// Devuelve la `PriceRule` creada/actualizada por `Navigator.pop`, o `null` si se cancela.
class PriceRuleFormDialog extends StatefulWidget {
  const PriceRuleFormDialog({
    super.key,
    required this.priceTariffId,
    this.existing,
  });

  final int priceTariffId;
  final PriceRule? existing;

  @override
  State<PriceRuleFormDialog> createState() => _PriceRuleFormDialogState();
}

class _PriceRuleFormDialogState extends State<PriceRuleFormDialog> {
  final _repository = sl<PriceTariffRepository>();
  final _formKey = GlobalKey<FormState>();
  final _startController = TextEditingController(text: '08:00');
  final _endController = TextEditingController(text: '14:00');
  final _priceController = TextEditingController();
  late Set<int> _selectedDays;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    if (existing != null) {
      _selectedDays = existing.daysOfWeek.toSet();
      _startController.text = existing.startTime;
      _endController.text = existing.endTime;
      _priceController.text = ThousandsFormat.formatPrice(existing.price);
    } else {
      _selectedDays = {1, 2, 3, 4, 5};
    }
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String? _timeValidator(String? value) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').hasMatch((value ?? '').trim());
    return match ? null : 'Formato "HH:mm", ej. 08:00.';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDays.isEmpty) {
      setState(() => _errorMessage = 'Seleccioná al menos un día.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final days = _selectedDays.toList()..sort();
    final price = ThousandsFormat.parsePrice(_priceController.text.trim()) ?? 0;

    final result = _isEditing
        ? await _repository.updateRule(
            widget.existing!.priceRuleId,
            daysOfWeek: days,
            startTime: _startController.text.trim(),
            endTime: _endController.text.trim(),
            price: price,
          )
        : await _repository.createRule(
            widget.priceTariffId,
            daysOfWeek: days,
            startTime: _startController.text.trim(),
            endTime: _endController.text.trim(),
            price: price,
          );

    if (!mounted) return;

    result.when(
      left: (DomainError failure) {
        setState(() {
          _errorMessage = failure.message;
          _isSaving = false;
        });
      },
      right: (PriceRule rule) => Navigator.of(context).pop(rule),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar franja' : 'Nueva franja'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Días de la semana'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final selected = _selectedDays.contains(day);
                  return InkWell(
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    }),
                    borderRadius: BorderRadius.circular(16),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      child: Text(_dayLabels[index]),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TimeField(
                      controller: _startController,
                      decoration: const InputDecoration(
                        labelText: 'Hora inicio',
                        hintText: 'HH:mm',
                        border: OutlineInputBorder(),
                      ),
                      validator: _timeValidator,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TimeField(
                      controller: _endController,
                      decoration: const InputDecoration(
                        labelText: 'Hora fin',
                        hintText: 'HH:mm',
                        border: OutlineInputBorder(),
                      ),
                      validator: _timeValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PriceField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = ThousandsFormat.parsePrice((value ?? '').trim());
                  return (parsed == null || parsed < 0) ? 'Ingresá un precio válido.' : null;
                },
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
