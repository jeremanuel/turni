import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/presentation/components/links/entity_links.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../core/utils/repository_response.dart';
import '../../../../domain/entities/fiscal/fiscal.dart';
import '../../../../domain/repositories/fiscal_repository.dart';
import '../cash_common.dart';
import 'fiscal_common.dart';
import 'fiscal_receiver_dialog.dart';

/// Acciones de un comprobante que no salió: las usan la fila de la lista y el
/// detalle. Devuelven true si algo cambió.
abstract final class FiscalDocumentActionsRunner {
  static FiscalRepository get _repository => sl<FiscalRepository>();

  static Future<bool> _run(BuildContext context, Future<RepositoryResponse<FiscalDocument>> request, String done) async {
    final result = await request;
    if (!context.mounted) return false;
    switch (result) {
      case Right():
        SnackbarsFunctions.showSuccessSnackbar(context, done);
        return true;
      case Left(:final failure):
        SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
        return false;
    }
  }

  static Future<bool> issue(BuildContext context, FiscalDocument doc) => _run(context, _repository.issue(doc.id), 'Comprobante en cola para ARCA');

  static Future<bool> retry(BuildContext context, FiscalDocument doc) => _run(context, _repository.retry(doc.id), 'Se vuelve a enviar');

  static Future<bool> correct(BuildContext context, FiscalDocument doc, {List<FiscalOption> conditions = fiscalIvaConditions}) {
    final rejected = doc.status == 'REJECTED' || doc.status == 'NEEDS_DATA';
    return showFiscalReceiverDialog(
      context,
      title: 'Corregir comprobante',
      subtitle: '${doc.documentLabel} · ${cashMoney(doc.total)}',
      initial: doc.receiver,
      rejection: doc.status == 'REJECTED' ? doc.errors.firstOrNull : null,
      warning: doc.status == 'NEEDS_DATA' ? doc.errors.firstOrNull : null,
      offerSaveToClient: doc.clientId != null,
      conditions: conditions,
      confirmLabel: rejected ? 'Reintentar' : 'Guardar',
      onSubmit: (receiver, saveToClient) async {
        final result = await _repository.correct(doc.id, receiver, saveToClient: saveToClient);
        return switch (result) {
          Right() => null,
          Left(:final failure) => failure.message,
        };
      },
    );
  }

  static Future<bool> cancel(BuildContext context, FiscalDocument doc) async {
    final reason = await showDialog<String>(context: context, builder: (_) => _CancelDialog(doc: doc));
    if (reason == null || !context.mounted) return false;
    return _run(context, _repository.cancel(doc.id, reason), 'Comprobante cancelado');
  }
}

/// Detalle de un comprobante: receptor, ítems, importes, CAE y lo que se puede
/// hacer con él. Devuelve true si cambió algo.
Future<bool> showFiscalDocumentDialog(BuildContext context, String id, {List<FiscalOption> conditions = fiscalIvaConditions}) async {
  final changed = await showDialog<bool>(context: context, builder: (_) => _FiscalDocumentDialog(id: id, conditions: conditions));
  return changed ?? false;
}

class _FiscalDocumentDialog extends StatefulWidget {
  const _FiscalDocumentDialog({required this.id, required this.conditions});

  final String id;
  final List<FiscalOption> conditions;

  @override
  State<_FiscalDocumentDialog> createState() => _FiscalDocumentDialogState();
}

class _FiscalDocumentDialogState extends State<_FiscalDocumentDialog> {
  late String _id = widget.id;
  FiscalDocument? _doc;
  DomainError? _error;
  bool _changed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await sl<FiscalRepository>().getDocument(_id);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Right(:final value):
          _doc = value;
          _error = null;
        case Left(:final failure):
          _error = failure;
      }
    });
  }

  Future<void> _act(Future<bool> Function() action) async {
    setState(() => _busy = true);
    final changed = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _changed |= changed;
    });
    if (changed) _load();
  }

  void _open(String id) {
    setState(() {
      _id = id;
      _doc = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final canEmit = Permissions.can(Permissions.FACTURACION_EMITIR);

    Widget body;
    if (doc == null) {
      body = _error != null ? CashMessage(_error!.message, onRetry: _load) : const LinearProgressIndicator();
    } else {
      final reason = fiscalStatusReason(doc);
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        if (doc.status == 'REJECTED' || doc.status == 'NEEDS_DATA' || doc.status == 'NEEDS_CONFIG' || doc.status == 'BLOCKED') ...[
          FiscalNotice(tone: fiscalStatusTone(scheme, doc.status), title: doc.statusLabel, text: reason ?? ''),
          const SizedBox(height: 14),
        ],
        _Facts(rows: [
          ('Cliente', doc.clientId != null ? ClientLink(clientId: doc.clientId!, name: doc.clientName ?? 'Cliente') : Text(doc.receiver.legalName ?? 'Sin cliente')),
          ('A nombre de', Text(doc.receiver.label)),
          if (!doc.receiver.isConsumerFinal) ('Condición', Text(doc.receiver.ivaConditionLabel ?? '')),
          if (doc.issueDate != null) ('Fecha', Text(fiscalDate(doc.issueDate!))),
          if (doc.cancelReason != null) ('Motivo', Text(doc.cancelReason!)),
        ]),
        const SizedBox(height: 14),
        _Amounts(doc: doc),
        if (doc.cae != null) ...[
          const SizedBox(height: 14),
          _Facts(rows: [
            ('CAE', Text(doc.cae!, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]))),
            if (doc.caeDue != null) ('Vence', Text(fiscalDate(doc.caeDue!))),
          ]),
        ],
        if (doc.observations.isNotEmpty) ...[
          const SizedBox(height: 14),
          FiscalNotice(tone: StatusTone.neutral(scheme), title: 'Observación de ARCA', text: doc.observations.join('\n')),
        ],
        if (doc.creditLegend) ...[
          const SizedBox(height: 8),
          Text('Lleva la leyenda de crédito fiscal para el monotributista.', style: muted),
        ],
        if (doc.related != null) ...[
          const SizedBox(height: 14),
          _RelatedRow(label: doc.isCreditNote ? 'Anula' : 'Corresponde a', doc: doc.related!, onOpen: () => _open(doc.related!.id)),
        ],
        for (final note in doc.creditNotes) ...[
          const SizedBox(height: 8),
          _RelatedRow(label: 'Nota de crédito', doc: note, onOpen: () => _open(note.id)),
        ],
      ]);
    }

    return AlertDialog(
      title: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc?.documentLabel ?? 'Comprobante'),
            if (doc != null) Text(fiscalNumber(doc), style: muted?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
        ),
        if (doc != null) CashTag(label: doc.statusLabel, tone: fiscalStatusTone(scheme, doc.status)),
      ]),
      content: SizedBox(width: 480, child: SingleChildScrollView(child: body)),
      actions: [
        if (doc != null && canEmit && doc.can.cancel)
          TextButton(onPressed: _busy ? null : () => _act(() => FiscalDocumentActionsRunner.cancel(context, doc)), child: const Text('Cancelar comprobante')),
        TextButton(onPressed: () => Navigator.of(context).pop(_changed), child: const Text('Cerrar')),
        if (doc != null && canEmit && doc.can.correct)
          OutlinedButton(
            onPressed: _busy ? null : () => _act(() => FiscalDocumentActionsRunner.correct(context, doc, conditions: widget.conditions)),
            child: Text(doc.status == 'REJECTED' ? 'Corregir y reintentar' : 'Corregir'),
          ),
        if (doc != null && canEmit && doc.can.issue)
          FilledButton(key: const ValueKey('fiscal.detail.issue'), onPressed: _busy ? null : () => _act(() => FiscalDocumentActionsRunner.issue(context, doc)), child: const Text('Emitir')),
        if (doc != null && canEmit && doc.can.retry)
          FilledButton(onPressed: _busy ? null : () => _act(() => FiscalDocumentActionsRunner.retry(context, doc)), child: const Text('Reintentar')),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.rows});

  final List<(String, Widget)> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(children: [
      for (final (label, value) in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant))),
            Expanded(child: DefaultTextStyle.merge(style: const TextStyle(fontSize: 13.5), child: value)),
          ]),
        ),
    ]);
  }
}

class _Amounts extends StatelessWidget {
  const _Amounts({required this.doc});

  final FiscalDocument doc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const tabular = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
    Widget line(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w500 : null))),
            Text(value, style: tabular.copyWith(fontWeight: bold ? FontWeight.w500 : null)),
          ]),
        );
    final discriminates = doc.ivaBreakdown.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 13.5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final item in doc.items) line(item.quantity == 1 ? item.description : '${item.description} × ${item.quantity.toStringAsFixed(0)}', cashMoney(item.subtotal)),
          Divider(height: 14, color: scheme.outlineVariant),
          if (discriminates) ...[
            line('Neto gravado', cashMoney(doc.netTaxed)),
            for (final iva in doc.ivaBreakdown) line('IVA ${iva.label}', cashMoney(iva.amount)),
          ],
          if (doc.exempt > 0) line('Exento', cashMoney(doc.exempt)),
          if (doc.notTaxed > 0) line('No gravado', cashMoney(doc.notTaxed)),
          line('Total', cashMoney(doc.total), bold: true),
        ]),
      ),
    );
  }
}

class _RelatedRow extends StatelessWidget {
  const _RelatedRow({required this.label, required this.doc, required this.onOpen});

  final String label;
  final FiscalDocument doc;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            Text('${doc.documentLabel} ${fiscalNumber(doc)} · ${fiscalAmount(doc)}', style: const TextStyle(fontSize: 13.5)),
            Text(doc.statusLabel, style: TextStyle(fontSize: 12, color: fiscalStatusTone(scheme, doc.status).foreground)),
          ]),
        ),
        TextButton(onPressed: onOpen, child: const Text('Ver')),
      ]),
    );
  }
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.doc});

  final FiscalDocument doc;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return AlertDialog(
      title: const Text('Cancelar comprobante'),
      content: SizedBox(
        width: 420,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text(
            'No salió a ARCA, así que se cancela sin nota de crédito. El cobro queda registrado igual.'
            '${widget.doc.isCreditNote ? '' : ' Si el cobro hay que facturarlo, no lo canceles: corregilo.'}',
            style: muted,
          ),
          const SizedBox(height: 14),
          Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('Motivo', style: muted)),
          TextField(controller: _reason, maxLength: 300, decoration: const InputDecoration(border: OutlineInputBorder()), onChanged: (_) => setState(() {})),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Volver')),
        FilledButton(
          onPressed: _reason.text.trim().isEmpty ? null : () => Navigator.of(context).pop(_reason.text.trim()),
          child: const Text('Cancelar comprobante'),
        ),
      ],
    );
  }
}
