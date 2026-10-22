import 'package:flutter/material.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/links/entity_links.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../domain/entities/membership/membership.dart';
import '../../../domain/repositories/membership_repository.dart';
import '../club_config/widgets/admin_data_table.dart';
import 'membership_dialogs.dart';
import 'register_payment_dialog.dart';
import 'widgets/membership_widgets.dart';

/// Pagos › Estado de cuotas: quién está al día y quién debe. Las tarjetas de
/// arriba filtran la lista. Solo existe si el admin ve servicios con abonos.
class MembershipBoardView extends StatefulWidget {
  const MembershipBoardView({super.key});

  @override
  State<MembershipBoardView> createState() => _MembershipBoardViewState();
}

class _MembershipBoardViewState extends State<MembershipBoardView> {
  final _repository = sl<MembershipRepository>();
  MembershipBoard? _board;
  String? _error;
  MembershipStatus _filter = MembershipStatus.late;
  bool _filterChosen = false;
  String _search = '';
  String? _plan;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repository.board();
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Right(:final value):
          _board = value;
          _error = null;
          // Arranca en lo más urgente que tenga algo.
          if (!_filterChosen) {
            _filter = const [MembershipStatus.late, MembershipStatus.soon, MembershipStatus.pendingFirst, MembershipStatus.ok, MembershipStatus.paused]
                    .firstWhere((s) => (value.counts[s] ?? 0) > 0, orElse: () => MembershipStatus.late);
          }
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  Future<void> _after(Future<Object?> action) async {
    final result = await action;
    if (result != null && result != false) _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final board = _board;
    final mobile = ResponsiveBuilder.isMobile(context);

    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), TextButton(onPressed: _load, child: const Text('Reintentar'))]));
    }
    if (board == null) return const Center(child: CircularProgressIndicator());

    final plans = {for (final row in board.rows) row.plan.name}.toList()..sort();
    final query = _search.trim().toLowerCase();
    final rows = board.rows
        .where((r) => r.status == _filter)
        .where((r) => _plan == null || r.plan.name == _plan)
        .where((r) => query.isEmpty || r.clientName.toLowerCase().contains(query))
        .toList();
    final remindable = rows.where((r) => r.status != MembershipStatus.ok && r.status != MembershipStatus.paused).toList();

    String sub(MembershipStatus status) => switch (status) {
          MembershipStatus.late => board.lateDebt > 0 ? '${money(board.lateDebt)} sin cobrar' : 'Nadie debe',
          MembershipStatus.soon => 'Del ${dayLabel(board.soonFrom)} al ${dayLabel(board.soonTo)}',
          MembershipStatus.ok => 'Cobrado este mes: ${money(board.collectedThisMonth)}',
          MembershipStatus.pendingFirst => 'Altas sin pago',
          MembershipStatus.paused => 'No suman deuda ni reciben avisos',
          MembershipStatus.ended => '',
        };
    String title(MembershipStatus status) => switch (status) {
          MembershipStatus.late => 'Vencidas',
          MembershipStatus.soon => 'Vencen en 7 días',
          _ => status.label,
        };

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(mobile ? 16 : 24),
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000 ? 5 : (constraints.maxWidth >= 600 ? 3 : 2);
            final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              for (final status in const [MembershipStatus.late, MembershipStatus.soon, MembershipStatus.ok, MembershipStatus.pendingFirst, MembershipStatus.paused])
                SizedBox(
                  width: width,
                  child: _KpiCard(
                    status: status,
                    title: title(status),
                    value: board.counts[status] ?? 0,
                    subtitle: sub(status),
                    selected: _filter == status,
                    onTap: () => setState(() {
                      _filter = status;
                      _filterChosen = true;
                    }),
                  ),
                ),
            ]);
          }),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(title(_filter), style: textTheme.titleMedium),
                  SizedBox(
                    width: 240,
                    child: TextField(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar cliente', border: OutlineInputBorder(), isDense: true),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  if (plans.length > 1)
                    PopupMenuButton<String?>(
                      tooltip: 'Filtrar por abono',
                      onSelected: (v) => setState(() => _plan = v),
                      itemBuilder: (_) => [
                        const PopupMenuItem<String?>(value: null, child: Text('Todos los abonos')),
                        for (final p in plans) PopupMenuItem<String?>(value: p, child: Text(p)),
                      ],
                      child: Chip(label: Text(_plan ?? 'Todos los abonos'), avatar: const Icon(Icons.arrow_drop_down, size: 18)),
                    ),
                  if (remindable.length > 1)
                    OutlinedButton(
                      onPressed: () => _after(showReminderDialog(context, remindable)),
                      child: Text('Avisar a todos (${remindable.length})'),
                    ),
                ]),
                const SizedBox(height: 14),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      board.rows.isEmpty ? 'Todavía nadie tiene un abono.' : 'No hay clientes en este estado.',
                      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  )
                else
                  AdminDataTable(
                    columns: const ['Cliente', 'Abono', 'Estado', 'Vencimiento', 'Debe', 'Último pago', ''],
                    columnWidths: const {
                      0: FlexColumnWidth(1.4),
                      1: FlexColumnWidth(1.3),
                      2: FlexColumnWidth(1.1),
                      3: FlexColumnWidth(1.1),
                      4: FlexColumnWidth(0.9),
                      5: FlexColumnWidth(1.1),
                      6: FixedColumnWidth(232),
                    },
                    rows: [for (final row in rows) _row(context, row)],
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _row(BuildContext context, Membership m) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final note = switch (m.status) {
      MembershipStatus.paused => [m.pause?.reason, m.pause?.end == null ? 'sin fecha de vuelta' : 'vuelve el ${dayLabel(m.pause!.end!)}'].whereType<String>().join(' · '),
      MembershipStatus.pendingFirst => 'Empezó hace ${daysSince(m.startDate)} días',
      _ => m.lastReminderAt != null ? 'Avisado el ${dayLabel(m.lastReminderAt!)}' : (m.owes ? 'Sin avisar' : ''),
    };
    final (statusLabel, due) = switch (m.status) {
      MembershipStatus.late => ('Hace ${m.daysOverdue} ${m.daysOverdue == 1 ? 'día' : 'días'}', m.unpaidCount > 1 ? '${dayLabel(m.overdueSince!)} · ${m.unpaidCount} cuotas' : dayLabel(m.overdueSince!)),
      MembershipStatus.soon when m.inGrace => ('En gracia', dayLabel(m.overdueSince!)),
      MembershipStatus.soon => (_inDays(m.nextDueDate!), dayLabel(m.nextDueDate!)),
      MembershipStatus.pendingFirst => ('Sin primer pago', 'Alta el ${dayLabel(m.startDate)}'),
      MembershipStatus.paused => ('En pausa', 'Desde el ${dayLabel(m.pause!.start)}'),
      MembershipStatus.ok => ('Al día', m.nextDueDate == null ? '—' : dayLabel(m.nextDueDate!)),
      MembershipStatus.ended => ('Terminado', '—'),
    };
    final canPay = Permissions.can(Permissions.PAGOS_REGISTRAR);
    return [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClientLink(clientId: m.clientId, name: m.clientName),
        if (note.isNotEmpty) Text(note, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ]),
      Text(m.plan.name),
      Align(alignment: Alignment.centerLeft, child: MembershipStatusChip(status: m.status, label: statusLabel)),
      Text(due),
      Align(
        alignment: Alignment.centerRight,
        child: Text(m.debt > 0 ? money(m.debt) : '—', style: const TextStyle(fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()])),
      ),
      Text(m.lastPaymentDate == null ? '—' : dayLabel(m.lastPaymentDate!), style: TextStyle(color: scheme.onSurfaceVariant)),
      Wrap(alignment: WrapAlignment.end, spacing: 6, runSpacing: 6, children: [
        if (m.status != MembershipStatus.ok && m.status != MembershipStatus.paused)
          OutlinedButton(onPressed: () => _after(showReminderDialog(context, [m])), child: const Text('Avisar')),
        if (canPay && m.status != MembershipStatus.paused)
          FilledButton(onPressed: () => _after(showRegisterPaymentDialog(context, membership: m)), child: const Text('Registrar pago')),
        if (m.status == MembershipStatus.paused && Permissions.can(Permissions.CLIENTES_ABONOS))
          OutlinedButton(onPressed: () => _after(showResumeDialog(context, m)), child: const Text('Retomar')),
      ]),
    ];
  }

  static String _inDays(DateTime date) {
    final days = -daysSince(date);
    if (days <= 0) return 'Vence hoy';
    return days == 1 ? 'Mañana' : 'En $days días';
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.status, required this.title, required this.value, required this.subtitle, required this.selected, required this.onTap});

  final MembershipStatus status;
  final String title;
  final int value;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colors = statusColors(scheme, status);
    final dotColor = switch (status) {
      MembershipStatus.late => scheme.error,
      MembershipStatus.soon => scheme.primary,
      MembershipStatus.ok => scheme.secondary,
      _ => scheme.outline,
    };
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: selected ? scheme.primary : Colors.transparent)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.dashed ? Colors.transparent : dotColor,
                    border: colors.dashed ? Border.all(color: dotColor, width: 2) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: textTheme.labelLarge)),
              ]),
              const SizedBox(height: 6),
              Text('$value', style: textTheme.headlineMedium),
              Text(subtitle, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      ),
    );
  }
}
