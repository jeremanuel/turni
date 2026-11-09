import 'package:flutter/material.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/option_chip.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/thousands_format.dart';
import '../../../domain/repositories/payment_repository.dart';

const _reasons = ['Error de carga', 'Se devolvió la plata', 'Otro'];

/// Pide el motivo y anula un cobro. Devuelve true si se anuló.
Future<bool> showVoidPaymentDialog(
  BuildContext context, {
  required PaymentRecordKind kind,
  required int paymentId,
  required String subject,
  required String method,
  required DateTime date,
  required double amount,
}) async {
  final voided = await showDialog<bool>(
    context: context,
    builder: (_) => _VoidPaymentDialog(kind: kind, paymentId: paymentId, subject: subject, method: method, date: date, amount: amount),
  );
  return voided ?? false;
}

class _VoidPaymentDialog extends StatefulWidget {
  const _VoidPaymentDialog({required this.kind, required this.paymentId, required this.subject, required this.method, required this.date, required this.amount});

  final PaymentRecordKind kind;
  final int paymentId;
  final String subject;
  final String method;
  final DateTime date;
  final double amount;

  @override
  State<_VoidPaymentDialog> createState() => _VoidPaymentDialogState();
}

class _VoidPaymentDialogState extends State<_VoidPaymentDialog> {
  final _detail = TextEditingController();
  String? _reason;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  bool get _valid => _reason != null && (_reason != 'Otro' || _detail.text.trim().isNotEmpty);

  String get _fullReason {
    final detail = _detail.text.trim();
    if (_reason == 'Otro') return detail;
    return detail.isEmpty ? _reason! : '$_reason: $detail';
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await sl<PaymentRepository>().voidPayment(widget.kind, widget.paymentId, _fullReason);
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

  String get _when {
    final d = widget.date;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} a las ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return AlertDialog(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Anular cobro'),
        Text(widget.subject, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ]),
      content: SizedBox(
        width: 460,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(child: Text('${widget.method}, $_when', style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))),
              Text('\$ ${ThousandsFormat.formatPrice(widget.amount)}', style: textTheme.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
          ),
          const SizedBox(height: 16),
          Text('Motivo', style: label),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final reason in _reasons)
              IntrinsicWidth(child: OptionChip(label: reason, selected: _reason == reason, onTap: _saving ? null : () => setState(() => _reason = reason))),
          ]),
          const SizedBox(height: 16),
          Text('Detalle', style: label),
          const SizedBox(height: 6),
          TextField(
            controller: _detail,
            enabled: !_saving,
            maxLength: 400,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              border: const OutlineInputBorder(),
              hintText: _reason == 'Otro' ? 'Contá qué pasó' : 'Opcional',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: textTheme.bodySmall?.copyWith(color: scheme.error)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
          onPressed: _saving || !_valid ? null : _submit,
          child: Text(_saving ? 'Anulando…' : 'Anular cobro'),
        ),
      ],
    );
  }
}
