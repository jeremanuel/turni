import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/chips/filter_chip_interval_date.dart';
import '../../../core/presentation/components/links/entity_links.dart';
import '../../../core/services/data_changes.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../domain/entities/cash/cash_reconciliation.dart';
import '../../../domain/repositories/cash_repository.dart';
import '../club_config/widgets/admin_data_table.dart';
import 'cash_common.dart';

/// Conciliación: cada cobro online del período contra lo que informó Mercado Pago
/// (bruto, devoluciones y comisiones). Solo con `caja.conciliar`.
class CashReconciliationView extends StatefulWidget {
  const CashReconciliationView({super.key});

  @override
  State<CashReconciliationView> createState() => _CashReconciliationViewState();
}

class _CashReconciliationViewState extends State<CashReconciliationView> with ReloadOnDataChange, AutomaticKeepAliveClientMixin {
  final _repository = sl<CashRepository>();
  CashReconciliation? _data;
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month - 1, DateTime.now().day);
  DateTime _to = DateTime.now();
  bool _onlyDifferences = false;
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.cash, DataTopic.payments};

  @override
  void onDataChanged(DataChange change) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _repository.getReconciliation(from: _from, to: _to);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Right(:final value):
          _data = value;
          _error = null;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final data = _data;
    final rows = data == null ? const <ReconciliationRow>[] : [for (final row in data.rows) if (!_onlyDifferences || !row.matches) row];

    return ListView(
      padding: EdgeInsets.all(ResponsiveBuilder.isMobile(context) ? 16 : 24),
      children: [
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FilterChipIntervalDate(
            initialSuggestion: 2,
            label: 'Período',
            withSuggesttions: true,
            onApply: (interval) {
              _from = interval.initialDate ?? _from;
              _to = interval.endDate ?? _to;
              _load();
            },
          ),
          FilterChip(
            label: const Text('Con diferencias'),
            selected: _onlyDifferences,
            showCheckmark: false,
            onSelected: (value) => setState(() => _onlyDifferences = value),
          ),
        ]),
        const SizedBox(height: 16),
        if (data != null) ...[
          CashStats(stats: [
            CashStat('Neto según Mercado Pago', cashMoney(data.provider.net), note: 'Cobrado menos devoluciones y comisiones'),
            CashStat('Neto en el libro', cashMoney(data.ledger.net)),
            CashStat('Comisiones', cashMoney(data.provider.fees), note: 'Mercado Pago y Turni'),
            CashStat('Cobros con diferencias', '${data.withDifferences} de ${data.payments}'),
          ]),
          const SizedBox(height: 16),
        ],
        if (_error != null)
          CashMessage(_error!, onRetry: _load)
        else if (data == null || (_loading && rows.isEmpty))
          const LinearProgressIndicator()
        else if (rows.isEmpty)
          CashMessage(_onlyDifferences ? 'Todos los cobros de este período cuadran.' : 'No hay cobros online en este período.')
        else
          AdminTableCard(child: _ReconciliationTable(rows: rows)),
        const SizedBox(height: 12),
        Text(
          'Mercado Pago se consulta todos los días y cada vez que se devuelve un cobro. '
          'Si un cobro no cuadra, se corrige solo en la próxima consulta; si sigue sin cuadrar, revisalo en Mercado Pago.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ReconciliationTable extends StatelessWidget {
  const _ReconciliationTable({required this.rows});

  final List<ReconciliationRow> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    // Cifra de Mercado Pago, con la del libro debajo cuando no coinciden.
    Widget figure(double? provider, double ledger, {bool differs = false}) {
      if (provider == null) return Text(cashMoney(ledger));
      if (!differs) return Text(cashMoney(provider));
      return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(cashMoney(provider), style: TextStyle(color: scheme.error)),
        Text('Libro: ${cashMoney(ledger)}', style: muted),
      ]);
    }

    return AdminDataTable(
      columns: const ['Fecha', 'Cliente', 'Cobrado', 'Devuelto', 'Comisiones', 'Neto', 'Estado'],
      defaultColumnWidth: const FlexColumnWidth(),
      rows: [
        for (final row in rows)
          [
            HoverLink(
              onTap: row.sessionId == null ? null : () => openSession(context, row.sessionId!),
              builder: (context, hovered) => Text(
                '${cashDay(row.date)} ${cashTime(row.date)}',
                style: row.sessionId == null ? null : linkStyle(TextStyle(color: scheme.primary), hovered),
              ),
            ),
            ClientLink(clientId: row.clientId, name: row.clientName),
            figure(row.provider?.gross, row.ledger.gross, differs: row.differences.contains(ReconciliationDifference.gross)),
            figure(row.provider?.refunded, row.ledger.refunded, differs: row.differences.contains(ReconciliationDifference.refunded)),
            figure(
              row.provider?.fees,
              row.ledger.fees,
              differs: row.differences.contains(ReconciliationDifference.providerFee) || row.differences.contains(ReconciliationDifference.platformFee),
            ),
            Text(cashMoney(row.provider?.net ?? row.ledger.net)),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 4, runSpacing: 4, children: [
                if (row.matches)
                  CashTag(label: 'Cuadra', tone: StatusTone.success(scheme))
                else
                  for (final difference in row.differences)
                    CashTag(
                      label: difference.label,
                      tone: difference == ReconciliationDifference.noProviderData ? StatusTone.warning(scheme) : StatusTone.danger(scheme),
                    ),
                if (row.status == 'CHARGED_BACK') CashTag(label: 'Contracargo', tone: StatusTone.danger(scheme)),
              ]),
            ),
          ],
      ],
    );
  }
}
