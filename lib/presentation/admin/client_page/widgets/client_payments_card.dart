import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/app_routes.dart';
import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/loading/app_skeleton.dart';
import '../../../../core/utils/admin_features.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/payment/payment_list_item.dart';
import '../../../../domain/repositories/payment_repository.dart';
import '../../club_config/widgets/admin_data_table.dart';
import '../../memberships/register_payment_dialog.dart';
import '../../../../core/services/data_changes.dart';

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
String _date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
String _money(num v) => '\$ ${ThousandsFormat.formatPrice(v)}';

/// Pagos de la ficha: tabla con qué se pagó (abono y cuota, turno, producto),
/// medio, monto y quién lo registró. Filtra por abono o turnos y extras.
class ClientPaymentsCard extends StatefulWidget {
  const ClientPaymentsCard({super.key, required this.client, required this.onPaid});

  final Client client;

  /// Se registró un pago desde acá.
  final VoidCallback onPaid;

  @override
  State<ClientPaymentsCard> createState() => _ClientPaymentsCardState();
}

class _ClientPaymentsCardState extends State<ClientPaymentsCard> with ReloadOnDataChange {
  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.payments};

  @override
  bool shouldReload(DataChange change) => change.isFor('client_id', widget.client.intClientId);

  /// En vivo: un pago de este cliente (cuota, turno, adicional).
  @override
  void onDataChanged(DataChange change) => _load(reset: true);
  final _repository = sl<PaymentRepository>();
  final _items = <PaymentListItem>[];
  int _page = 1;
  int _total = 0;
  double _yearTotal = 0;
  DateTime? _lastPayment;
  String? _kind;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _items.clear();
    }
    setState(() => _loading = true);
    final result = await _repository.getClientPaymentRows(widget.client.intClientId, _page, kind: _kind);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Right(:final value):
          _items.addAll(value.items);
          _total = value.total;
          if (_kind == null) {
            _yearTotal = value.yearTotal;
            _lastPayment = value.lastPaymentDate;
          }
          _page++;
          _error = null;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  void _filter(String? kind) {
    if (_kind == kind) return;
    _kind = kind;
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final memberships = AdminFeatures.memberships;

    final summary = [
      if (_yearTotal > 0) '${_money(_yearTotal)} en ${DateTime.now().year}',
      if (_lastPayment != null) 'último pago el ${_date(_lastPayment!)}',
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pagos', style: textTheme.titleMedium),
                if (summary.isNotEmpty) Text(summary, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ]),
              Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (memberships) ...[
                  ChoiceChip(label: const Text('Todos'), selected: _kind == null, showCheckmark: false, onSelected: (_) => _filter(null)),
                  ChoiceChip(label: const Text('Abono'), selected: _kind == 'MEMBERSHIP', showCheckmark: false, onSelected: (_) => _filter('MEMBERSHIP')),
                  ChoiceChip(label: const Text('Turnos y extras'), selected: _kind == 'OTHERS', showCheckmark: false, onSelected: (_) => _filter('OTHERS')),
                ],
                RegisterPaymentButton(
                  client: widget.client,
                  filled: true,
                  onPaid: () {
                    _load(reset: true);
                    widget.onPaid();
                  },
                ),
              ]),
            ],
          ),
          const SizedBox(height: 14),
          if (_error != null)
            LoadError(message: _error!, onRetry: () => _load(reset: true))
          else if (_items.isEmpty && _loading)
            // La tabla de siempre con filas de mentira: no salta al llegar.
            AppSkeleton(
              child: _table([
                for (var i = 0; i < 3; i++)
                  [
                    Text(BoneMock.date),
                    Text(skeletonText(2 + i % 2), style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(skeletonText(1)),
                    Align(alignment: Alignment.centerRight, child: Text(BoneMock.chars(8))),
                    Text(skeletonText(1)),
                  ],
              ]),
            )
          else if (_items.isEmpty)
            Text('Sin pagos todavía.', style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))
          else ...[
            _table([
              for (final payment in _items)
                [
                  Text(_date(payment.paymentDate)),
                  _Concept(payment: payment),
                  Text(payment.paymentMethodName),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(_money(payment.amount), style: const TextStyle(fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()])),
                  ),
                  Text(payment.adminName ?? (payment.providerStatus != null ? 'Online' : '—'), style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text('${_items.length} de $_total ${_total == 1 ? 'pago' : 'pagos'}', style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const Spacer(),
              if (_items.length < _total)
                TextButton(onPressed: _loading ? null : () => _load(), child: Text(_loading ? 'Cargando…' : 'Ver más')),
            ]),
          ],
        ]),
      ),
    );
  }
}

Widget _table(List<List<Widget>> rows) => AdminDataTable(
      columns: const ['Fecha', 'Concepto', 'Medio', 'Monto', 'Registró'],
      columnWidths: const {0: FixedColumnWidth(118), 1: FlexColumnWidth(1.8), 2: FlexColumnWidth(), 3: FixedColumnWidth(110), 4: FlexColumnWidth()},
      rows: rows,
    );

class _Concept extends StatelessWidget {
  const _Concept({required this.payment});

  final PaymentListItem payment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final detail = [payment.conceptDetail, payment.observation].whereType<String>().where((s) => s.trim().isNotEmpty && s.trim() != payment.conceptLabel).join(' · ');
    final label = Text(payment.conceptLabel, style: const TextStyle(fontWeight: FontWeight.w500));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (payment.sessionId != null)
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.goNamed(AppRoutes.SESSION_MANAGER_RESERVE_ROUTE.name, pathParameters: {'idSession': '${payment.sessionId}'}),
            child: label,
          ),
        )
      else
        label,
      if (detail.isNotEmpty) Text(detail, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
    ]);
  }
}
