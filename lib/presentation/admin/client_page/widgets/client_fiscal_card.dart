import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/services/fiscal_status.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../domain/entities/fiscal/fiscal.dart';
import '../../../../domain/repositories/fiscal_repository.dart';
import '../../cash/fiscal/fiscal_receiver_dialog.dart';

/// Datos de facturación del cliente: con qué documento y condición le salen
/// los comprobantes. Solo si el club factura con ARCA.
class ClientFiscalCard extends StatefulWidget {
  const ClientFiscalCard({super.key, required this.clientId});

  final int clientId;

  @override
  State<ClientFiscalCard> createState() => _ClientFiscalCardState();
}

class _ClientFiscalCardState extends State<ClientFiscalCard> {
  ClientFiscalData? _data;
  bool _loaded = false;

  static const _canEdit = [Permissions.FACTURACION_EMITIR, Permissions.CLIENTES_EDITAR];

  @override
  void initState() {
    super.initState();
    FiscalStatus.enabled.addListener(_onStatus);
    if (FiscalStatus.enabled.value) _load();
  }

  @override
  void dispose() {
    FiscalStatus.enabled.removeListener(_onStatus);
    super.dispose();
  }

  void _onStatus() {
    if (FiscalStatus.enabled.value && !_loaded) _load();
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final result = await sl<FiscalRepository>().getClientData(widget.clientId);
    if (!mounted) return;
    setState(() {
      _loaded = true;
      if (result case Right(:final value)) _data = value;
    });
  }

  Future<void> _edit() async {
    final saved = await showFiscalReceiverDialog(
      context,
      title: 'Datos de facturación',
      subtitle: _data?.name,
      initial: _data?.fiscalData,
      allowConsumerFinal: false,
      onSubmit: (input, _) async {
        final result = await sl<FiscalRepository>().saveClientData(widget.clientId, input);
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
    if (!FiscalStatus.enabled.value || !_loaded || _data == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = TextStyle(fontSize: 13, height: 1.4, color: scheme.onSurfaceVariant);
    final receiver = _data!.fiscalData;
    final canEdit = Permissions.canAny(_canEdit);

    return Card(
      key: const ValueKey('client.fiscal'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text('Datos de facturación', style: textTheme.titleMedium)),
            if (canEdit) IconButton(tooltip: 'Editar datos de facturación', icon: const Icon(Icons.edit_outlined, size: 18), onPressed: _edit),
          ]),
          const SizedBox(height: 12),
          if (receiver == null || receiver.isConsumerFinal)
            Text('Sin datos: sus comprobantes salen a Consumidor final.', style: muted)
          else ...[
            Text(receiver.legalName ?? receiver.ivaConditionLabel ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text('${receiver.docTypeLabel ?? ''} ${receiver.docNumber}', style: muted),
            Text(receiver.ivaConditionLabel ?? '', style: muted),
            if (receiver.email != null) Text(receiver.email!, style: muted),
          ],
        ]),
      ),
    );
  }
}
