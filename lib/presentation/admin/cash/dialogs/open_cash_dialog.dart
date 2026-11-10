import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/option_chip.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/cash/cash.dart';
import '../../../../domain/repositories/cash_repository.dart';
import '../../club_config/widgets/price_field.dart';
import '../cash_common.dart';

/// Abre una caja. [points] son los puestos activos; devuelve true si abrió.
Future<bool> showOpenCashDialog(BuildContext context, {required List<CashPoint> points, int? selectedId}) async {
  final opened = await showDialog<bool>(context: context, builder: (_) => _OpenCashDialog(points: points, selectedId: selectedId));
  return opened ?? false;
}

class _OpenCashDialog extends StatefulWidget {
  const _OpenCashDialog({required this.points, this.selectedId});

  final List<CashPoint> points;
  final int? selectedId;

  @override
  State<_OpenCashDialog> createState() => _OpenCashDialogState();
}

class _OpenCashDialogState extends State<_OpenCashDialog> {
  final _amount = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  CashPoint? _point;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final closed = widget.points.where((point) => !point.isOpen);
    final preferred = closed.where((point) => point.id == widget.selectedId).firstOrNull;
    _select(preferred ?? closed.firstOrNull);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _select(CashPoint? point) {
    _point = point;
    final left = point?.lastClose?.leftAmount;
    _amount.text = left == null ? '' : ThousandsFormat.formatPrice(left);
  }

  Future<void> _open() async {
    final point = _point;
    if (point == null || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await sl<CashRepository>().openShift(point.id, ThousandsFormat.parsePrice(_amount.text) ?? 0);
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
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final left = _point?.lastClose?.leftAmount;

    return AlertDialog(
      title: const Text('Abrir caja'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Puesto', style: labelStyle),
              const SizedBox(height: 6),
              for (final point in widget.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OptionChip(
                      label: point.name,
                      subtitle: point.isOpen ? 'Ya está abierta' : cashSpacesLabel(point.spaces),
                      selected: _point?.id == point.id,
                      onTap: point.isOpen ? null : () => setState(() => _select(point)),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text('Monto inicial en efectivo', style: labelStyle),
              const SizedBox(height: 6),
              PriceField(
                controller: _amount,
                decoration: const InputDecoration(prefixText: '\$ ', border: OutlineInputBorder()),
                validator: (value) => ThousandsFormat.parsePrice(value ?? '') == null ? 'Poné el monto. Si no hay efectivo, 0.' : null,
              ),
              if (left != null) ...[
                const SizedBox(height: 6),
                Text('El último cierre dejó ${cashMoney(left)} en esta caja. Si contás otro monto, se registra la diferencia.', style: labelStyle),
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
        FilledButton(onPressed: _saving || _point == null ? null : _open, child: const Text('Abrir caja')),
      ],
    );
  }
}
