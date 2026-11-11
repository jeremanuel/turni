import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/chips/filter_chip_interval_date.dart';
import '../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../core/presentation/components/onboarding/tour_anchor.dart';
import '../../../core/services/cash_status.dart';
import '../../../core/services/data_changes.dart';
import '../../../core/services/fiscal_status.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../domain/entities/cash/cash.dart';
import '../../../domain/repositories/cash_repository.dart';
import '../club_config/widgets/admin_data_table.dart';
import '../widgets/admin_destinations.dart';
import 'cash_common.dart';
import 'cash_reconciliation_view.dart';
import 'dialogs/close_cash_dialog.dart';
import 'dialogs/open_cash_dialog.dart';
import 'fiscal/fiscal_documents_view.dart';

/// Caja: los puestos con su estado, todos los movimientos y los cierres. Si
/// el club factura con ARCA, también los comprobantes (y solo eso, si no usa
/// caja).
class CashPage extends StatelessWidget {
  const CashPage({super.key, this.initialTab});

  /// `comprobantes` abre esa pestaña (ej. desde un aviso de comprobante rechazado).
  final String? initialTab;

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: AdminDestinations.changes, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showFiscal = FiscalStatus.enabled.value && Permissions.can(Permissions.FACTURACION_VER);
    final showCash = (CashStatus.enabled.value || !showFiscal) && Permissions.can(Permissions.CAJA_VER);
    final canReconcile = showCash && Permissions.can(Permissions.CAJA_CONCILIAR);
    final tabs = <(Widget, Widget)>[
      if (showCash) ...[
        (TourAnchor(id: 'cash.tab.points', onActivate: TourAnchor.selectTab(0), child: const Tab(text: 'Puestos')), const CashPointsView()),
        (TourAnchor(id: 'cash.tab.movements', onActivate: TourAnchor.selectTab(1), child: const Tab(text: 'Movimientos')), const CashMovementsView()),
        (TourAnchor(id: 'cash.tab.closes', onActivate: TourAnchor.selectTab(2), child: const Tab(text: 'Cierres')), const CashClosesView()),
        if (canReconcile) (const Tab(text: 'Conciliación'), const CashReconciliationView()),
      ],
      if (showFiscal) (const TourAnchor(id: 'cash.tab.fiscal', child: Tab(text: 'Comprobantes')), const FiscalDocumentsView()),
    ];
    if (tabs.isEmpty) return const Center(child: CashMessage('Tu rol no puede ver la caja ni los comprobantes.'));
    final initialIndex = initialTab == 'comprobantes' && showFiscal ? tabs.length - 1 : 0;
    return DefaultTabController(
      key: ValueKey('${tabs.length}-$initialIndex'),
      length: tabs.length,
      initialIndex: initialIndex,
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
                tabs: [for (final (tab, _) in tabs) tab],
              ),
            ),
          ),
          Expanded(child: TabBarView(children: [for (final (_, view) in tabs) view])),
        ]),
      ),
    );
  }
}

EdgeInsets _pagePadding(BuildContext context) => EdgeInsets.all(ResponsiveBuilder.isMobile(context) ? 16 : 24);

class CashPointsView extends StatefulWidget {
  const CashPointsView({super.key});

  @override
  State<CashPointsView> createState() => _CashPointsViewState();
}

class _CashPointsViewState extends State<CashPointsView> with ReloadOnDataChange {
  final _repository = sl<CashRepository>();
  CashOverview? _overview;
  String? _error;
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
    final result = await _repository.getOverview();
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Right(:final value):
          _overview = value;
          _error = null;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  double _otherMethod(CashOverview overview, String needle) => overview.todayOtherMethods
      .where((method) => method.name.toLowerCase().contains(needle))
      .fold<double>(0, (sum, method) => sum + method.amount);

  Future<void> _open(CashOverview overview, CashPoint point) async {
    if (await showOpenCashDialog(context, points: overview.activePoints, selectedId: point.id)) _load();
  }

  Future<void> _close(CashOverview overview, CashPoint point) async {
    final closed = await showCloseCashDialog(context, shiftId: point.openShift!.id, pointName: point.name, tolerance: overview.settings.tolerance);
    if (!closed || !mounted) return;
    SnackbarsFunctions.showSuccessSnackbar(context, 'Caja cerrada');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    if (overview == null) {
      if (_error != null) return Center(child: CashMessage(_error!, onRetry: _load));
      return const LinearProgressIndicator();
    }

    final points = overview.activePoints;
    final inOpen = points.fold<double>(0, (sum, point) => sum + (point.openShift?.expectedAmount ?? 0));

    return ListView(
      padding: _pagePadding(context),
      children: [
        TourAnchor(
          id: 'cash.stats',
          child: CashStats(stats: [
            CashStat('En cajas abiertas', overview.canSeeExpected ? cashMoney(inOpen) : '—', note: overview.canSeeExpected ? null : 'Arqueo ciego'),
            CashStat('Mercado Pago hoy', cashMoney(_otherMethod(overview, 'mercado'))),
            CashStat('Transferencias hoy', cashMoney(_otherMethod(overview, 'transfer'))),
            CashStat('Tarjeta hoy', cashMoney(_otherMethod(overview, 'tarjeta'))),
          ]),
        ),
        const SizedBox(height: 16),
        if (points.isEmpty)
          const CashMessage('Todavía no hay puestos. Se crean en Configuración › Cajas.')
        else
          TourAnchor(
            id: 'cash.points',
            child: LayoutBuilder(builder: (context, constraints) {
              final columns = (constraints.maxWidth / 340).floor().clamp(1, 4);
              final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
              return Wrap(spacing: 12, runSpacing: 12, children: [
                for (final point in points)
                  SizedBox(
                    width: width,
                    child: _PointCard(
                      point: point,
                      canSeeExpected: overview.canSeeExpected,
                      onOpen: () => _open(overview, point),
                      onClose: () => _close(overview, point),
                    ),
                  ),
              ]);
            }),
          ),
      ],
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({required this.point, required this.canSeeExpected, required this.onOpen, required this.onClose});

  final CashPoint point;
  final bool canSeeExpected;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final shift = point.openShift;
    final canOperate = Permissions.can(Permissions.CAJA_OPERAR);

    return Card(
      key: ValueKey('cash.point.${point.name}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(point.name, style: textTheme.titleMedium),
            if (point.isPrimary) CashTag(label: 'Principal', tone: StatusTone.primary(scheme)),
            CashTag(label: shift != null ? 'Abierta' : 'Cerrada', tone: shift != null ? StatusTone.success(scheme) : StatusTone.neutral(scheme)),
          ]),
          const SizedBox(height: 4),
          Text(shift != null ? 'Abrió ${shift.openedByName ?? 'sin nombre'} a las ${cashTime(shift.openedAt)}' : _lastCloseText(), style: muted),
          const SizedBox(height: 12),
          if (shift != null && (canSeeExpected || shift.expectedAmount != null)) ...[
            Text('Efectivo esperado', style: muted),
            Text(cashMoney(shift.expectedAmount ?? 0), style: textTheme.titleLarge),
          ] else if (shift != null) ...[
            Text('Efectivo esperado', style: muted),
            Text('Arqueo ciego', style: textTheme.titleSmall),
          ] else ...[
            Text('Quedó en la caja', style: muted),
            Text(cashMoney(point.lastClose?.leftAmount ?? 0), style: textTheme.titleLarge),
          ],
          const SizedBox(height: 12),
          Text('Espacios', style: muted),
          Text(cashSpacesLabel(point.spaces), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          Row(children: [
            if (canOperate)
              shift != null
                  ? FilledButton(onPressed: onClose, child: const Text('Cerrar caja'))
                  : FilledButton(onPressed: onOpen, child: const Text('Abrir caja')),
            if (canOperate && shift != null) const SizedBox(width: 8),
            if (shift != null)
              OutlinedButton(
                onPressed: () => context.goNamed(AppRoutes.CASH_SHIFT_ROUTE.name, pathParameters: {'shiftId': shift.id}),
                child: const Text('Ver'),
              ),
          ]),
        ]),
      ),
    );
  }

  String _lastCloseText() {
    final last = point.lastClose;
    if (last?.closedAt == null) return 'Todavía no tuvo cierres';
    return 'Cerró ${last!.closedByName ?? 'sin nombre'} el ${cashDay(last.closedAt!)} a las ${cashTime(last.closedAt!)}';
  }
}

/// Puestos para los filtros.
Future<List<CashPoint>> _loadPoints() async {
  final result = await sl<CashRepository>().getOverview();
  if (result case Right(:final value)) return value.points;
  return const [];
}

class CashMovementsView extends StatefulWidget {
  const CashMovementsView({super.key});

  @override
  State<CashMovementsView> createState() => _CashMovementsViewState();
}

class _CashMovementsViewState extends State<CashMovementsView> with ReloadOnDataChange, AutomaticKeepAliveClientMixin {
  final _repository = sl<CashRepository>();
  final _movements = <CashMovement>[];
  List<CashPoint> _points = const [];
  DateTime _from = DateTime.now().subtract(const Duration(days: 6));
  DateTime _to = DateTime.now();
  int? _accountId;
  String? _kind;
  String? _cursor;
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  static const _kinds = ['SALE', 'REVERSAL', 'EXPENSE', 'WITHDRAWAL', 'DEPOSIT', 'ADJUSTMENT'];

  @override
  bool get wantKeepAlive => true;

  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.cash, DataTopic.payments};

  @override
  void onDataChanged(DataChange change) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(reset: true));
  }

  @override
  void initState() {
    super.initState();
    _loadPoints().then((points) {
      if (mounted) setState(() => _points = points);
    });
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    setState(() => _loading = true);
    final result = await _repository.getMovements(CashListFilters(cashAccountId: _accountId, kind: _kind, from: _from, to: _to, cursor: reset ? null : _cursor));
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Right(:final value):
          if (reset) _movements.clear();
          _movements.addAll(value.movements);
          _cursor = value.nextCursor;
          _error = null;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: _pagePadding(context),
      children: [
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FilterChipIntervalDate(
            initialSuggestion: 0,
            label: 'Fecha',
            withSuggesttions: true,
            onApply: (interval) {
              _from = interval.initialDate ?? _from;
              _to = interval.endDate ?? _to;
              _load(reset: true);
            },
          ),
          CashFilterMenu<int>(
            tooltip: 'Puesto',
            value: _accountId,
            allLabel: 'Todos los puestos',
            options: [for (final point in _points) (point.id, point.name)],
            onSelected: (id) {
              _accountId = id;
              _load(reset: true);
            },
          ),
          CashFilterMenu<String>(
            tooltip: 'Tipo',
            value: _kind,
            allLabel: 'Todos los tipos',
            options: [for (final kind in _kinds) (kind, cashMovementLabel(kind))],
            onSelected: (kind) {
              _kind = kind;
              _load(reset: true);
            },
          ),
        ]),
        const SizedBox(height: 16),
        if (_error != null)
          CashMessage(_error!, onRetry: () => _load(reset: true))
        else if (_movements.isEmpty && _loading)
          const LinearProgressIndicator()
        else if (_movements.isEmpty)
          const CashMessage('No hay movimientos en este período.')
        else
          AdminTableCard(child: CashMovementsTable(movements: _movements, showAccount: true)),
        if (_cursor != null) ...[
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: _loading ? null : () => _load(), child: Text(_loading ? 'Cargando…' : 'Ver más'))),
        ],
      ],
    );
  }
}

class CashClosesView extends StatefulWidget {
  const CashClosesView({super.key});

  @override
  State<CashClosesView> createState() => _CashClosesViewState();
}

class _CashClosesViewState extends State<CashClosesView> with ReloadOnDataChange, AutomaticKeepAliveClientMixin {
  final _repository = sl<CashRepository>();
  final _shifts = <CashShift>[];
  CashShiftsPage? _last;
  List<CashPoint> _points = const [];
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month - 1, DateTime.now().day);
  DateTime _to = DateTime.now();
  int? _accountId;
  bool _withDifference = false;
  bool _loading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.cash};

  @override
  void onDataChanged(DataChange change) => _load(reset: true);

  @override
  void initState() {
    super.initState();
    _loadPoints().then((points) {
      if (mounted) setState(() => _points = points);
    });
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    setState(() => _loading = true);
    final result = await _repository.getClosedShifts(
      CashListFilters(cashAccountId: _accountId, from: _from, to: _to, withDifference: _withDifference, cursor: reset ? null : _last?.nextCursor),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Right(:final value):
          if (reset) _shifts.clear();
          _shifts.addAll(value.shifts);
          _last = value;
          _error = null;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  (String, StatusTone) _status(ColorScheme scheme, String? label) => switch (label) {
        'BALANCED' => ('Cuadró', StatusTone.success(scheme)),
        'WITHIN_TOLERANCE' => ('En tolerancia', StatusTone.warning(scheme)),
        _ => ('Revisar', StatusTone.danger(scheme)),
      };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final last = _last;

    return ListView(
      padding: _pagePadding(context),
      children: [
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FilterChipIntervalDate(
            initialSuggestion: 2,
            label: 'Período',
            withSuggesttions: true,
            onApply: (interval) {
              _from = interval.initialDate ?? _from;
              _to = interval.endDate ?? _to;
              _load(reset: true);
            },
          ),
          CashFilterMenu<int>(
            tooltip: 'Puesto',
            value: _accountId,
            allLabel: 'Todos los puestos',
            options: [for (final point in _points) (point.id, point.name)],
            onSelected: (id) {
              _accountId = id;
              _load(reset: true);
            },
          ),
          FilterChip(
            label: const Text('Con diferencia'),
            selected: _withDifference,
            showCheckmark: false,
            onSelected: (value) {
              _withDifference = value;
              _load(reset: true);
            },
          ),
        ]),
        const SizedBox(height: 16),
        if (last != null) ...[
          CashStats(stats: [
            CashStat('Diferencia del período', cashSigned(last.totalDifference), note: 'Suma de faltantes y sobrantes'),
            CashStat('Cierres con diferencia', '${last.withDifference} de ${last.count}'),
            CashStat('Para revisar', '${last.overTolerance}', note: 'Superan la tolerancia'),
          ]),
          const SizedBox(height: 16),
        ],
        if (_error != null)
          CashMessage(_error!, onRetry: () => _load(reset: true))
        else if (_shifts.isEmpty && _loading)
          const LinearProgressIndicator()
        else if (_shifts.isEmpty)
          const CashMessage('No hay cierres en este período.')
        else
          AdminTableCard(
            child: AdminDataTable(
              columns: const ['Fecha', 'Puesto', 'Cerró', 'Esperado', 'Contado', 'Diferencia', 'Estado'],
              defaultColumnWidth: const FlexColumnWidth(),
              rows: [
                for (final shift in _shifts)
                  [
                    InkWell(
                      onTap: () => context.goNamed(AppRoutes.CASH_SHIFT_ROUTE.name, pathParameters: {'shiftId': shift.id}),
                      child: Text(shift.closedAt == null ? '—' : cashDay(shift.closedAt!), style: TextStyle(color: scheme.primary)),
                    ),
                    Text(shift.accountName),
                    Text(shift.closedByName ?? '—'),
                    Text(shift.expectedAmount == null ? '—' : cashMoney(shift.expectedAmount!)),
                    Text(shift.countedAmount == null ? '—' : cashMoney(shift.countedAmount!)),
                    Text(cashSigned(shift.difference ?? 0), style: TextStyle(color: cashAmountColor(scheme, shift.difference ?? 0))),
                    Builder(builder: (context) {
                      final (label, tone) = _status(scheme, shift.statusLabel);
                      return Align(alignment: Alignment.centerLeft, child: CashTag(label: label, tone: tone));
                    }),
                  ],
              ],
            ),
          ),
        if (last?.nextCursor != null) ...[
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: _loading ? null : () => _load(), child: Text(_loading ? 'Cargando…' : 'Ver más'))),
        ],
        if (last?.byPerson != null && last!.byPerson!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Diferencia por persona', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(children: [
                for (final person in last.byPerson!)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(person.name ?? 'Sin nombre'),
                      Text(cashSigned(person.difference), style: TextStyle(color: cashAmountColor(scheme, person.difference))),
                    ]),
                  ),
              ]),
            ),
          ),
        ],
      ],
    );
  }
}
