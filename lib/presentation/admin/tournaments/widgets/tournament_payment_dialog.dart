import 'package:flutter/material.dart';

import '../../../../core/presentation/components/inputs/option_chip.dart';
import '../../../../domain/entities/payment/payment_method.dart';
import '../../cash/widgets/cash_entry_row.dart';
import '../../session_manager_screen/widgets/side_panel/payment_view.dart' show PaymentMethods;

/// Pide con qué medio se pagó una inscripción y, si el club usa caja, a qué
/// puesto entra. Devuelve null si se cancela.
Future<({int methodId, int? cashAccountId})?> showTournamentPaymentDialog(BuildContext context, {required String message}) {
  return showDialog<({int methodId, int? cashAccountId})>(context: context, builder: (_) => _TournamentPaymentDialog(message: message));
}

class _TournamentPaymentDialog extends StatefulWidget {
  const _TournamentPaymentDialog({required this.message});

  final String message;

  @override
  State<_TournamentPaymentDialog> createState() => _TournamentPaymentDialogState();
}

class _TournamentPaymentDialogState extends State<_TournamentPaymentDialog> {
  List<PaymentMethod>? _methods;
  PaymentMethod? _method;
  CashEntrySelection _entry = const CashEntrySelection();

  @override
  void initState() {
    super.initState();
    PaymentMethods.load().then((methods) {
      if (!mounted) return;
      setState(() {
        _methods = methods;
        _method = methods.first;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final method = _method;
    return AlertDialog(
      title: const Text('Registrar pago en el club'),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.message),
          const SizedBox(height: 14),
          Text('Medio de pago', style: labelStyle),
          const SizedBox(height: 6),
          if (_methods == null)
            const LinearProgressIndicator()
          else
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final option in _methods!)
                OptionChip(label: option.name, selected: option.paymentMethodId == method?.paymentMethodId, onTap: () => setState(() => _method = option)),
            ]),
          const SizedBox(height: 8),
          CashEntryRow(method: method, onChanged: (entry) => setState(() => _entry = entry)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: method == null || _entry.blocked
              ? null
              : () => Navigator.of(context).pop((methodId: method.paymentMethodId, cashAccountId: _entry.cashAccountId)),
          child: const Text('Registrar pago'),
        ),
      ],
    );
  }
}
