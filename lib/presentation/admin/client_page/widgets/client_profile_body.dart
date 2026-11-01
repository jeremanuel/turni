import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/router/app_routes.dart';
import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/links/entity_links.dart';
import '../../../../core/presentation/components/loading/app_skeleton.dart';
import '../../../../core/utils/admin_features.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/client_summary.dart';
import '../../../../domain/entities/person.dart';
import '../../../../domain/repositories/fixed_session_repository.dart';
import '../../memberships/client_membership_card.dart';
import '../../memberships/register_payment_dialog.dart';
import 'client_payments_card.dart';
import 'client_notifications_card.dart';
import 'client_fixed_sessions.dart';
import 'client_routine_card.dart';
import '../../../../core/presentation/components/onboarding/tour_anchor.dart';

/// Cuerpo de la ficha del cliente (rediseño): encabezado con datos y
/// acciones, indicadores, turnos fijos, próximos turnos, pagos y, al costado,
/// abono, etiquetas, notas y actividad. Cada sección aparece solo si tiene
/// sentido para lo que ve el admin ([AdminFeatures]): la rutina, si ve algún
/// gimnasio; el abono con cuotas, si ve algún servicio con abonos.
///
/// [subscription] y [labels] son los componentes de siempre de la ficha; acá
/// solo se acomodan. [editor] reemplaza al encabezado mientras se editan los
/// datos. [categories] (torneos) va debajo de los pagos.
class ClientProfileBody extends StatefulWidget {
  const ClientProfileBody({
    super.key,
    required this.client,
    required this.isEditing,
    required this.onEdit,
    required this.editor,
    required this.subscription,
    required this.labels,
    this.categories,
  });

  final Client client;
  final bool isEditing;
  final VoidCallback onEdit;
  final Widget editor;
  final Widget subscription;
  final Widget labels;
  final Widget? categories;

  @override
  State<ClientProfileBody> createState() => _ClientProfileBodyState();
}

class _ClientProfileBodyState extends State<ClientProfileBody> {
  final _repository = sl<FixedSessionRepository>();
  ClientSummary? _summary;
  String? _summaryError;

  /// Sube cuando cambia algo de plata (un pago, una pausa): recarga las cards.
  int _paymentsVersion = 0;

  void _moneyChanged() {
    _loadSummary();
    setState(() => _paymentsVersion++);
  }

  /// La card "Abono" de siempre, para abonos que no son con cuotas (o si el
  /// admin no ve ningún servicio con cuotas).
  bool get _showLegacySubscription {
    if (!AdminFeatures.memberships) return true;
    return widget.client.clientSubscriptions?.any((s) =>
            s.isActive && s.subscription.subscriptionType != 'FIXED_SESSION' && !AdminFeatures.isMembershipPartition(s.subscription.clubPartitionId)) ??
        false;
  }

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final result = await _repository.clientSummary(widget.client.intClientId);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Right(:final value):
          _summary = value;
          _summaryError = null;
        case Left(:final failure):
          _summaryError = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final desktop = ResponsiveBuilder.isDesktop(context);

    // Los TourAnchor son los pasos de la guía de la ficha (admin_guides.dart).
    // El de la rutina va adentro de ClientRoutineCard: abre el editor.
    final main = <Widget>[
      TourAnchor(id: 'client.fixed', child: ClientFixedSessions(key: ValueKey('fixed-${widget.client.clientId}'), client: widget.client, onChanged: _loadSummary)),
      if (AdminFeatures.routines) ClientRoutineCard(key: ValueKey('routine-${widget.client.clientId}'), client: widget.client),
      if (AdminFeatures.memberships)
        TourAnchor(
          id: 'client.membership',
          child: ClientMembershipCard(key: ValueKey('membership-${widget.client.clientId}-$_paymentsVersion'), client: widget.client, onChanged: _moneyChanged),
        ),
      TourAnchor(id: 'client.upcoming', child: _UpcomingCard(summary: _summary, error: _summaryError)),
      TourAnchor(
        id: 'client.payments',
        child: ClientPaymentsCard(key: ValueKey('payments-${widget.client.clientId}-$_paymentsVersion'), client: widget.client, onPaid: _moneyChanged),
      ),
      if (widget.categories != null) TourAnchor(id: 'client.categories', child: widget.categories!),
    ];
    final side = <Widget>[
      if (_showLegacySubscription) _SideCard(title: 'Abono', child: widget.subscription),
      TourAnchor(id: 'client.labels', child: Card(margin: EdgeInsets.zero, child: widget.labels)),
      TourAnchor(id: 'client.notes', child: _NotesCard(client: widget.client, onEdit: widget.onEdit)),
      TourAnchor(id: 'client.activity', child: _ActivityCard(summary: _summary, error: _summaryError)),
      TourAnchor(
        id: 'client.notifications',
        child: ClientNotificationsCard(key: ValueKey('notifications-${widget.client.clientId}'), clientId: widget.client.intClientId),
      ),
    ];

    Widget column(List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final (i, child) in children.indexed) ...[if (i > 0) const SizedBox(height: 20), child]],
        );

    return SingleChildScrollView(
      padding: EdgeInsets.all(desktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isEditing)
            widget.editor
          else
            TourAnchor(id: 'client.header', child: _HeaderCard(client: widget.client, onEdit: widget.onEdit, onPaymentCreated: _moneyChanged)),
          const SizedBox(height: 20),
          TourAnchor(id: 'client.kpis', child: _KpiRow(summary: _summary, loading: _summary == null && _summaryError == null)),
          const SizedBox(height: 20),
          if (desktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: column(main)),
                const SizedBox(width: 20),
                Expanded(child: column(side)),
              ],
            )
          else
            column([...main, ...side]),
        ],
      ),
    );
  }
}

String _money(num value) => '\$ ${ThousandsFormat.formatPrice(value)}';

String _initials(String name) =>
    name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.client, required this.onEdit, required this.onPaymentCreated});

  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onPaymentCreated;

  Future<void> _whatsApp() async {
    final digits = (client.person?.phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    await launchUrl(Uri.parse('https://wa.me/$digits'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final person = client.person;
    final name = person?.fullName.trim() ?? 'Cliente';
    final birth = person?.birdDate;
    final age = birth == null ? null : (DateTime.now().difference(birth).inDays / 365.25).floor();
    final facts = <String>[
      if ((person?.phone ?? '').isNotEmpty) person!.phone!,
      if ((person?.email ?? '').isNotEmpty) person!.email!,
      if (age != null) '$age años',
    ];
    final labels = client.labels ?? const [];

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if ((person?.phone ?? '').isNotEmpty)
          OutlinedButton.icon(onPressed: _whatsApp, icon: const Icon(Icons.chat_outlined, size: 18), label: const Text('WhatsApp')),
        if (Permissions.can(Permissions.CLIENTES_EDITAR))
          OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Editar datos')),
        RegisterPaymentButton(client: client, onPaid: onPaymentCreated),
        if (Permissions.can(Permissions.AGENDA_RESERVAR))
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.SESSION_MANAGER_ROUTE.path),
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: const Text('Reservar turno'),
          ),
      ],
    );

    // Celular: avatar y datos en una fila, acciones abajo alineadas a la
    // izquierda (el Wrap de escritorio dejaba todo desparejo).
    if (ResponsiveBuilder.isMobile(context)) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(_initials(name), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: scheme.onPrimaryContainer)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
                        if (client.userId != null || labels.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (client.userId != null) _Tag(label: 'Usa la app', filled: true),
                              for (final label in labels.take(3)) _Tag(label: label.value),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          facts.isEmpty ? 'Sin datos de contacto' : facts.join('\n'),
                          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: actions.children),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 24,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(_initials(name), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: scheme.onPrimaryContainer)),
                ),
                const SizedBox(width: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(name, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500)),
                          if (client.userId != null) _Tag(label: 'Usa la app', filled: true),
                          for (final label in labels.take(3)) _Tag(label: label.value),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        facts.isEmpty ? 'Sin datos de contacto' : facts.join('   ·   '),
                        style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions,
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? scheme.secondaryContainer : null,
        borderRadius: BorderRadius.circular(8),
        border: filled ? null : Border.all(color: scheme.outline),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: filled ? scheme.onSecondaryContainer : scheme.onSurface),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.summary, this.loading = false});

  final ClientSummary? summary;

  /// Mientras carga: los mismos indicadores con números de mentira.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return AppSkeleton(
        child: _grid([
          for (final label in const ['Turnos · últimos 90 días', 'Días cancelados · 90 días', 'Saldo pendiente', 'Último pago'])
            _Kpi(label: label, value: '00', detail: skeletonText(3)),
        ]),
      );
    }
    final s = summary;
    final last = s?.lastPayment;
    final tiles = [
      _Kpi(
        label: 'Turnos · últimos 90 días',
        value: s == null ? '—' : '${s.sessionsLast90Days}',
        detail: s == null ? '' : '${s.fixedSessionsLast90Days} por turno fijo',
      ),
      _Kpi(
        label: 'Días cancelados · 90 días',
        value: s == null ? '—' : '${s.cancelledDaysLast90Days}',
        detail: 'De sus turnos fijos',
      ),
      _Kpi(
        label: 'Saldo pendiente',
        value: s == null ? '—' : _money(s.pendingBalance),
        detail: s == null ? '' : (s.unpaidSessions == 0 ? 'Al día' : '${s.unpaidSessions} turno${s.unpaidSessions == 1 ? '' : 's'} sin pagar'),
        alert: (s?.pendingBalance ?? 0) > 0,
      ),
      _Kpi(
        label: 'Último pago',
        value: last == null ? '—' : DateFormat('dd/MM').format(last.date),
        detail: last == null ? 'Sin pagos' : [_money(last.amount), if (last.method != null) last.method!].join(' · '),
      ),
    ];
    return _grid(tiles);
  }

  static Widget _grid(List<Widget> tiles) => LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth > 900 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(spacing: 16, runSpacing: 16, children: [for (final t in tiles) SizedBox(width: width, child: t)]);
      });
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.detail, this.alert = false});

  final String label;
  final String value;
  final String detail;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton.keep(child: Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: alert ? scheme.error : scheme.onSurface)),
            Text(detail, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.summary, this.error});

  final ClientSummary? summary;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final upcoming = summary?.upcoming;

    Widget body;
    if (error != null) {
      body = Text(error!, style: TextStyle(color: scheme.error));
    } else if (upcoming == null) {
      body = const SkeletonRows();
    } else if (upcoming.isEmpty) {
      body = Text('No tiene turnos próximos.', style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant));
    } else {
      body = Column(children: [for (final u in upcoming) _UpcomingRow(session: u)]);
    }

    return _SideCard(title: 'Próximos turnos', child: body);
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.session});

  final ClientUpcomingSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final court = [session.sport, session.courtName].whereType<String>().join(' · ');
    final place = <LinkSegment>[
      LinkSegment.text(court),
      if (!session.isOwner && session.ownerName != null) ...[
        const LinkSegment.text(' · turno de '),
        LinkSegment.client(session.ownerClientId, session.ownerName!),
      ] else if (session.membersCount > 1)
        LinkSegment.text(' · con ${session.membersCount - 1} integrante${session.membersCount == 2 ? '' : 's'}'),
    ];
    final (String tag, Color bg, Color fg) = session.isPending
        ? ('Pendiente', scheme.secondaryContainer, scheme.onSecondaryContainer)
        : session.isFixed
            ? ('Fijo', scheme.tertiaryContainer, scheme.onTertiaryContainer)
            : ('Confirmado', scheme.primaryContainer, scheme.onPrimaryContainer);
    final pay = session.due <= 0.005
        ? 'Pagado'
        : session.paid > 0
            ? 'Seña ${_money(session.paid)}'
            : (session.isOwner ? 'Debe ${_money(session.due)}' : 'Sin pagar');

    // Toda la fila abre el turno en la agenda; con hover se subrayan día y hora.
    return HoverLink(
      onTap: () => openSession(context, session.sessionId),
      builder: (context, hovered) => Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: scheme.outlineVariant))),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              DateFormat('EEE dd/MM', 'es').format(session.startTime),
              style: linkStyle(const TextStyle(fontWeight: FontWeight.w500), hovered),
            ),
          ),
          SizedBox(width: 64, child: Text(DateFormat('HH:mm').format(session.startTime), style: linkStyle(const TextStyle(), hovered))),
          Expanded(
            child: ClientLinksText(place, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Text(tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
          ),
          SizedBox(
            width: 140,
            child: Text(
              pay,
              textAlign: TextAlign.end,
              style: TextStyle(color: pay.startsWith('Debe') || pay == 'Sin pagar' ? scheme.error : scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)), if (action != null) action!]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.client, required this.onEdit});

  final Client client;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final note = client.person?.observation?.trim() ?? '';
    return _SideCard(
      title: 'Notas',
      action: Permissions.can(Permissions.CLIENTES_EDITAR)
          ? IconButton(tooltip: 'Editar notas', icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit)
          : null,
      child: Text(
        note.isEmpty ? 'Sin notas.' : note,
        style: TextStyle(fontSize: 14, height: 1.45, color: note.isEmpty ? scheme.onSurfaceVariant : scheme.onSurface),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.summary, this.error});

  final ClientSummary? summary;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activity = summary?.activity;
    Color dot(String kind) => switch (kind) {
          'FIXED_DAY_CANCELLED' => scheme.tertiary,
          'FIXED_ENDED' => scheme.error,
          'PAYMENT' => scheme.secondary,
          _ => scheme.primary,
        };

    return _SideCard(
      title: 'Actividad',
      child: error != null
          ? Text(error!, style: TextStyle(color: scheme.error))
          : activity == null
          ? const SkeletonRows(dividers: false, padding: EdgeInsets.only(bottom: 12))
          : activity.isEmpty
              ? Text('Sin actividad todavía.', style: TextStyle(color: scheme.onSurfaceVariant))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final a in activity)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(color: dot(a.kind), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.text, style: const TextStyle(fontSize: 13)),
                                  Text(
                                    DateFormat("dd/MM/yyyy HH:mm").format(a.at),
                                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}

/// La ficha mientras llega el cliente (entrando por link o recargando): el
/// encabezado, los indicadores y las cards con su forma, sin datos.
class ClientProfileSkeleton extends StatelessWidget {
  const ClientProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final desktop = ResponsiveBuilder.isDesktop(context);
    final client = Client(
      person: Person(name: skeletonText(1), lastName: skeletonText(1), email: BoneMock.email, phone: BoneMock.phone),
    );

    Widget card(String title, {int rows = 3}) => _SideCard(title: title, child: SkeletonRows(count: rows));
    Widget column(List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final (i, child) in children.indexed) ...[if (i > 0) const SizedBox(height: 20), child]],
        );
    final main = [card('Turnos fijos', rows: 2), card('Próximos turnos'), card('Pagos')];
    final side = [card('Etiquetas', rows: 1), card('Notas', rows: 1), card('Actividad')];

    return SingleChildScrollView(
      padding: EdgeInsets.all(desktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeleton(child: _HeaderCard(client: client, onEdit: () {}, onPaymentCreated: () {})),
          const SizedBox(height: 20),
          const _KpiRow(summary: null, loading: true),
          const SizedBox(height: 20),
          if (desktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: column(main)),
                const SizedBox(width: 20),
                Expanded(child: column(side)),
              ],
            )
          else
            column([...main, ...side]),
        ],
      ),
    );
  }
}
