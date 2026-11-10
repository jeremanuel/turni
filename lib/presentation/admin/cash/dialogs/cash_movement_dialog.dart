import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/option_chip.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/repositories/cash_repository.dart';
import '../../club_config/widgets/price_field.dart';
import '../cash_common.dart';

const _categories = ['Limpieza', 'Mantenimiento', 'Proveedores', 'Sueldos', 'Otros'];

/// Gasto, retiro, ingreso o (con supervisión) ajuste de una caja abierta.
/// Devuelve true si se registró.
Future<bool> showCashMovementDialog(BuildContext context, {required String shiftId, required String pointName}) async {
  final saved = await showDialog<bool>(context: context, builder: (_) => _CashMovementDialog(shiftId: shiftId, pointName: pointName));
  return saved ?? false;
}

class _Kind {
  const _Kind(this.code, this.label, this.note, this.verb);

  final String code;
  final String label;
  final String note;
  final String verb;
}

const _expense = _Kind('EXPENSE', 'Gasto', 'Sale plata', 'Registrar gasto');
const _withdrawal = _Kind('WITHDRAWAL', 'Retiro', 'A administración', 'Registrar retiro');
const _deposit = _Kind('DEPOSIT', 'Ingreso', 'Entra plata', 'Registrar ingreso');
const _adjustment = _Kind('ADJUSTMENT', 'Ajuste', 'Corrige la caja', 'Registrar ajuste');

class _CashMovementDialog extends StatefulWidget {
  const _CashMovementDialog({required this.shiftId, required this.pointName});

  final String shiftId;
  final String pointName;

  @override
  State<_CashMovementDialog> createState() => _CashMovementDialogState();
}

class _CashMovementDialogState extends State<_CashMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _detail = TextEditingController();
  final _reason = TextEditingController();

  /// El mismo para todos los reintentos: el servidor no lo registra dos veces.
  final _requestId = cashRequestId();

  _Kind _kind = _expense;
  String _category = _categories.first;
  bool _negative = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _detail.dispose();
    _reason.dispose();
    super.dispose();
  }

  bool get _isExpense => _kind == _expense;
  bool get _isAdjustment => _kind == _adjustment;

  String get _concept {
    final detail = _detail.text.trim();
    if (!_isExpense) return detail;
    return detail.isEmpty ? _category : '$_category · $detail';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = ThousandsFormat.parsePrice(_amount.text)!;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await sl<CashRepository>().addMovement(
      widget.shiftId,
      kind: _kind.code,
      amount: _isAdjustment && _negative ? -amount : amount,
      concept: _concept,
      reason: _isAdjustment ? _reason.text.trim() : null,
      clientRequestId: _requestId,
    );
    if (!mounted) return;
    switch (result) {
      case Right():
        Navigator.of(context).pop(true);
      case Left(:final failure):
        setState(() {
          _saving = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final kinds = [_expense, _withdrawal, _deposit, if (Permissions.can(Permissions.CAJA_SUPERVISAR)) _adjustment];
    const gap = SizedBox(height: 14);

    return AlertDialog(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Registrar movimiento'),
        Text('En ${widget.pointName}', style: labelStyle),
      ]),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (final (index, kind) in kinds.indexed) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Expanded(child: OptionChip(label: kind.label, subtitle: kind.note, selected: _kind == kind, onTap: () => setState(() => _kind = kind))),
                  ],
                ]),
              ),
              gap,
              Text('Monto', style: labelStyle),
              const SizedBox(height: 6),
              PriceField(
                controller: _amount,
                decoration: const InputDecoration(prefixText: '\$ ', border: OutlineInputBorder()),
                validator: (value) => (ThousandsFormat.parsePrice(value ?? '') ?? 0) <= 0 ? 'Poné el monto.' : null,
              ),
              if (_isAdjustment) ...[
                gap,
                Wrap(spacing: 8, children: [
                  OptionChip(label: 'Suma', selected: !_negative, onTap: () => setState(() => _negative = false)),
                  OptionChip(label: 'Resta', selected: _negative, onTap: () => setState(() => _negative = true)),
                ]),
              ],
              if (_isExpense) ...[
                gap,
                Text('Categoría', style: labelStyle),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final category in _categories)
                    OptionChip(label: category, selected: _category == category, onTap: () => setState(() => _category = category)),
                ]),
              ],
              gap,
              Text(_isExpense ? 'Detalle (opcional)' : 'Detalle', style: labelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _detail,
                maxLength: 200,
                decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ''),
                validator: (value) => !_isExpense && (value ?? '').trim().isEmpty ? 'Contá de qué se trata.' : null,
              ),
              if (_isAdjustment) ...[
                gap,
                Text('Motivo', style: labelStyle),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _reason,
                  maxLength: 500,
                  decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ''),
                  validator: (value) => (value ?? '').trim().isEmpty ? 'El ajuste necesita un motivo.' : null,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_kind.verb)),
      ],
    );
  }
}
