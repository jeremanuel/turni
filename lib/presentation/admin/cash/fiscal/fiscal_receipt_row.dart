import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/services/data_changes.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../domain/entities/fiscal/fiscal.dart';
import '../../../../domain/repositories/fiscal_repository.dart';
import '../cash_common.dart';
import 'fiscal_receiver_dialog.dart';

/// Fila "Comprobante" de un cobro: qué comprobante sale y a nombre de quién.
/// "Cambiar" guarda los datos fiscales en la ficha del cliente, que es de
/// donde los toma la factura. Si el club no factura no ocupa lugar.
class FiscalReceiptRow extends StatefulWidget {
  const FiscalReceiptRow({super.key, required this.clientId, required this.amount});

  /// Cliente del turno; sin cliente sale a Consumidor final.
  final int? clientId;
  final double amount;

  @override
  State<FiscalReceiptRow> createState() => _FiscalReceiptRowState();
}

class _FiscalReceiptRowState extends State<FiscalReceiptRow> with ReloadOnDataChange {
  FiscalPreview? _preview;
  Timer? _debounce;

  static const _canChange = [
    Permissions.FACTURACION_EMITIR,
    Permissions.CLIENTES_EDITAR,
    Permissions.AGENDA_COBRAR,
    Permissions.PAGOS_REGISTRAR,
    Permissions.TORNEOS_EDITAR,
  ];

  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.clubConfig, DataTopic.cash};

  @override
  void onDataChanged(DataChange change) => _schedule();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(FiscalReceiptRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientId != widget.clientId || oldWidget.amount != widget.amount) _schedule();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _load() async {
    final result = await sl<FiscalRepository>().preview(clientId: widget.clientId, amount: widget.amount);
    if (!mounted) return;
    // Sin permiso o sin red no se muestra: la factura igual la arma el servidor.
    setState(() => _preview = switch (result) {
          Right(:final value) => value,
          Left() => null,
        });
  }

  Future<void> _change(FiscalPreview preview) async {
    final clientId = widget.clientId!;
    final receiver = preview.receiver;
    final saved = await showFiscalReceiverDialog(
      context,
      title: '¿A nombre de quién?',
      subtitle: 'Se guarda en la ficha del cliente y se usa en sus próximos comprobantes.',
      initial: receiver != null && !receiver.isConsumerFinal ? receiver : null,
      allowConsumerFinal: false,
      warning: preview.problem,
      confirmLabel: 'Usar',
      onSubmit: (input, _) async {
        final result = await sl<FiscalRepository>().saveClientData(clientId, input);
        return switch (result) {
          Right() => null,
          Left(:final failure) => failure.message,
        };
      },
    );
    if (saved) _load();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    if (preview == null || !preview.enabled) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final problem = preview.problem;
    final receiverLabel = preview.receiver?.label ?? 'Consumidor final';
    final when = preview.automatic ? 'Sale solo al cobrar' : 'Queda por emitir en Caja › Comprobantes';
    final canChange = widget.clientId != null && Permissions.canAny(_canChange);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 4),
        decoration: BoxDecoration(
          border: Border.all(color: problem != null ? StatusTone.warning(scheme).foreground : scheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Comprobante', style: muted),
              Text('${preview.documentLabel ?? 'Factura'} · $receiverLabel', key: const ValueKey('fiscal.receipt.title'), style: textTheme.titleSmall),
              Text(
                problem != null ? '$problem Si no lo tenés ahora, queda en Faltan datos.' : when,
                style: problem != null ? muted?.copyWith(color: StatusTone.warning(scheme).foreground) : muted,
              ),
            ]),
          ),
          if (canChange) TextButton(key: const ValueKey('fiscal.receipt.change'), onPressed: () => _change(preview), child: const Text('Cambiar')),
        ]),
      ),
    );
  }
}
