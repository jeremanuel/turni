import 'package:flutter/material.dart';

import '../../../core/presentation/components/links/entity_links.dart';
import 'package:intl/intl.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../domain/entities/fixed_session.dart';
import '../../../domain/repositories/fixed_session_repository.dart';
import '../../../core/utils/admin_vocabulary.dart';
import '../club_config/widgets/admin_data_table.dart';
import 'widgets/fixed_session_actions.dart';
import 'widgets/fixed_session_texts.dart';
import '../../../core/services/data_changes.dart';
import '../../../core/presentation/components/onboarding/tour_anchor.dart';

enum _View { week, list }

/// Turnos fijos del club (pestaña de Gestión masiva): la semana en columnas
/// (o una lista), con indicadores, búsqueda por cliente y filtro por deporte.
class FixedSessionsTab extends StatefulWidget {
  const FixedSessionsTab({super.key});

  @override
  State<FixedSessionsTab> createState() => _FixedSessionsTabState();
}

class _FixedSessionsTabState extends State<FixedSessionsTab> with ReloadOnDataChange {
  final _repository = sl<FixedSessionRepository>();
  final _search = TextEditingController();

  bool _loading = true;
  String? _error;
  List<FixedSession> _items = [];
  String? _sport;
  /// null = la de default: lista en el celular, semana en pantallas anchas.
  _View? _selectedView;
  _View get _view => _selectedView ?? (ResponsiveBuilder.isMobile(context) ? _View.list : _View.week);

  bool get _canCreate => Permissions.can(Permissions.TURNOS_FIJOS_CREAR);
  bool get _canCancel => Permissions.can(Permissions.TURNOS_FIJOS_CANCELAR);

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.fixedSessions};

  /// En vivo: sin spinner, la lista se reemplaza cuando llega.
  @override
  void onDataChanged(DataChange change) => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final result = await _repository.list();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Right(:final value):
          _items = value;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  List<String> get _sports => {for (final f in _items) f.sport ?? 'Otros'}.toList()..sort();

  List<FixedSession> get _visible {
    final query = _search.text.trim().toLowerCase();
    return _items.where((f) {
      if (_sport != null && (f.sport ?? 'Otros') != _sport) return false;
      if (query.isEmpty) return true;
      return f.members.any((m) => m.fullName.toLowerCase().contains(query));
    }).toList()
      ..sort((a, b) => _weekIndex(a.dayOfWeek).compareTo(_weekIndex(b.dayOfWeek)) != 0
          ? _weekIndex(a.dayOfWeek).compareTo(_weekIndex(b.dayOfWeek))
          : a.startTime.compareTo(b.startTime));
  }

  static int _weekIndex(int day) => fixedSessionWeekOrder.indexOf(day);

  Future<void> _create({int? day}) async {
    if (await openNewFixedSession(context, dayOfWeek: day) != null) _load();
  }

  Future<void> _onAction(String action, FixedSession item) async {
    final place = [item.sport, item.courtName].whereType<String>().join(' · ');
    final changed = switch (action) {
      'participants' => await editFixedSessionParticipants(context, item) != null,
      'cancel' => await cancelFixedSession(context, item.ref, place: place),
      _ => false,
    };
    if (changed) _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());

    final visible = _visible;
    final hours = _items.fold<int>(0, (sum, f) => sum + f.duration) / 60;
    final conflicts = _items.where((f) => f.hasConflicts).length;

    final isMobile = ResponsiveBuilder.isMobile(context);
    final hoursLabel = '${hours == hours.roundToDouble() ? hours.toInt() : hours.toStringAsFixed(1)} h';
    final search = TourAnchor(id: 'fixed.search', child: TextField(
      controller: _search,
      decoration: const InputDecoration(
        hintText: 'Buscar cliente',
        prefixIcon: Icon(Icons.search),
        isDense: true,
        border: OutlineInputBorder(),
      ),
    ));
    final viewToggle = TourAnchor(id: 'fixed.view', child: SegmentedButton<_View>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: _View.week, label: Text('Semana'), icon: Icon(Icons.view_week_outlined)),
        ButtonSegment(value: _View.list, label: Text('Lista'), icon: Icon(Icons.view_list_outlined)),
      ],
      selected: {_view},
      onSelectionChanged: (s) => setState(() => _selectedView = s.first),
    ));
    final sportChips = [
      ChoiceChip(label: const Text('Todos'), selected: _sport == null, onSelected: (_) => setState(() => _sport = null)),
      for (final sport in _sports)
        ChoiceChip(label: Text(sport), selected: _sport == sport, onSelected: (_) => setState(() => _sport = sport)),
    ];

    // Celular: cada bloque a todo el ancho (en el Wrap de escritorio las
    // stats, el buscador y los botones quedaban desparejos).
    final mobileHeader = <Widget>[
      TourAnchor(id: 'fixed.stats', child: IntrinsicHeight(
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _StatTile(label: 'Activos', value: '${_items.length}')),
          const SizedBox(width: 8),
          Expanded(child: _StatTile(label: 'Horas por semana', value: hoursLabel)),
          const SizedBox(width: 8),
          Expanded(child: _StatTile(label: 'Con conflictos', value: '$conflicts', alert: conflicts > 0)),
        ],
      ),
      )),
      const SizedBox(height: 12),
      search,
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: sportChips),
      const SizedBox(height: 12),
      Row(
        children: [
          viewToggle,
          const Spacer(),
          if (_canCreate)
            TourAnchor(id: 'fixed.new', child: FilledButton.icon(onPressed: () => _create(), icon: const Icon(Icons.add), label: const Text('Nuevo'))),
        ],
      ),
    ];

    return Padding(
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile) ...mobileHeader else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TourAnchor(
                id: 'fixed.stats',
                child: Wrap(spacing: 12, runSpacing: 12, children: [
                  _StatTile(label: 'Activos', value: '${_items.length}'),
                  _StatTile(label: 'Horas por semana', value: hoursLabel),
                  _StatTile(label: 'Con conflictos', value: '$conflicts', alert: conflicts > 0),
                ]),
              ),
              const SizedBox(width: 12),
              TourAnchor(
                id: 'fixed.search',
                child: SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: 'Buscar cliente',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              ChoiceChip(label: const Text('Todos'), selected: _sport == null, onSelected: (_) => setState(() => _sport = null)),
              for (final sport in _sports)
                ChoiceChip(label: Text(sport), selected: _sport == sport, onSelected: (_) => setState(() => _sport = sport)),
              viewToggle,
              if (_canCreate)
                TourAnchor(
                  id: 'fixed.new',
                  child: FilledButton.icon(
                    onPressed: () => _create(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo turno fijo'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(_error!, style: TextStyle(color: scheme.error))
          else
            Expanded(child: TourAnchor(id: 'fixed.board', child: _view == _View.week ? _week(visible) : _list(visible))),
        ],
      ),
    );
  }

  Widget _week(List<FixedSession> visible) {
    // Celular: los 7 días no entran a lo ancho; columnas de ancho fijo con
    // scroll horizontal.
    if (ResponsiveBuilder.isMobile(context)) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: 7 * 260 + 6 * 12, child: _weekRow(visible)),
      );
    }
    return _weekRow(visible);
  }

  Widget _weekRow(List<FixedSession> visible) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, day) in fixedSessionWeekOrder.indexed) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
              child: Builder(builder: (context) {
                final items = visible.where((f) => f.dayOfWeek == day).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(fixedSessionDayNames[day], style: Theme.of(context).textTheme.titleSmall)),
                          Text(items.isEmpty ? '—' : '${items.length}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final item in items) ...[
                            _FixedCard(
                              item: item,
                              actions: _actionsMenu(item),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                    if (_canCreate)
                      OutlinedButton(
                        onPressed: () => _create(day: day),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: scheme.outlineVariant),
                          foregroundColor: scheme.onSurfaceVariant,
                        ),
                        child: const Text('+ Agregar'),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _actionsMenu(FixedSession item) {
    if (!_canCreate && !_canCancel) return null;
    return PopupMenuButton<String>(
      tooltip: 'Acciones',
      iconSize: 18,
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => _onAction(action, item),
      itemBuilder: (_) => [
        if (_canCreate) const PopupMenuItem(value: 'participants', child: Text('Integrantes')),
        if (_canCancel) const PopupMenuItem(value: 'cancel', child: Text('Cancelar…')),
      ],
    );
  }

  Widget _list(List<FixedSession> visible) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (visible.isEmpty) {
      return Text(
        _items.isEmpty ? 'Todavía no hay turnos fijos cargados.' : 'Ningún turno fijo coincide con la búsqueda.',
        style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      );
    }
    return SingleChildScrollView(
      child: AdminTableCard(
          child: LayoutBuilder(
            builder: (context, constraints) => AdminTableScroll(
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: AdminDataTable(
                  columns: ['Día y hora', adminVocabulary().space.singular, 'Titular', 'Integrantes', 'Próximo turno', ''],
                  columnWidths: const {3: FlexColumnWidth()},
                  rows: [
                    for (final item in visible)
                      [
                        Text('${item.dayName} ${item.startTime} · ${item.duration} min'),
                        Text([item.sport, item.courtName].whereType<String>().join(' · ')),
                        ClientLink(clientId: item.client.clientId, name: item.client.fullName),
                        item.participants.isEmpty
                            ? const Text('—')
                            : ClientLinksText.people([for (final p in item.participants) (p.clientId, p.fullName)]),
                        _FixedFooter(item: item),
                        _actionsMenu(item) ?? const SizedBox(width: 40),
                      ],
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.alert = false});

  final String label;
  final String value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant)),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: alert ? scheme.error : scheme.onSurface)),
        ],
      ),
    );
  }
}

/// Tarjeta de un turno fijo en la columna de su día.
class _FixedCard extends StatelessWidget {
  const _FixedCard({required this.item, this.actions});

  final FixedSession item;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final first = item.participants.isEmpty ? null : item.participants.first;
    final members = <LinkSegment>[
      if (first == null)
        const LinkSegment.text('Sin integrantes')
      else ...[
        const LinkSegment.text('Con '),
        LinkSegment.client(first.clientId, first.fullName),
        if (item.participants.length > 1) LinkSegment.text(' y ${item.participants.length - 1} más'),
      ],
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.hasConflicts ? scheme.errorContainer : scheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.startTime, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
              Text('${item.duration} min', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant)),
              if (actions != null) SizedBox(width: 32, height: 32, child: actions),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
            child: Text(
              [item.sport, item.courtName].whereType<String>().join(' · '),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: scheme.onSecondaryContainer),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  _initials(item.client.fullName),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: ClientLink(clientId: item.client.clientId, name: item.client.fullName, style: textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClientLinksText(members, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 6),
          _FixedFooter(item: item),
        ],
      ),
    );
  }

  static String _initials(String name) =>
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
}

/// Próximo turno, o el aviso de un día ocupado / cancelado.
class _FixedFooter extends StatelessWidget {
  const _FixedFooter({required this.item});

  final FixedSession item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, String text, Color color) = item.hasConflicts
        ? (
            Icons.warning_amber_rounded,
            '${item.missingDates.map(FixedSessionTexts.shortDate).join(', ')}: horario ocupado',
            scheme.error,
          )
        : item.upcoming.isEmpty
            ? (Icons.schedule, 'Sin turnos cargados', scheme.onSurfaceVariant)
            : (
                Icons.schedule,
                'Próx. ${DateFormat('EEE dd/MM', 'es').format(item.upcoming.first.startTime.toLocal())}'
                    '${item.cancelledDates.isEmpty ? '' : ' · ${item.cancelledDates.length} cancelado${item.cancelledDates.length == 1 ? '' : 's'}'}',
                scheme.onSurfaceVariant,
              );
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: TextStyle(fontSize: 12, color: color))),
      ],
    );
  }
}
