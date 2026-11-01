import 'package:flutter/material.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/permissions.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/membership/membership.dart';
import '../../../domain/repositories/membership_repository.dart';
import '../../../domain/repositories/subscription_repository.dart';
import '../client_page/client_page.dart';
import 'membership_dialogs.dart';
import 'register_payment_dialog.dart';
import 'widgets/membership_widgets.dart';
import '../../../core/services/data_changes.dart';

/// Card "Abono" de la ficha para servicios con abonos con cuotas: el abono,
/// si está al día o debe, las últimas cuotas, pausas y las acciones (pagar,
/// avisar, pausar, retomar, cambiar, dar de baja). Solo se muestra si el
/// admin ve algún servicio con abonos (`AdminFeatures.memberships`).
class ClientMembershipCard extends StatefulWidget {
  const ClientMembershipCard({super.key, required this.client, required this.onChanged});

  final Client client;

  /// Algo cambió (un pago, una pausa): la ficha recarga pagos e indicadores.
  final VoidCallback onChanged;

  @override
  State<ClientMembershipCard> createState() => _ClientMembershipCardState();
}

class _ClientMembershipCardState extends State<ClientMembershipCard> with ReloadOnDataChange {
  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.gym, DataTopic.payments};

  @override
  bool shouldReload(DataChange change) => change.isFor('client_id', widget.client.intClientId);

  /// En vivo: una cuota, pausa o cambio de plan de este cliente (acá o desde otro lado).
  @override
  void onDataChanged(DataChange change) => _load();
  final _repository = sl<MembershipRepository>();
  ClientMemberships? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ClientMembershipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Un abono nuevo o dado de baja desde otro lado de la ficha.
    if (oldWidget.client.clientSubscriptions?.length != widget.client.clientSubscriptions?.length ||
        oldWidget.client.clientSubscriptions?.where((s) => s.isActive).length != widget.client.clientSubscriptions?.where((s) => s.isActive).length) {
      _load();
    }
  }

  Future<void> _load() async {
    final result = await _repository.clientMemberships(widget.client.intClientId);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Right(:final value):
          _data = value;
          _error = null;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  void _changed() {
    _load();
    widget.onChanged();
  }

  Future<void> _run(Future<Object?> Function() action) async {
    final result = await action();
    if (result != null && result != false) _changed();
  }

  Future<void> _assign() async {
    final created = await showAssignMembershipDialog(context, clientId: widget.client.intClientId, clientName: widget.client.person?.fullName.trim() ?? 'el cliente');
    if (created == null || !mounted) return;
    final inherited = ClientInherited.of(context);
    inherited?.updateClient(widget.client.copyWith(clientSubscriptions: [created, ...widget.client.clientSubscriptions ?? []]));
    _changed();
  }

  Future<void> _changePlan(Membership membership) async {
    final plans = await _repository.plans();
    if (!mounted) return;
    final all = plans.when(left: (_) => const <MembershipPlan>[], right: (value) => value.expand((p) => p.plans).toList());
    await _run(() => showChangePlanDialog(context, membership, all));
  }

  Future<void> _unsubscribe(Membership membership) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dar de baja el abono'),
        content: Text(membership.owes
            ? '${membership.clientName} debe ${money(membership.debt)}. La deuda queda registrada en el abono, pero deja de figurar en el estado de cuotas.'
            : '¿Dar de baja "${membership.plan.name}" de ${membership.clientName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Dar de baja'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final result = await sl<SubscriptionRepository>().unSubscribeClient(membership.id, widget.client.intClientId);
    if (!mounted) return;
    result.when(
      left: (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
      right: (_) => _changed(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final data = _data;

    Widget body;
    if (_error != null) {
      body = Row(children: [Expanded(child: Text(_error!)), TextButton(onPressed: _load, child: const Text('Reintentar'))]);
    } else if (data == null) {
      body = const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator());
    } else if (data.active.isEmpty) {
      body = Row(children: [
        Expanded(
          child: Text(
            data.previous.isEmpty ? 'No tiene un abono del gimnasio.' : 'No tiene un abono activo.',
            style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        if (Permissions.can(Permissions.CLIENTES_ABONOS)) FilledButton.icon(onPressed: _assign, icon: const Icon(Icons.add, size: 18), label: const Text('Asignar abono')),
      ]);
    } else {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final (i, membership) in data.active.indexed) ...[
          if (i > 0) const Divider(height: 32),
          _MembershipBody(
            membership: membership,
            onPay: () => _run(() => showRegisterPaymentDialog(context, client: widget.client, membership: membership)),
            onRemind: () => _run(() => showReminderDialog(context, [membership])),
            onPause: () => _run(() => showPauseDialog(context, membership)),
            onEditPause: () => _run(() => showEditPauseDialog(context, membership)),
            onResume: () => _run(() => showResumeDialog(context, membership)),
            onChangePlan: () => _changePlan(membership),
            onUnsubscribe: () => _unsubscribe(membership),
          ),
        ],
      ]);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Abono', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          body,
          if (data != null && data.previous.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Abonos anteriores (${data.previous.length})', style: textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                children: [
                  for (final m in data.previous)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text('${m.plan.partitionName.isEmpty ? '' : '${m.plan.partitionName} · '}${m.plan.name}'),
                      subtitle: Text(
                        '${dayLabel(m.startDate)} – ${m.endDate == null ? 'hoy' : dayLabel(m.endDate!)} · ${m.debt > 0 ? 'terminó debiendo ${money(m.debt)}' : 'terminó al día'}',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _MembershipBody extends StatelessWidget {
  const _MembershipBody({
    required this.membership,
    required this.onPay,
    required this.onRemind,
    required this.onPause,
    required this.onEditPause,
    required this.onResume,
    required this.onChangePlan,
    required this.onUnsubscribe,
  });

  final Membership membership;
  final VoidCallback onPay;
  final VoidCallback onRemind;
  final VoidCallback onPause;
  final VoidCallback onEditPause;
  final VoidCallback onResume;
  final VoidCallback onChangePlan;
  final VoidCallback onUnsubscribe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final m = membership;
    final canManage = Permissions.can(Permissions.CLIENTES_ABONOS);
    final canPay = Permissions.can(Permissions.PAGOS_REGISTRAR);
    final paused = m.status == MembershipStatus.paused;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.plan.name, style: textTheme.titleLarge),
            Text(
              [
                if (m.plan.partitionName.isNotEmpty) m.plan.partitionName,
                '${money(m.plan.price)} por mes',
                paused ? (m.plan.billingMode == BillingMode.fixedDay ? 'vence el día ${m.plan.billingDay}' : 'en pausa') : dueDescription(m),
                'desde el ${dayLabel(m.startDate)} ${m.startDate.year}',
              ].join(' · '),
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ]),
          if (canManage)
            Wrap(spacing: 8, children: [
              if (!paused) OutlinedButton.icon(onPressed: onPause, icon: const Icon(Icons.pause, size: 16), label: const Text('Pausar')),
              OutlinedButton(onPressed: onChangePlan, child: const Text('Cambiar abono')),
              TextButton(onPressed: onUnsubscribe, child: const Text('Dar de baja')),
            ]),
        ],
      ),
      const SizedBox(height: 14),
      _StatusBanner(membership: m, canPay: canPay, canManage: canManage, onPay: onPay, onRemind: onRemind, onEditPause: onEditPause, onResume: onResume),
      if (m.periods.isNotEmpty || m.pauses.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text('Últimas cuotas', style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        MembershipStrip(items: membershipStrip(m)),
      ],
      if (m.pauses.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Pausas', style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        for (final pause in m.pauses.reversed)
          Text(
            '${dayLabel(pause.start)} – ${pause.end == null ? 'hoy' : dayLabel(pause.end!)}${pause.reason != null ? ' · ${pause.reason}' : ''}',
            style: textTheme.bodySmall,
          ),
      ],
    ]);
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.membership,
    required this.canPay,
    required this.canManage,
    required this.onPay,
    required this.onRemind,
    required this.onEditPause,
    required this.onResume,
  });

  final Membership membership;
  final bool canPay;
  final bool canManage;
  final VoidCallback onPay;
  final VoidCallback onRemind;
  final VoidCallback onEditPause;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final m = membership;
    final colors = statusColors(scheme, m.status);
    final reminder = m.lastReminderAt == null ? '' : ' Le avisaste el ${dayLabel(m.lastReminderAt!)}.';

    final (IconData icon, String title, String detail) = switch (m.status) {
      MembershipStatus.late => (
          Icons.error_outline,
          m.unpaidCount > 1
              ? '${m.unpaidCount} cuotas vencidas · la primera hace ${m.daysOverdue} días'
              : 'Cuota de ${monthLong(m.overdueSince!)} vencida hace ${m.daysOverdue} ${m.daysOverdue == 1 ? 'día' : 'días'}',
          'Vencía el ${dayLabel(m.overdueSince!)} (gracia hasta el ${dayLabel(m.overdueSince!.add(Duration(days: m.plan.graceDays)))}). Debe ${money(m.debt)}.$reminder',
        ),
      MembershipStatus.soon when m.inGrace => (
          Icons.schedule,
          'Venció el ${dayLabel(m.overdueSince!)} · en gracia',
          'Pasa a vencida después del ${dayLabel(m.overdueSince!.add(Duration(days: m.plan.graceDays)))}. Debe ${money(m.debt)}.$reminder',
        ),
      MembershipStatus.soon => (
          Icons.schedule,
          'Vence el ${weekdayLabel(m.nextDueDate!)}',
          '${money(m.nextDueAmount ?? m.plan.price)} · al día hasta entonces.$reminder',
        ),
      MembershipStatus.pendingFirst => (
          Icons.hourglass_empty,
          'Todavía no pagó la primera cuota',
          'Arrancó el ${dayLabel(m.startDate)}. Debe ${money(m.debt > 0 ? m.debt : (m.nextDueAmount ?? m.plan.price))}.',
        ),
      MembershipStatus.paused => (
          Icons.pause,
          'En pausa desde el ${dayLabel(m.pause!.start)} · hace ${daysSince(m.pause!.start)} días',
          [
            if (m.pause!.reason != null) m.pause!.reason!,
            m.pause!.end == null ? 'hasta que vuelva' : 'vuelve el ${dayLabel(m.pause!.end!)}',
            'No genera cuotas ni avisos.',
            if (m.pause!.adminName != null) 'Pausó ${m.pause!.adminName}.',
            if (m.debt > 0) 'Debe ${money(m.debt)} de antes.',
          ].join(' · '),
        ),
      MembershipStatus.ok => (
          Icons.check_circle_outline,
          'Al día hasta el ${dayLabel(m.paidUntil!)}',
          [if (m.lastPaymentDate != null) 'Último pago el ${dayLabel(m.lastPaymentDate!)}${m.lastPaymentMethod != null ? ' · ${m.lastPaymentMethod}' : ''}.'].join(' '),
        ),
      MembershipStatus.ended => (Icons.block, 'Terminado', ''),
    };

    final buttons = <Widget>[
      if (m.status == MembershipStatus.paused) ...[
        if (canManage) TextButton(onPressed: onEditPause, child: const Text('Editar pausa')),
        if (canManage) FilledButton(onPressed: onResume, child: const Text('Retomar')),
      ] else ...[
        if (m.status != MembershipStatus.ok)
          OutlinedButton(
            onPressed: onRemind,
            style: OutlinedButton.styleFrom(foregroundColor: colors.foreground, side: BorderSide(color: colors.foreground)),
            child: Text(m.lastReminderAt == null ? 'Avisar' : 'Avisar de nuevo'),
          ),
        if (canPay)
          m.status == MembershipStatus.ok
              ? OutlinedButton(onPressed: onPay, child: const Text('Registrar pago'))
              : FilledButton(
                  onPressed: onPay,
                  style: m.status == MembershipStatus.late ? FilledButton.styleFrom(backgroundColor: scheme.onErrorContainer, foregroundColor: scheme.errorContainer) : null,
                  child: const Text('Registrar pago'),
                ),
      ],
    ];

    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: m.status == MembershipStatus.paused ? scheme.surfaceContainerHighest : colors.background,
        borderRadius: BorderRadius.circular(12),
        border: colors.border != null && !colors.dashed ? Border.all(color: colors.border!) : null,
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: colors.foreground),
              const SizedBox(width: 12),
              Flexible(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: textTheme.titleSmall?.copyWith(color: colors.foreground)),
                  if (detail.isNotEmpty) Text(detail, style: textTheme.bodySmall?.copyWith(color: colors.foreground)),
                ]),
              ),
            ]),
          ),
          if (buttons.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: buttons),
        ],
      ),
    );
    if (!colors.dashed) return content;
    return CustomPaint(painter: DashedRRectPainter(color: colors.border!, radius: 12), child: content);
  }
}
