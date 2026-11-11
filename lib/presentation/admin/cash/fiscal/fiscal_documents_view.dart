import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/chips/filter_chip_interval_date.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/presentation/components/links/entity_links.dart';
import '../../../../core/services/data_changes.dart';
import '../../../../core/services/file_download/file_download.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../domain/entities/fiscal/fiscal.dart';
import '../../../../domain/repositories/fiscal_repository.dart';
import '../../club_config/club_config_focus.dart';
import '../../club_config/widgets/admin_data_table.dart';
import '../cash_common.dart';
import 'fiscal_common.dart';
import 'fiscal_document_dialog.dart';

enum _Filter {
  all('Todos', null),
  authorized('Autorizados', 'AUTHORIZED'),
  inProgress('En proceso', 'PENDING,SENDING'),
  attention('Para resolver', 'ATTENTION'),
  draft('Por emitir', 'DRAFT');

  const _Filter(this.label, this.status);

  final String label;
  final String? status;
}

/// Caja › Comprobantes: las facturas y notas de crédito del período, con lo
/// que hay que resolver arriba de todo.
class FiscalDocumentsView extends StatefulWidget {
  const FiscalDocumentsView({super.key});

  @override
  State<FiscalDocumentsView> createState() => _FiscalDocumentsViewState();
}

class _FiscalDocumentsViewState extends State<FiscalDocumentsView> with ReloadOnDataChange, AutomaticKeepAliveClientMixin {
  final _repository = sl<FiscalRepository>();
  final _documents = <FiscalDocument>[];
  FiscalDocumentsPage? _last;
  FiscalSettings? _settings;
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _to = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  _Filter _filter = _Filter.all;
  bool _loading = false;
  bool _exporting = false;
  String? _error;
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.cash, DataTopic.payments};

  @override
  void onDataChanged(DataChange change) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadSettings();
      _load(reset: true);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final result = await _repository.getSettings();
    if (!mounted) return;
    if (result case Right(:final value)) setState(() => _settings = value);
  }

  FiscalDocumentFilters _filters({String? cursor}) => FiscalDocumentFilters(status: _filter.status, from: _from, to: _to, cursor: cursor);

  Future<void> _load({bool reset = false}) async {
    setState(() => _loading = true);
    final result = await _repository.getDocuments(_filters(cursor: reset ? null : _last?.nextCursor));
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Right(:final value):
          if (reset) _documents.clear();
          _documents.addAll(value.documents);
          _last = value;
          _error = null;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    final result = await _repository.exportCsv(FiscalDocumentFilters(from: _from, to: _to));
    if (!mounted) return;
    setState(() => _exporting = false);
    switch (result) {
      case Right(:final value):
        final name = 'comprobantes_${_day(_from)}_${_day(_to)}.csv';
        if (await downloadTextFile(name, value)) return;
        await Clipboard.setData(ClipboardData(text: value));
        if (mounted) SnackbarsFunctions.showSuccessSnackbar(context, 'CSV copiado: pegalo en una planilla');
      case Left(:final failure):
        SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
    }
  }

  String _day(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  List<FiscalOption> get _conditions => _settings?.options.ivaConditions ?? fiscalIvaConditions;

  Future<void> _after(Future<bool> action) async {
    if (await action) _load(reset: true);
  }

  Future<void> _openDetail(FiscalDocument doc) => _after(showFiscalDocumentDialog(context, doc.id, conditions: _conditions));

  List<Widget> _actions(FiscalDocument doc) {
    final canEmit = Permissions.can(Permissions.FACTURACION_EMITIR);
    final key = ValueKey('fiscal.row.${doc.id}.action');
    if (canEmit && doc.can.issue) {
      return [TextButton(key: key, onPressed: () => _after(FiscalDocumentActionsRunner.issue(context, doc)), child: const Text('Emitir'))];
    }
    if (canEmit && doc.can.correct && (doc.status == 'REJECTED' || doc.status == 'NEEDS_DATA')) {
      return [
        TextButton(
          key: key,
          onPressed: () => _after(FiscalDocumentActionsRunner.correct(context, doc, conditions: _conditions)),
          child: Text(doc.status == 'REJECTED' ? 'Corregir y reintentar' : 'Completar'),
        ),
      ];
    }
    if (doc.status == 'NEEDS_CONFIG' || doc.status == 'BLOCKED') {
      return [
        if (canEmit && doc.can.retry) TextButton(key: key, onPressed: () => _after(FiscalDocumentActionsRunner.retry(context, doc)), child: const Text('Reintentar')),
        if (Permissions.can(Permissions.CONFIGURACION_FACTURACION))
          TextButton(onPressed: () => openClubConfig(context, const ClubConfigFocus.fiscal()), child: const Text('Ver conexión')),
      ];
    }
    return [TextButton(key: key, onPressed: () => _openDetail(doc), child: const Text('Ver'))];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final last = _last;
    final profile = _settings?.profile;
    final mobile = ResponsiveBuilder.isMobile(context);
    final muted = TextStyle(fontSize: 12, height: 16 / 12, color: scheme.onSurfaceVariant);

    return ListView(
      padding: EdgeInsets.all(mobile ? 16 : 24),
      children: [
        if (_settings?.isSimulated ?? false) ...[
          FiscalNotice(
            key: const ValueKey('fiscal.simulated'),
            tone: StatusTone.primary(scheme),
            title: 'Modo de prueba',
            text: 'Los comprobantes los autoriza un simulador, no ARCA: no tienen validez fiscal.',
          ),
          const SizedBox(height: 12),
        ],
        if (profile != null && profile.connectionStatus == 'BLOCKED') ...[
          FiscalNotice(
            tone: StatusTone.warning(scheme),
            title: 'ARCA desconectada',
            text: 'Hay comprobantes esperando. No se perdió ningún cobro: salen cuando vuelva la conexión.',
            action: Permissions.can(Permissions.CONFIGURACION_FACTURACION)
                ? FilledButton(onPressed: () => openClubConfig(context, const ClubConfigFocus.fiscal()), child: const Text('Ver conexión'))
                : null,
          ),
          const SizedBox(height: 12),
        ],
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            FilterChipIntervalDate(
              initialSuggestion: 3,
              label: 'Período',
              withSuggesttions: true,
              onApply: (interval) {
                _from = interval.initialDate ?? _from;
                _to = interval.endDate ?? _to;
                _load(reset: true);
              },
            ),
            for (final filter in _Filter.values)
              FilterChip(
                key: ValueKey('fiscal.filter.${filter.name}'),
                label: Text(filter.label),
                selected: _filter == filter,
                showCheckmark: false,
                onSelected: (_) {
                  _filter = filter;
                  _load(reset: true);
                },
              ),
          ]),
          OutlinedButton(onPressed: _exporting ? null : _export, child: Text(_exporting ? 'Exportando…' : 'Exportar CSV')),
        ]),
        const SizedBox(height: 16),
        if (last != null) ...[
          CashStats(stats: [
            CashStat('Autorizados', '${last.count(const ['AUTHORIZED'])}'),
            CashStat('En proceso', '${last.count(fiscalInProgressStatuses)}'),
            CashStat('Para resolver', '${last.attention}', note: last.attention > 0 ? 'Necesitan algo de tu parte' : null),
            CashStat('Facturado', cashMoney(last.counts['AUTHORIZED']?.total ?? 0), note: 'Menos las notas de crédito'),
          ]),
          const SizedBox(height: 16),
        ],
        if (_error != null)
          CashMessage(_error!, onRetry: () => _load(reset: true))
        else if (_documents.isEmpty && _loading)
          const LinearProgressIndicator()
        else if (_documents.isEmpty)
          const CashMessage('No hay comprobantes en este período.')
        else
          AdminTableCard(
            child: AdminDataTable(
              columns: const ['Fecha', 'Comprobante', 'Cliente', 'Monto', 'Estado', ''],
              defaultColumnWidth: const FlexColumnWidth(),
              columnWidths: const {0: FixedColumnWidth(110), 3: FixedColumnWidth(124), 4: FlexColumnWidth(1.6), 5: FixedColumnWidth(200)},
              rows: [
                for (final doc in _documents)
                  [
                    Text(
                      doc.createdAt == null ? '—' : '${cashDay(doc.createdAt!)} ${cashTime(doc.createdAt!)}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                    InkWell(
                      key: ValueKey('fiscal.row.${doc.id}'),
                      onTap: () => _openDetail(doc),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(doc.documentLabel, style: TextStyle(color: scheme.primary)),
                        Text(fiscalNumber(doc), style: muted.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                      ]),
                    ),
                    doc.receiver.isConsumerFinal || doc.clientId == null
                        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (doc.clientId != null) ClientLink(clientId: doc.clientId!, name: doc.clientName ?? 'Cliente') else Text(doc.receiver.label),
                            if (doc.clientId != null) Text('Consumidor final', style: muted),
                          ])
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            ClientLink(clientId: doc.clientId!, name: doc.clientName ?? 'Cliente'),
                            Text(doc.receiver.label, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]),
                    Text(
                      fiscalAmount(doc),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()], color: doc.status == 'CANCELLED' ? scheme.onSurfaceVariant : null),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CashTag(label: doc.statusLabel, tone: fiscalStatusTone(scheme, doc.status)),
                      if (fiscalStatusReason(doc) case final reason?) ...[
                        const SizedBox(height: 4),
                        Text(reason, style: muted, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ]),
                    Wrap(children: _actions(doc)),
                  ],
              ],
            ),
          ),
        if (last?.nextCursor != null) ...[
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: _loading ? null : () => _load(), child: Text(_loading ? 'Cargando…' : 'Ver más'))),
        ],
      ],
    );
  }
}
