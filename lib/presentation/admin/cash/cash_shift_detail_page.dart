import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../core/services/data_changes.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../domain/entities/cash/cash.dart';
import '../../../domain/repositories/cash_repository.dart';
import '../club_config/widgets/admin_data_table.dart';
import 'cash_common.dart';
import 'dialogs/cash_movement_dialog.dart';
import 'dialogs/close_cash_dialog.dart';

/// Una caja, abierta o cerrada: de dónde sale el efectivo.
class CashShiftDetailPage extends StatefulWidget {
  const CashShiftDetailPage({super.key, required this.shiftId});

  final String shiftId;

  @override
  State<CashShiftDetailPage> createState() => _CashShiftDetailPageState();
}

class _CashShiftDetailPageState extends State<CashShiftDetailPage> with ReloadOnDataChange {
  final _repository = sl<CashRepository>();
  CashShift? _shift;
  double _tolerance = 0;
  List<CashMovement> _movements = const [];
  String? _cursor;
  String? _error;
  bool _loadingMore = false;
  Timer? _debounce;

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
    final shiftRequest = _repository.getShift(widget.shiftId);
    final movementsRequest = _repository.getMovements(CashListFilters(shiftId: widget.shiftId));
    final overviewRequest = _repository.getOverview();
    final shift = await shiftRequest;
    final movements = await movementsRequest;
    final overview = await overviewRequest;
    if (!mounted) return;
    setState(() {
      switch (shift) {
        case Right(:final value):
          _shift = value;
          _error = null;
        case Left(:final failure):
          _error = failure.message;
      }
      if (movements case Right(:final value)) {
        _movements = value.movements;
        _cursor = value.nextCursor;
      }
      if (overview case Right(:final value)) _tolerance = value.settings.tolerance;
    });
  }

  Future<void> _more() async {
    setState(() => _loadingMore = true);
    final result = await _repository.getMovements(CashListFilters(shiftId: widget.shiftId, cursor: _cursor));
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (result case Right(:final value)) {
        _movements = [..._movements, ...value.movements];
        _cursor = value.nextCursor;
      }
    });
  }

  Future<void> _addMovement(CashShift shift) async {
    if (await showCashMovementDialog(context, shiftId: shift.id, pointName: shift.accountName)) _load();
  }

  Future<void> _close(CashShift shift) async {
    final closed = await showCloseCashDialog(context, shiftId: shift.id, pointName: shift.accountName, tolerance: _tolerance);
    if (!closed || !mounted) return;
    SnackbarsFunctions.showSuccessSnackbar(context, 'Caja cerrada');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shift = _shift;
    Widget body;
    if (shift == null) {
      body = _error != null ? Center(child: CashMessage(_error!, onRetry: _load)) : const LinearProgressIndicator();
    } else {
      body = _content(context, shift);
    }
    return Scaffold(backgroundColor: scheme.surfaceContainer, body: body);
  }

  Widget _content(BuildContext context, CashShift shift) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final totals = shift.totals;
    final mobile = ResponsiveBuilder.isMobile(context);

    final actions = shift.isOpen
        ? [
            if (Permissions.can(Permissions.CAJA_MOVIMIENTOS)) OutlinedButton(onPressed: () => _addMovement(shift), child: const Text('Registrar movimiento')),
            if (Permissions.can(Permissions.CAJA_OPERAR)) FilledButton(onPressed: () => _close(shift), child: const Text('Cerrar caja')),
          ]
        : const <Widget>[];

    return ListView(
      padding: EdgeInsets.all(mobile ? 16 : 24),
      children: [
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(shift.accountName, style: textTheme.titleLarge),
              CashTag(label: shift.isOpen ? 'Abierta' : 'Cerrada', tone: shift.isOpen ? StatusTone.success(scheme) : StatusTone.neutral(scheme)),
            ]),
            const SizedBox(height: 2),
            Text(_subtitle(shift), style: muted),
          ]),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ]),
        const SizedBox(height: 16),
        CashStats(stats: [
          CashStat('Inicial', cashMoney(shift.openingAmount)),
          if (totals != null) ...[
            CashStat('Cobros', cashMoney(totals.collected)),
            CashStat('Gastos', cashMoney(totals.expenses.abs())),
            CashStat('Retiros', cashMoney(totals.withdrawals.abs())),
          ],
          CashStat('Efectivo esperado', shift.expectedAmount == null ? '—' : cashMoney(shift.expectedAmount!), note: shift.expectedAmount == null ? 'Arqueo ciego' : null),
          if (!shift.isOpen) ...[
            CashStat('Contado', cashMoney(shift.countedAmount ?? 0)),
            CashStat('Diferencia', cashSigned(shift.difference ?? 0)),
          ],
        ]),
        if (shift.note != null && shift.note!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Nota', style: muted),
                const SizedBox(height: 4),
                Text(shift.note!),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_movements.isEmpty)
          const CashMessage('Todavía no hay movimientos en esta caja.')
        else
          AdminTableCard(child: CashMovementsTable(movements: _movements)),
        if (_cursor != null) ...[
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: _loadingMore ? null : _more, child: Text(_loadingMore ? 'Cargando…' : 'Ver más'))),
        ],
        if (shift.otherMethods.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Otros medios en este período', style: textTheme.titleSmall),
          Text('Se muestran para control. No suman al efectivo.', style: muted),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final method in shift.otherMethods)
              Chip(label: Text('${method.name} · ${cashMoney(method.amount)}')),
          ]),
        ],
      ],
    );
  }

  String _subtitle(CashShift shift) {
    final opened = 'Abrió ${shift.openedByName ?? 'sin nombre'} el ${cashDay(shift.openedAt)} a las ${cashTime(shift.openedAt)}';
    if (shift.closedAt == null) return opened;
    return '$opened · Cerró ${shift.closedByName ?? 'sin nombre'} el ${cashDay(shift.closedAt!)} a las ${cashTime(shift.closedAt!)}';
  }
}
