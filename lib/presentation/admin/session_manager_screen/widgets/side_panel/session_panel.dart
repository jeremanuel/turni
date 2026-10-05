import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/config/router/app_routes.dart';
import '../../../../../core/config/service_locator.dart';
import '../../../../../core/utils/either.dart';
import '../../../../../core/utils/physical_partition_naming.dart';
import '../../../../../domain/entities/client.dart';
import '../../../../../domain/entities/club_partition.dart';
import '../../../../../domain/entities/extra.dart';
import '../../../../../domain/entities/physical_partition.dart';
import '../../../../../domain/entities/session.dart';
import '../../../../../domain/repositories/admin_repository.dart';
import '../../../../../domain/repositories/session_repository.dart';
import '../../../../../domain/usercases/session_user_cases.dart';
import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';
import '../../utils/pending_request_ttl.dart';
import 'consumo_view.dart';
import 'free_session_view.dart';
import 'new_client_view.dart';
import 'panel_common.dart';
import 'payment_view.dart';

enum _PanelView { detail, payment, consumo, newClient }

/// Panel derecho con el turno seleccionado. Reservado: cliente, cuenta
/// (turno + consumos − pagos), notas y actividad, con accesos a "Cobrar" y
/// "Agregar consumo". Libre: elegir o crear el cliente y reservar.
/// Pendiente: aceptar o rechazar la solicitud.
class SessionPanel extends StatefulWidget {
  const SessionPanel({
    super.key,
    required this.session,
    required this.physicalPartition,
    required this.clubPartition,
  });

  final Session session;
  final PhysicalPartition physicalPartition;
  final ClubPartition clubPartition;

  @override
  State<SessionPanel> createState() => _SessionPanelState();
}

class _SessionPanelState extends State<SessionPanel> {
  _PanelView _view = _PanelView.detail;

  @override
  void didUpdateWidget(covariant SessionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedSession = oldWidget.session.sessionId != widget.session.sessionId;
    final changedState = oldWidget.session.isFree != widget.session.isFree;
    if (changedSession || changedState) _view = _PanelView.detail;
  }

  void _go(_PanelView view) => setState(() => _view = view);

  String get _courtLabel => PhysicalPartitionNaming.labelFromPhysicalPartition(
        widget.physicalPartition,
        fallbackClubPartition: widget.clubPartition,
      );

  String get _clientName => widget.session.client?.person?.fullName ?? 'Cliente';

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    void back() => _go(_PanelView.detail);

    return switch (_view) {
      _PanelView.payment => PaymentView(
          session: session,
          subtitle: '$_clientName · ${panelRange(session)}',
          players: widget.physicalPartition.maxPlayers ?? widget.physicalPartition.minPlayers,
          onBack: back,
        ),
      _PanelView.consumo => ConsumoView(
          session: session,
          subtitle: '$_clientName · ${panelRange(session)}',
          onBack: back,
        ),
      _PanelView.newClient => NewClientView(
          session: session,
          subtitle: 'Para el turno de ${panelRange(session)} · $_courtLabel',
          onBack: back,
        ),
      _PanelView.detail when session.isFree => FreeSessionView(
          session: session,
          header: _header(context),
          onCreateClient: () => _go(_PanelView.newClient),
        ),
      _PanelView.detail => _BookedDetail(
          session: session,
          header: _header(context),
          onCharge: () => _go(_PanelView.payment),
          onAddConsumo: () => _go(_PanelView.consumo),
        ),
    };
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = widget.session;
    final status = session.isFree
        ? PanelStatusChip(label: 'Libre', foreground: scheme.onSurfaceVariant, dashedBorder: scheme.outline)
        : session.isPending
            ? PanelStatusChip(
                label: 'Por aprobar',
                background: scheme.tertiaryContainer,
                foreground: scheme.onTertiaryContainer,
              )
            : PanelStatusChip(
                label: 'Reservado',
                background: scheme.primaryContainer,
                foreground: scheme.onPrimaryContainer,
              );

    return PanelSessionHeader(
      status: status,
      title: panelRange(session),
      subtitle: [
        panelDayTitle(session.startTime),
        widget.clubPartition.clubType?.name,
        _courtLabel,
        '${session.duration} min',
      ].whereType<String>().where((t) => t.isNotEmpty).join(' · '),
      onClose: () => context.go(AppRoutes.SESSION_MANAGER_ROUTE.path),
    );
  }
}

// ---------------------------------------------------------------------------
// Turno reservado (o pendiente de aprobación).

class _BookedDetail extends StatelessWidget {
  const _BookedDetail({
    required this.session,
    required this.header,
    required this.onCharge,
    required this.onAddConsumo,
  });

  final Session session;
  final Widget header;
  final VoidCallback onCharge;
  final VoidCallback onAddConsumo;

  Future<void> _cancelReservation(BuildContext context) async {
    final ok = await confirmPanelAction(
      context,
      title: 'Cancelar reserva',
      message: 'El turno vuelve a quedar libre. Los pagos y consumos cargados se pierden.',
      confirmLabel: 'Cancelar reserva',
    );
    if (!ok || !context.mounted) return;
    await context.read<SessionManagerBloc>().cancelSessionReservation(session.sessionId);
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await confirmPanelAction(
      context,
      title: 'Eliminar turno',
      message: 'El turno se borra de la agenda. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (!ok || !context.mounted) return;
    context.read<SessionManagerBloc>().add(DeleteSession(session.sessionId));
    context.go(AppRoutes.SESSION_MANAGER_ROUTE.path);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PanelFrame(
      footer: Row(
        children: [
          PanelTextButton(
            label: session.isPending ? 'Rechazar solicitud' : 'Cancelar reserva',
            color: scheme.error,
            onPressed: session.isPending
                ? () => context.read<SessionManagerBloc>().add(RejectSessionRequest(session.sessionId))
                : () => _cancelReservation(context),
          ),
          const Spacer(),
          PanelTextButton(label: 'Eliminar turno', color: scheme.onSurfaceVariant, onPressed: () => _delete(context)),
        ],
      ),
      children: [
        header,
        if (session.client != null) _ClientCard(client: session.client!),
        if (session.isPending) _PendingBanner(session: session),
        if (!session.isPending) _AccountCard(session: session, onCharge: onCharge, onAddConsumo: onAddConsumo),
        _NotesField(session: session),
        _Activity(session: session),
      ],
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final person = client.person;
    final contact = [
      if (person?.hasEmail() ?? false) person!.email!,
      if (person?.hasPhone() ?? false) person!.phone!,
    ].join(' · ');

    return PanelCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          PanelAvatar(name: person?.fullName ?? ''),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person?.fullName ?? 'Cliente',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: scheme.onSurface),
                ),
                if (contact.isNotEmpty)
                  Text(
                    contact,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (client.clientId != null)
            IconButton(
              tooltip: 'Abrir ficha del cliente',
              style: IconButton.styleFrom(
                foregroundColor: scheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: () => context.goNamed(AppRoutes.CLIENT_ROUTE.name, pathParameters: {'clientId': client.clientId!}),
              icon: const Icon(Icons.open_in_new, size: 18),
            ),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    PendingRequestTtl.ensureLoaded();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solicitud de turno',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: scheme.onTertiaryContainer),
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<int?>(
            valueListenable: PendingRequestTtl.minutes,
            builder: (context, _, _) {
              final expires = PendingRequestTtl.expiresLabel(session.createdAt);
              return Text(
                'El cliente pidió este turno${expires == null ? '' : ' · $expires'}. Precio ${panelPrice(session.price)}.',
                style: TextStyle(fontSize: 13, color: scheme.onTertiaryContainer),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PanelTextButton(
                label: 'Rechazar',
                color: scheme.onTertiaryContainer,
                onPressed: () => context.read<SessionManagerBloc>().add(RejectSessionRequest(session.sessionId)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => context.read<SessionManagerBloc>().add(AcceptSessionRequest(session.sessionId)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  backgroundColor: scheme.tertiary,
                  foregroundColor: scheme.onTertiary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  textStyle: panelButtonText(context),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Aceptar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Agua mineral x2" (así se guardan los consumos con cantidad) → (2, "Agua mineral").
(int, String) extraQuantity(Extra extra) {
  final match = RegExp(r'^(.*) x(\d+)$').firstMatch(extra.name);
  if (match == null) return (1, extra.name);
  return (int.parse(match.group(2)!), match.group(1)!);
}

class _AccountCard extends StatefulWidget {
  const _AccountCard({required this.session, required this.onCharge, required this.onAddConsumo});

  final Session session;
  final VoidCallback onCharge;
  final VoidCallback onAddConsumo;

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  final _useCases = SessionUserCases(sl<SessionRepository>());
  final _deleting = <Extra>{};

  Future<void> _deleteExtra(Extra extra) async {
    setState(() => _deleting.add(extra));
    final result = await _useCases.deleteSessionExtra(widget.session.sessionId, extra);
    if (!mounted) return;
    setState(() => _deleting.remove(extra));
    if (result case Right(value: true)) {
      final session = widget.session;
      context.read<SessionManagerBloc>().updateSessionInState(
            session.copyWith(
              extras: session.extras
                  ?.where((e) => e.extraId != null && extra.extraId != null ? e.extraId != extra.extraId : e != extra)
                  .toList(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = widget.session;
    final extras = session.extras ?? const <Extra>[];
    final payments = [
      for (final p in session.payments ?? const []) (p.paymentMethod.name, p.paymentDate, p.amount),
      for (final e in extras)
        if (e.payment != null) ('${e.payment!.paymentMethod.name} (consumo)', e.payment!.paymentDate, e.payment!.amount),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    final remaining = session.remainingTotalPrice;
    final settled = remaining <= 0;

    final body = TextStyle(fontSize: 14, color: scheme.onSurface);
    final muted = TextStyle(color: scheme.onSurfaceVariant);
    final group = TextStyle(fontSize: 12, color: scheme.outline);

    Widget line(Widget left, Widget right) => Row(
          children: [Expanded(child: left), right],
        );

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: scheme.onSurface)),
              ),
              Text('Turno + consumos', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),
          line(Text('Turno', style: body), Text(panelPrice(session.price), style: body)),
          if (extras.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Consumos', style: group),
            for (final extra in extras) ...[
              const SizedBox(height: 10),
              line(
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${extraQuantity(extra).$1} × ', style: muted),
                    TextSpan(text: extraQuantity(extra).$2),
                    if (extra.payed) TextSpan(text: ' · pagado', style: muted.copyWith(fontSize: 12)),
                  ]),
                  style: body,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(panelPrice(extra.amount), style: body),
                    if (!extra.payed)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: SizedBox(
                          width: 24,
                          height: 20,
                          child: _deleting.contains(extra)
                              ? const Center(
                                  child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : IconButton(
                                  tooltip: 'Quitar consumo',
                                  padding: EdgeInsets.zero,
                                  iconSize: 16,
                                  style: IconButton.styleFrom(
                                    foregroundColor: scheme.onSurfaceVariant,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                  onPressed: () => _deleteExtra(extra),
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
          if (payments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Pagos', style: group),
            for (final p in payments) ...[
              const SizedBox(height: 10),
              line(
                Text.rich(
                  TextSpan(children: [TextSpan(text: p.$1), TextSpan(text: ' · ${panelHm(p.$2)}', style: muted)]),
                  style: body,
                ),
                Text('−${panelPrice(p.$3)}', style: body.copyWith(color: scheme.primary)),
              ),
            ],
          ],
          const SizedBox(height: 12),
          CustomPaint(size: const Size(double.infinity, 1), painter: _DashedLine(scheme.outlineVariant)),
          const SizedBox(height: 12),
          line(Text('Total', style: body.copyWith(color: scheme.onSurfaceVariant)), Text(panelPrice(session.totalPrice), style: body)),
          const SizedBox(height: 10),
          _SaldoBox(settled: settled, remaining: remaining),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: PanelFilledButton(label: 'Cobrar', icon: Icons.credit_card, onPressed: settled ? null : widget.onCharge),
              ),
              const SizedBox(width: 8),
              Expanded(
                // Un poco más ancho que "Cobrar" para que entre el texto completo.
                flex: 6,
                child: OutlinedButton.icon(
                  onPressed: widget.onAddConsumo,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.outline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    textStyle: panelButtonText(context),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar consumo', maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaldoBox extends StatelessWidget {
  const _SaldoBox({required this.settled, required this.remaining});

  final bool settled;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = settled ? scheme.onPrimaryContainer : scheme.onTertiaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: settled ? scheme.primaryContainer : scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              settled ? 'Todo pago' : 'Saldo a cobrar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: fg),
            ),
          ),
          Text(panelPrice(settled ? 0 : remaining), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

class _DashedLine extends CustomPainter {
  _DashedLine(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 3, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLine oldDelegate) => oldDelegate.color != color;
}

/// Notas del turno: se guardan solas (al dejar de tipear o al salir del campo).
class _NotesField extends StatefulWidget {
  const _NotesField({required this.session});

  final Session session;

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late final _controller = TextEditingController(text: widget.session.observation ?? '');
  final _focus = FocusNode();
  Timer? _debounce;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
  }

  @override
  void didUpdateWidget(covariant _NotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.sessionId != widget.session.sessionId) {
      _debounce?.cancel();
      _controller.text = widget.session.observation ?? '';
      _saved = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_pending) _save(silent: true);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _pending => _controller.text.trim() != (widget.session.observation ?? '').trim();

  Future<void> _save({bool silent = false}) async {
    _debounce?.cancel();
    if (!_pending || _saving) return;
    final session = widget.session;
    final text = _controller.text.trim();
    final bloc = context.read<SessionManagerBloc>();
    if (!silent) setState(() => _saving = true);
    final result = await sl<AdminRepository>().updateSessionObservation(session.sessionId, text.isEmpty ? null : text);
    if (result case Right(:final value)) bloc.updateSessionInState(session.copyWith(observation: value));
    if (!mounted || silent) return;
    setState(() {
      _saving = false;
      _saved = result is Right;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Notas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface)),
            ),
            if (_saving || _saved)
              Text(_saving ? 'Guardando…' : 'Guardado', style: TextStyle(fontSize: 12, color: scheme.outline)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          focusNode: _focus,
          minLines: 2,
          maxLines: 5,
          maxLength: 1000,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          style: TextStyle(fontSize: 14, color: scheme.onSurface),
          decoration: panelInputDecoration(context, hintText: 'Agregar una nota del turno…')
              .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          onChanged: (_) {
            if (_saved) setState(() => _saved = false);
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 900), _save);
          },
        ),
      ],
    );
  }
}

/// Actividad del turno armada con lo que se sabe: alta del turno, pagos y
/// cobros de consumos.
class _Activity extends StatelessWidget {
  const _Activity({required this.session});

  final Session session;

  static String _when(DateTime date) {
    final now = DateTime.now();
    final hm = panelHm(date);
    if (DateUtils.isSameDay(date, now)) return 'hoy $hm';
    if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) return 'ayer $hm';
    return '${DateFormat('EEE d MMM', 'es').format(date).replaceAll('.', '')} $hm';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = <(DateTime, bool, String, String)>[
      for (final p in session.payments ?? const [])
        (p.paymentDate, true, 'Cobro', ' de ${panelPrice(p.amount)} en ${p.paymentMethod.name.toLowerCase()}'),
      for (final e in session.extras ?? const <Extra>[])
        if (e.payment != null)
          (
            e.payment!.paymentDate,
            true,
            'Cobro de consumo',
            ' ${extraQuantity(e).$2} · ${panelPrice(e.payment!.amount)} en ${e.payment!.paymentMethod.name.toLowerCase()}',
          ),
      (session.createdAt, false, 'Turno creado', ''),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Actividad', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface)),
        for (final entry in entries) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(shape: BoxShape.circle, color: entry.$2 ? scheme.primary : scheme.outline),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: entry.$3, style: const TextStyle(fontWeight: FontWeight.w500)),
                    TextSpan(text: entry.$4),
                    TextSpan(text: '\n${_when(entry.$1)}', style: TextStyle(fontSize: 12, color: scheme.outline)),
                  ]),
                  style: TextStyle(fontSize: 13, color: scheme.onSurface),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
