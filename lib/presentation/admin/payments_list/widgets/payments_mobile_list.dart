import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/app_routes.dart';
import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/payment/payment_list_item.dart';
import '../cubit/payments_list_cubit.dart';

/// Celular: los pagos agrupados por día, con scroll infinito (en lugar de la
/// grilla de escritorio). Usa los mismos filtros del cubit.
class PaymentsMobileList extends StatefulWidget {
  const PaymentsMobileList({super.key});

  @override
  State<PaymentsMobileList> createState() => _PaymentsMobileListState();
}

class _PaymentsMobileListState extends State<PaymentsMobileList> {
  static const _pageSize = 25;

  final _payments = <PaymentListItem>[];
  final _scroll = ScrollController();
  int _nextPage = 1;
  int? _total;
  double? _totalAmount;
  bool _loading = false;
  bool _failed = false;
  late final PaymentsListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<PaymentsListCubit>();
    _cubit.onMobileRefresh = _reload;
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
    });
    _loadMore();
  }

  @override
  void dispose() {
    if (_cubit.onMobileRefresh == _reload) _cubit.onMobileRefresh = null;
    _scroll.dispose();
    super.dispose();
  }

  bool get _hasMore => _total == null || (_nextPage - 1) * _pageSize < _total!;

  void _reload() {
    if (!mounted) return;
    setState(() {
      _payments.clear();
      _nextPage = 1;
      _total = null;
      _totalAmount = null;
      _failed = false;
    });
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final page = await _cubit.fetchPage(_nextPage);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (page == null) {
        _failed = true;
        return;
      }
      _payments.addAll(page.items);
      _total = page.totalCount;
      _totalAmount = page.totalAmount;
      _nextPage++;
    });
  }

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static String _dayLabel(DateTime d) {
    final today = DateTime.now();
    final date = DateTime(d.year, d.month, d.day);
    final diff = DateTime(today.year, today.month, today.day).difference(date).inDays;
    final dd = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    if (diff == 0) return 'Hoy · $dd';
    if (diff == 1) return 'Ayer · $dd';
    return dd;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (_payments.isEmpty) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _failed
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('No se pudieron cargar los pagos.'),
                  TextButton(onPressed: _reload, child: const Text('Reintentar')),
                ])
              : Text('No hay pagos en este período.', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ),
      );
    }

    // Encabezado del período + un bloque por día (con su subtotal).
    final items = <Widget>[
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(child: Text('Total del período · ${_total ?? 0} pagos', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))),
            Text(ThousandsFormat.formatPrice(_totalAmount ?? 0), style: text.titleMedium),
          ]),
        ),
      ),
    ];
    String? currentDay;
    for (final payment in _payments) {
      final key = _dayKey(payment.paymentDate);
      if (key != currentDay) {
        currentDay = key;
        final dayTotal = _payments.where((p) => _dayKey(p.paymentDate) == key).fold<double>(0, (sum, p) => sum + p.amount);
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
          child: Row(children: [
            Expanded(child: Text(_dayLabel(payment.paymentDate).toUpperCase(), style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0.4))),
            Text(ThousandsFormat.formatPrice(dayTotal), style: text.labelSmall),
          ]),
        ));
      }
      items.add(Padding(padding: const EdgeInsets.only(top: 8), child: _PaymentCard(payment: payment)));
    }
    if (_loading) items.add(const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())));

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: items,
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final PaymentListItem payment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final status = payment.providerStatus;
    final detail = [
      payment.paymentMethodName,
      if (payment.subscriptionName != null) payment.subscriptionName!,
      if (payment.sessionId != null) 'Turno #${payment.sessionId}',
    ].join(' · ');
    final sessionId = payment.sessionId;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Un pago de turno abre ese turno; uno suelto, la ficha del cliente.
        onTap: sessionId != null
            ? () => context.goNamed(AppRoutes.SESSION_MANAGER_RESERVE_ROUTE.name, pathParameters: {'idSession': '$sessionId'})
            : payment.clientId == null
                ? null
                : () => context.goNamed(AppRoutes.CLIENT_ROUTE.name, pathParameters: {'clientId': '${payment.clientId}'}),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(payment.clientName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(detail, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (status != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: status.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(status.label, style: TextStyle(color: status.color, fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(ThousandsFormat.formatPrice(payment.amount), style: text.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
