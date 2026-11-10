import 'package:flutter/material.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/option_chip.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/thousands_format.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../club_config/widgets/price_field.dart';

const _reasons = ['Se suspendió el turno', 'Lo pidió el cliente', 'Cobro duplicado', 'Otro'];

/// Resultado de la devolución pedida.
enum RefundOutcome {
  /// Ya quedó en el cobro y queda una parte sin devolver.
  applied,

  /// Ya quedó en el cobro y lo devolvió entero.
  appliedWhole,

  /// Mercado Pago todavía no la confirmó: llega sola en unos minutos.
  pending,
}

/// Pide monto y motivo y devuelve un cobro online por Mercado Pago. Devuelve
/// null si se canceló.
///
/// [remaining]: lo que queda del cobro sin devolver. [wholeOnly]: una
/// inscripción a torneo se devuelve entera.
Future<RefundOutcome?> showRefundPaymentDialog(
  BuildContext context, {
  required PaymentRecordKind kind,
  required int paymentId,
  required String subject,
  required DateTime date,
  required double amount,
  required double remaining,
  bool wholeOnly = false,
}) {
  return showDialog<RefundOutcome>(
    context: context,
    builder: (_) => _RefundPaymentDialog(
      kind: kind,
      paymentId: paymentId,
      subject: subject,
      date: date,
      amount: amount,
      remaining: remaining,
      wholeOnly: wholeOnly,
    ),
  );
}

class _RefundPaymentDialog extends StatefulWidget {
  const _RefundPaymentDialog({
    required this.kind,
    required this.paymentId,
    required this.subject,
    required this.date,
    required this.amount,
    required this.remaining,
    required this.wholeOnly,
  });

  final PaymentRecordKind kind;
  final int paymentId;
  final String subject;
  final DateTime date;
  final double amount;
  final double remaining;
  final bool wholeOnly;

  @override
  State<_RefundPaymentDialog> createState() => _RefundPaymentDialogState();
}

class _RefundPaymentDialogState extends State<_RefundPaymentDialog> {
  final _detail = TextEditingController();
  final _partAmount = TextEditingController();
  bool _whole = true;
  String? _reason;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _partAmount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _detail.dispose();
    _partAmount.dispose();
    super.dispose();
  }

  double? get _part => ThousandsFormat.parsePrice(_partAmount.text);

  String? get _amountError {
    if (_whole || _partAmount.text.isEmpty) return null;
    final part = _part;
    if (part == null || part <= 0) return 'Ingresá un monto';
    if (part > widget.remaining + 0.009) return 'Hasta \$ ${ThousandsFormat.formatPrice(widget.remaining)}';
    return null;
  }

  bool get _valid {
    if (_reason == null || (_reason == 'Otro' && _detail.text.trim().isEmpty)) return false;
    return _whole || (_part != null && _amountError == null);
  }

  String get _fullReason {
    final detail = _detail.text.trim();
    if (_reason == 'Otro') return detail;
    return detail.isEmpty ? _reason! : '$_reason: $detail';
  }

  double get _refundAmount => _whole ? widget.remaining : _part!;

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await sl<PaymentRepository>().refundPayment(
      widget.kind,
      widget.paymentId,
      amount: _whole ? null : _part,
      reason: _fullReason,
    );
    if (!mounted) return;
    switch (result) {
      case Right(:final value):
        final whole = _whole || _part! >= widget.remaining - 0.009;
        Navigator.of(context).pop(!value ? RefundOutcome.pending : whole ? RefundOutcome.appliedWhole : RefundOutcome.applied);
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
    final money = textTheme.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final alreadyRefunded = widget.amount - widget.remaining;

    return AlertDialog(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Devolver cobro'),
        Text(widget.subject, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ]),
      content: SizedBox(
        width: 460,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text('Mercado Pago, $_when', style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))),
                Text('\$ ${ThousandsFormat.formatPrice(widget.amount)}', style: money),
              ]),
              if (alreadyRefunded > 0.009) ...[
                const SizedBox(height: 4),
                Text('Ya se devolvieron \$ ${ThousandsFormat.formatPrice(alreadyRefunded)}', style: label),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          Text('Cuánto', style: label),
          const SizedBox(height: 6),
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: OptionChip(
                  label: 'Todo · \$ ${ThousandsFormat.formatPrice(widget.remaining)}',
                  selected: _whole,
                  onTap: _saving ? null : () => setState(() => _whole = true),
                ),
              ),
              if (!widget.wholeOnly) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OptionChip(
                    label: 'Una parte',
                    selected: !_whole,
                    onTap: _saving ? null : () => setState(() => _whole = false),
                  ),
                ),
              ],
            ]),
          ),
          if (widget.wholeOnly) ...[
            const SizedBox(height: 6),
            Text('Una inscripción a torneo se devuelve entera.', style: label),
          ],
          if (!_whole) ...[
            const SizedBox(height: 12),
            PriceField(
              controller: _partAmount,
              isDense: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                prefixText: '\$ ',
                hintText: 'Monto a devolver',
                errorText: _amountError,
              ),
            ),
          ],
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
          const SizedBox(height: 12),
          Text(
            'La plata vuelve a la cuenta de Mercado Pago de quien pagó, desde la cuenta del club. Al cliente le llega un aviso.',
            style: label,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: textTheme.bodySmall?.copyWith(color: scheme.error)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
          onPressed: _saving || !_valid ? null : _submit,
          child: Text(_saving
              ? 'Devolviendo…'
              : _valid
                  ? 'Devolver \$ ${ThousandsFormat.formatPrice(_refundAmount)}'
                  : 'Devolver'),
        ),
      ],
    );
  }
}
