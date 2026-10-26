import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/chips/filter_chip_interval_date.dart';
import '../../../core/presentation/components/links/entity_links.dart';
import '../../../core/utils/admin_features.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../core/utils/thousands_format.dart';
import '../../../domain/entities/payment/payment_list_item.dart';
import '../../../domain/entities/payment/payment_method.dart';
import '../../../domain/entities/payment/payment_provider_status.dart';
import '../../../domain/entities/request/payment/payment_list_page_response.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../memberships/membership_board_view.dart';
import '../memberships/register_payment_dialog.dart';
import '../../../core/presentation/components/onboarding/tour_anchor.dart';

/// Pagos. Con algún servicio con abonos con cuotas: pestañas "Estado de
/// cuotas" y "Pagos registrados"; si no, directo los pagos registrados.
class PaymentsListPage extends StatelessWidget {
  const PaymentsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!AdminFeatures.memberships) {
      return Scaffold(backgroundColor: scheme.surfaceContainer, body: const PaymentsRegisteredView());
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainer,
        body: Column(children: [
          Material(
            color: scheme.surface,
            child: Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: scheme.outlineVariant))),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  TourAnchor(id: 'payments.tab.board', onActivate: TourAnchor.selectTab(0), child: const Tab(text: 'Estado de cuotas')),
                  TourAnchor(id: 'payments.tab.registered', onActivate: TourAnchor.selectTab(1), child: const Tab(text: 'Pagos registrados')),
                ],
              ),
            ),
          ),
          const Expanded(child: TabBarView(children: [MembershipBoardView(), PaymentsRegisteredView()])),
        ]),
      ),
    );
  }
}

const _months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
const _weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
String _money(num v) => '\$ ${ThousandsFormat.formatPrice(v)}';

String _dayTitle(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final label = '${_weekdays[d.weekday - 1].toLowerCase()} ${d.day} de ${_months[d.month - 1]}${d.year != now.year ? ' de ${d.year}' : ''}';
  if (day == today) return 'Hoy, $label';
  if (day == today.subtract(const Duration(days: 1))) return 'Ayer, $label';
  return label[0].toUpperCase() + label.substring(1);
}

/// Pagos registrados: período (el combo de siempre), qué se pagó, medio y
/// cliente; totales por medio; los pagos agrupados por día.
class PaymentsRegisteredView extends StatefulWidget {
  const PaymentsRegisteredView({super.key});

  @override
  State<PaymentsRegisteredView> createState() => _PaymentsRegisteredViewState();
}

class _PaymentsRegisteredViewState extends State<PaymentsRegisteredView> {
  final _repository = sl<PaymentRepository>();
  final _items = <PaymentListItem>[];
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  String? _kind;
  int? _methodId;
  String _search = '';
  List<PaymentMethod> _methods = const [];
  PaymentListPageResponse? _last;
  int _page = 1;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository.getPaymentMethods().then((r) {
      if (mounted) r.when(left: (_) {}, right: (methods) => setState(() => _methods = methods));
    });
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _items.clear();
    }
    setState(() => _loading = true);
    final result = await _repository.getPayments(_page, fechaDesde: _from, fechaHasta: _to, kind: _kind, paymentMethodId: _methodId, search: _search);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Right(:final value):
          _items.addAll(value.items);
          _last = value;
          _page++;
          _error = null;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mobile = ResponsiveBuilder.isMobile(context);
    final last = _last;

    // Agrupados por día, en el orden en que llegan (más nuevos primero).
    final groups = <DateTime, List<PaymentListItem>>{};
    for (final item in _items) {
      groups.putIfAbsent(DateTime(item.paymentDate.year, item.paymentDate.month, item.paymentDate.day), () => []).add(item);
    }

    final kinds = <(String?, String)>[
      (null, 'Todo'),
      if (AdminFeatures.memberships) ('MEMBERSHIP', 'Abonos'),
      ('SESSION', 'Turnos'),
      ('PRODUCT', 'Productos'),
      ('OTHER', 'Otros'),
    ];

    return ListView(
      padding: EdgeInsets.all(mobile ? 16 : 24),
      children: [
        TourAnchor(id: 'payments.filters', child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FilterChipIntervalDate(
            initialSuggestion: 2,
            label: 'Fecha de pago',
            withSuggesttions: true,
            onApply: (interval) {
              _from = interval.initialDate ?? _from;
              _to = interval.endDate ?? _to;
              _load(reset: true);
            },
          ),
          for (final (kind, label) in kinds)
            ChoiceChip(
              label: Text(label),
              selected: _kind == kind,
              showCheckmark: false,
              onSelected: (_) {
                _kind = kind;
                _load(reset: true);
              },
            ),
          if (_methods.isNotEmpty)
            PopupMenuButton<int?>(
              tooltip: 'Medio de pago',
              onSelected: (id) {
                _methodId = id;
                _load(reset: true);
              },
              itemBuilder: (_) => [
                const PopupMenuItem<int?>(value: null, child: Text('Todos los medios')),
                for (final m in _methods) PopupMenuItem<int?>(value: m.paymentMethodId, child: Text(m.name)),
              ],
              child: Chip(
                label: Text(_methods.where((m) => m.paymentMethodId == _methodId).firstOrNull?.name ?? 'Todos los medios'),
                avatar: const Icon(Icons.arrow_drop_down, size: 18),
              ),
            ),
          SizedBox(
            width: 220,
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar cliente', border: OutlineInputBorder(), isDense: true),
              onSubmitted: (v) {
                _search = v;
                _load(reset: true);
              },
            ),
          ),
          TourAnchor(id: 'payments.register', child: RegisterPaymentButton(filled: true, onPaid: () => _load(reset: true))),
        ])),
        const SizedBox(height: 16),
        if (last != null) TourAnchor(id: 'payments.totals', child: _Totals(response: last, showMemberships: AdminFeatures.memberships && _kind == null)),
        const SizedBox(height: 16),
        if (_error != null)
          Row(children: [Expanded(child: Text(_error!)), TextButton(onPressed: () => _load(reset: true), child: const Text('Reintentar'))])
        else if (_items.isEmpty && _loading)
          const LinearProgressIndicator()
        else if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No hay pagos en este período.', style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))),
          )
        else
          TourAnchor(id: 'payments.list', child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (!mobile) const _HeaderRow(),
              for (final entry in groups.entries) ...[
                _DayRow(day: entry.key, items: entry.value),
                for (final item in entry.value) mobile ? _MobileRow(item: item) : _PaymentRow(item: item),
              ],
            ]),
          )),
        if (last != null && _items.length < last.totalCount) ...[
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: _loading ? null : () => _load(), child: Text(_loading ? 'Cargando…' : 'Ver más (${_items.length} de ${last.totalCount})'))),
        ],
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.response, required this.showMemberships});

  final PaymentListPageResponse response;
  final bool showMemberships;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final memberships = response.byKind['MEMBERSHIP'];
    final total = response.byMethod.fold<double>(0, (s, m) => s + m.$2);
    final cards = <(String, String, String?, bool)>[
      ('Cobrado', _money(response.totalAmount), '${response.totalCount} ${response.totalCount == 1 ? 'pago' : 'pagos'}', true),
      if (showMemberships && memberships != null) ('Abonos', _money(memberships.$1), '${memberships.$2} ${memberships.$2 == 1 ? 'cuota' : 'cuotas'}', false),
      for (final (name, amount) in response.byMethod.take(3)) (name, _money(amount), total > 0 ? '${(amount * 100 / total).round()} %' : null, false),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000 ? cards.length.clamp(1, 5) : (constraints.maxWidth >= 600 ? 3 : 2);
      final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        for (final (label, value, sub, main) in cards)
          SizedBox(
            width: width,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(value, style: (main ? textTheme.headlineSmall : textTheme.titleMedium)?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                  if (sub != null) Text(sub, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ]),
              ),
            ),
          ),
      ]);
    });
  }
}

const _flex = [70.0, 1.3, 1.8, 1.0, 120.0, 1.0];

Widget _cells(BuildContext context, List<Widget> children, {Color? background, TextStyle? style}) {
  final scheme = Theme.of(context).colorScheme;
  Widget cell(int i, Widget child) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(border: Border(left: i == 0 ? BorderSide.none : BorderSide(color: scheme.outlineVariant))),
      alignment: i == 4 ? Alignment.centerRight : Alignment.centerLeft,
      child: DefaultTextStyle.merge(style: style, child: child),
    );
    final w = _flex[i];
    return w > 10 ? SizedBox(width: w, child: content) : Expanded(flex: (w * 10).round(), child: content);
  }

  return Container(
    decoration: BoxDecoration(color: background, border: Border(top: BorderSide(color: scheme.outlineVariant))),
    child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final (i, c) in children.indexed) cell(i, c)])),
  );
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _cells(
      context,
      const [Text('Hora'), Text('Cliente'), Text('Concepto'), Text('Medio'), Text('Monto'), Text('Registró')],
      background: scheme.surfaceContainerHighest,
      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.items});

  final DateTime day;
  final List<PaymentListItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = items.where((i) => i.providerStatus == null || i.providerStatus == PaymentProviderStatus.approved).fold<double>(0, (s, i) => s + i.amount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: scheme.surfaceContainer, border: Border(top: BorderSide(color: scheme.outlineVariant))),
      child: Row(children: [
        Expanded(child: Text(_dayTitle(day), style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant))),
        Text(_money(total), style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, filled) = switch (kind) {
      'MEMBERSHIP' => ('Abono', true),
      'SESSION' => ('Turno', false),
      'PRODUCT' => ('Producto', false),
      _ => ('Otro', false),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? scheme.secondaryContainer : null,
        borderRadius: BorderRadius.circular(8),
        border: filled ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: filled ? scheme.onSecondaryContainer : scheme.onSurfaceVariant)),
    );
  }
}

class _ConceptCell extends StatelessWidget {
  const _ConceptCell({required this.item});

  final PaymentListItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final detail = [item.conceptDetail, item.observation].whereType<String>().where((s) => s.trim().isNotEmpty && s.trim() != item.conceptLabel).join(' · ');
    final status = item.providerStatus;
    return Row(children: [
      _KindChip(kind: item.conceptKind),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (item.sessionId != null)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.goNamed(AppRoutes.SESSION_MANAGER_RESERVE_ROUTE.name, pathParameters: {'idSession': '${item.sessionId}'}),
                child: Text(item.conceptLabel, style: TextStyle(color: scheme.primary)),
              ),
            )
          else
            Text(item.conceptLabel),
          if (detail.isNotEmpty) Text(detail, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
      if (status != null && status != PaymentProviderStatus.approved) ...[
        const SizedBox(width: 6),
        Text(status.label, style: textTheme.labelSmall?.copyWith(color: status.color)),
      ],
    ]);
  }
}

String _time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.item});

  final PaymentListItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _cells(context, [
      Text(_time(item.paymentDate), style: TextStyle(color: scheme.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()])),
      item.clientId == null ? Text(item.clientName) : ClientLink(clientId: item.clientId!, name: item.clientName),
      _ConceptCell(item: item),
      Text(item.paymentMethodName),
      Text(_money(item.amount), style: const TextStyle(fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()])),
      Text(item.adminName ?? (item.providerStatus != null ? 'Online' : '—'), style: TextStyle(color: scheme.onSurfaceVariant)),
    ]);
  }
}

class _MobileRow extends StatelessWidget {
  const _MobileRow({required this.item});

  final PaymentListItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: scheme.outlineVariant))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: item.clientId == null ? Text(item.clientName) : ClientLink(clientId: item.clientId!, name: item.clientName)),
          Text(_money(item.amount), style: textTheme.titleSmall),
        ]),
        const SizedBox(height: 6),
        _ConceptCell(item: item),
        const SizedBox(height: 4),
        Text('${_time(item.paymentDate)} · ${item.paymentMethodName}${item.adminName != null ? ' · ${item.adminName}' : ''}', style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ]),
    );
  }
}
