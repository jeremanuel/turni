import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/router/app_routes.dart';
import '../../../../core/presentation/components/dashed_rrect_painter.dart';
import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/entities/session.dart';
import '../bloc/session_manager_bloc.dart';
import '../bloc/session_manager_event.dart';
import '../utils/pending_request_ttl.dart';
import 'close_session_dialog.dart';

/// Card de un turno en la agenda, según el diseño "Cards de turnos de la
/// agenda" (https://claude.ai/artifact/SySjxAmpiY5MUQa58Efe26):
/// - Libre: fondo `surfaceContainerHigh` con borde punteado `outline`.
/// - Reservado: fondo `primaryContainer`, cliente y barra de pago abajo.
/// - Pendiente de aprobación: fondo `tertiaryContainer` con borde punteado
///   `tertiary`, y aceptar/rechazar en la misma card.
/// El contenido se adapta al alto (= duración): una línea, compacta o completa.
class SessionManagerCard extends StatelessWidget {
  const SessionManagerCard({
    super.key,
    required this.session,
    required this.physicalPartition,
    this.onReserve,
    this.onDelete,
    this.hasFocus = false,
    required this.height,
  });

  final Session session;
  final PhysicalPartition physicalPartition;
  final Function? onReserve;
  final Function? onDelete;
  final bool hasFocus;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (session.isPending) {
      return PendingSessionCard(session: session, hasFocus: hasFocus, height: height);
    }
    if (session.isConfirmed) {
      return ReservedSessionCard(session: session, hasFocus: hasFocus, height: height);
    }
    return NotReservedSessionCard(session: session, onReserve: onReserve, hasFocus: hasFocus, height: height);
  }
}

/// Tamaño de la card según su alto en la agenda.
enum _CardSize {
  /// Una sola línea (turnos de ~30 min).
  line,

  /// Horario + una línea de detalle.
  compact,

  /// Todo el detalle y las acciones.
  full;

  static _CardSize of(double height) {
    if (height < 56) return line;
    if (height < 110) return compact;
    return full;
  }
}

String _hm(DateTime value) => DateFormat('HH:mm').format(value);

String _price(double value) => '\$${ThousandsFormat.formatPrice(value)}';

String _range(Session session) => '${_hm(session.startTime)} – ${_hm(session.endTime as DateTime)}';

String _initials(String fullName) {
  final words = fullName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return (words.first.substring(0, 1) + words.last.substring(0, 1)).toUpperCase();
}

/// Contenedor común: radio 8, 2px de aire a los costados, borde (sólido o
/// punteado) y el anillo `primary` de "seleccionado".
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.background,
    required this.borderColor,
    required this.dashed,
    required this.selected,
    required this.onTap,
    required this.child,
    this.tooltip,
  });

  final Color background;
  final Color borderColor;
  final bool dashed;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);

    Widget card = Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: dashed ? BorderSide.none : BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );

    if (dashed) {
      card = CustomPaint(
        foregroundPainter: DashedRRectPainter(color: borderColor, radius: 8),
        child: card,
      );
    }

    if (selected) {
      // Anillo de 2px separado de la card por 2px del fondo de la agenda.
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(color: scheme.primary, spreadRadius: 4),
            BoxShadow(color: scheme.surface, spreadRadius: 2),
          ],
        ),
        child: card,
      );
    }

    if (tooltip != null) card = Tooltip(message: tooltip!, child: card);

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: card);
  }
}

/// Botón de ícono de 28px de las cards.
class _CardIconButton extends StatelessWidget {
  const _CardIconButton({required this.icon, required this.color, required this.tooltip, required this.onPressed});

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 16,
        style: IconButton.styleFrom(
          foregroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}

/// Avatar de 20px con las iniciales del cliente.
class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.background, required this.foreground});

  final String name;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: foreground, height: 1),
      ),
    );
  }
}

/// Contenido "compacto": sin `Spacer`s, recortado si no entra (en lugar de
/// las franjas amarillas de overflow en turnos un poco más cortos).
Widget _clipped(Widget column) => ClipRect(
      child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: column),
    );

void _openSession(BuildContext context, Session session) {
  context.goNamed(
    AppRoutes.SESSION_MANAGER_RESERVE_ROUTE.name,
    pathParameters: {"idSession": session.sessionId.toString()},
  );
}

// ---------------------------------------------------------------------------
// Libre
// ---------------------------------------------------------------------------

class NotReservedSessionCard extends StatefulWidget {
  const NotReservedSessionCard({
    super.key,
    required this.session,
    this.onReserve,
    this.hasFocus = false,
    required this.height,
  });

  final Session session;
  final Function? onReserve;
  final bool hasFocus;
  final double height;

  @override
  State<NotReservedSessionCard> createState() => _NotReservedSessionCardState();
}

class _NotReservedSessionCardState extends State<NotReservedSessionCard> {
  bool _hover = false;

  void _reserve() {
    widget.onReserve?.call();
    _openSession(context, widget.session);
  }

  Future<void> _delete() async {
    final action = await showCloseSessionDialog(context, isReserved: false);
    if (!mounted || action != CloseSessionAction.deleteSession) return;
    context.read<SessionManagerBloc>().add(DeleteSession(widget.session.sessionId));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = widget.session;
    final size = _CardSize.of(widget.height);

    final Widget content;
    if (size == _CardSize.line) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Text(_range(session),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: scheme.onSurface)),
            const Spacer(),
            Text('Libre', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
        ),
      );
    } else {
      final header = SizedBox(
        height: 28,
        child: Row(
          children: [
            Text(_range(session),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: scheme.onSurface)),
            const Spacer(),
            if (_hover)
              _CardIconButton(
                icon: Icons.close,
                color: scheme.onSurfaceVariant,
                tooltip: 'Eliminar turno',
                onPressed: _delete,
              ),
          ],
        ),
      );
      final detail = Text(
        'Libre · ${_price(session.price)}',
        style: TextStyle(fontSize: 12, height: 16 / 12, color: scheme.onSurfaceVariant),
      );

      content = Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 8),
        child: size == _CardSize.compact
            ? _clipped(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [header, const SizedBox(height: 2), detail],
              ))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 2),
                  detail,
                  const Spacer(),
                  if (_hover)
                    OutlinedButton.icon(
                      onPressed: _reserve,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        foregroundColor: scheme.primary,
                        side: BorderSide(color: scheme.outline),
                        textStyle: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                      label: const Text('Reservar'),
                    )
                  else
                    Text('${session.duration} min', style: TextStyle(fontSize: 12, color: scheme.outline)),
                ],
              ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: _CardShell(
        background: _hover ? scheme.surfaceContainerHighest : scheme.surfaceContainerHigh,
        borderColor: _hover ? scheme.primary : scheme.outline,
        dashed: !_hover,
        selected: widget.hasFocus,
        onTap: _reserve,
        child: SizedBox(height: widget.height, width: double.infinity, child: content),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reservado
// ---------------------------------------------------------------------------

enum _PayState { none, partial, full }

class ReservedSessionCard extends StatelessWidget {
  const ReservedSessionCard({super.key, required this.session, this.hasFocus = false, required this.height});

  final Session session;
  final bool hasFocus;
  final double height;

  bool get isFixedReservedSession => session.clubTypeName == "FIXED_SESSION";

  _PayState get _payState {
    final total = session.totalPrice;
    final paid = session.totalPayedPrice;
    if (total <= 0 || paid >= total) return _PayState.full;
    if (paid > 0) return _PayState.partial;
    return _PayState.none;
  }

  double get _paidFraction {
    if (session.totalPrice <= 0) return 1;
    return (session.totalPayedPrice / session.totalPrice).clamp(0, 1).toDouble();
  }

  String get _payLabel {
    switch (_payState) {
      case _PayState.full:
        return 'Pagado';
      case _PayState.partial:
        return 'Seña ${_price(session.totalPayedPrice)} de ${_price(session.totalPrice)}';
      case _PayState.none:
        return 'Sin pagar · ${_price(session.totalPrice)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onPrimaryContainer;
    final size = _CardSize.of(height);
    final clientName = session.client?.person?.fullName ?? 'Cliente';
    final clientId = session.client?.clientId;

    final name = Text(
      clientName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: size == _CardSize.line ? 12 : 13, color: fg),
    );

    final fixedIcon = isFixedReservedSession
        ? Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Tooltip(message: 'Turno fijo', child: Icon(Icons.event_repeat, size: 14, color: fg)),
          )
        : const SizedBox.shrink();

    final Widget content;
    if (size == _CardSize.line) {
      final payState = _payState;
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Text(_hm(session.startTime), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
            const SizedBox(width: 6),
            Expanded(child: name),
            const SizedBox(width: 6),
            Tooltip(
              message: _payLabel,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary, width: 1.5),
                  color: switch (payState) {
                    _PayState.full => scheme.primary,
                    _PayState.partial => fg,
                    _PayState.none => Colors.transparent,
                  },
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final header = SizedBox(
        height: 28,
        child: Row(
          children: [
            Text(_range(session), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg)),
            fixedIcon,
            const Spacer(),
            if (clientId != null)
              _CardIconButton(
                icon: Icons.open_in_new,
                color: fg,
                tooltip: 'Abrir ficha del cliente',
                onPressed: () => context.goNamed(AppRoutes.CLIENT_ROUTE.name, pathParameters: {"clientId": clientId}),
              ),
          ],
        ),
      );
      final clientRow = Row(
        children: [
          _Initials(name: clientName, background: scheme.primary, foreground: scheme.onPrimary),
          const SizedBox(width: 6),
          Expanded(child: name),
        ],
      );

      content = Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 9),
            child: size == _CardSize.compact
                ? _clipped(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [header, const SizedBox(height: 4), clientRow],
                  ))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      const SizedBox(height: 4),
                      clientRow,
                      const Spacer(),
                      Row(
                        children: [
                          if (_payState == _PayState.full) ...[
                            Icon(Icons.check, size: 14, color: fg),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              _payLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, height: 16 / 12, color: fg),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          // Barra de pago: 3px abajo, de punta a punta.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 3,
            child: ColoredBox(
              color: fg.withValues(alpha: 0.18),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _paidFraction,
                child: ColoredBox(color: scheme.primary),
              ),
            ),
          ),
        ],
      );
    }

    return _CardShell(
      background: scheme.primaryContainer,
      borderColor: scheme.primaryContainer,
      dashed: false,
      selected: hasFocus,
      onTap: () => _openSession(context, session),
      tooltip: size == _CardSize.line ? null : _payLabel,
      child: SizedBox(height: height, width: double.infinity, child: content),
    );
  }
}

// ---------------------------------------------------------------------------
// Pendiente de aprobación
// ---------------------------------------------------------------------------

class PendingSessionCard extends StatefulWidget {
  const PendingSessionCard({super.key, required this.session, this.hasFocus = false, required this.height});

  final Session session;
  final bool hasFocus;
  final double height;

  @override
  State<PendingSessionCard> createState() => _PendingSessionCardState();
}

class _PendingSessionCardState extends State<PendingSessionCard> {
  @override
  void initState() {
    super.initState();
    PendingRequestTtl.ensureLoaded();
  }

  void _accept() => context.read<SessionManagerBloc>().add(AcceptSessionRequest(widget.session.sessionId));

  /// Rechazar le avisa al cliente y libera el turno: se confirma antes.
  Future<void> _reject() async {
    final bloc = context.read<SessionManagerBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rechazar solicitud'),
        content: Text(
          '¿Rechazar la solicitud de ${widget.session.client?.person?.fullName ?? 'este cliente'} '
          'para las ${_hm(widget.session.startTime)}? El turno vuelve a quedar libre.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Rechazar')),
        ],
      ),
    );
    if (confirmed == true) bloc.add(RejectSessionRequest(widget.session.sessionId));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onTertiaryContainer;
    final session = widget.session;
    final size = _CardSize.of(widget.height);
    final clientName = session.client?.person?.fullName ?? 'Cliente';
    final hourglass = Icon(Icons.hourglass_empty, size: 14, color: scheme.tertiary);

    final accept = _CardIconButton(
      icon: Icons.check,
      color: scheme.tertiary,
      tooltip: 'Aceptar solicitud',
      onPressed: _accept,
    );

    final Widget content;
    if (size == _CardSize.line) {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
        child: Row(
          children: [
            hourglass,
            const SizedBox(width: 6),
            Text(_hm(session.startTime), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Pendiente',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: fg)),
            ),
            accept,
          ],
        ),
      );
    } else {
      // En "completa" las acciones van abajo como botones: el encabezado no
      // reserva los 28px de los íconos (si no, en 90 min no entra todo).
      final header = SizedBox(
        height: size == _CardSize.compact ? 28 : null,
        child: Row(
          children: [
            hourglass,
            const SizedBox(width: 6),
            Text(_range(session), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg)),
            const Spacer(),
            if (size == _CardSize.compact) ...[
              accept,
              _CardIconButton(icon: Icons.close, color: fg, tooltip: 'Rechazar solicitud', onPressed: _reject),
            ],
          ],
        ),
      );
      final clientRow = Row(
        children: [
          _Initials(name: clientName, background: scheme.tertiary, foreground: scheme.onTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(clientName,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: fg)),
          ),
        ],
      );

      content = Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 8),
        child: size == _CardSize.compact
            ? _clipped(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [header, const SizedBox(height: 4), clientRow],
              ))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 4),
                  clientRow,
                  const SizedBox(height: 4),
                  ValueListenableBuilder<int?>(
                    valueListenable: PendingRequestTtl.minutes,
                    builder: (context, _, __) {
                      final expires = PendingRequestTtl.expiresLabel(session.createdAt);
                      return Text(
                        expires == null ? 'Solicitud pendiente' : 'Pendiente · $expires',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, height: 16 / 12, color: fg),
                      );
                    },
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _accept,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: scheme.tertiary,
                          foregroundColor: scheme.onTertiary,
                          textStyle: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        child: const Text('Aceptar'),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: _reject,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          foregroundColor: fg,
                          textStyle: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        child: const Text('Rechazar'),
                      ),
                    ],
                  ),
                ],
              ),
      );
    }

    return _CardShell(
      background: scheme.tertiaryContainer,
      borderColor: scheme.tertiary,
      dashed: true,
      selected: widget.hasFocus,
      // El panel del turno no contempla solicitudes pendientes (mostraría
      // pagos de un turno no confirmado): tocar la card ofrece las acciones.
      // Es también la única forma de rechazar desde una card de 30 min.
      onTap: _showActions,
      child: SizedBox(height: widget.height, width: double.infinity, child: content),
    );
  }

  Future<void> _showActions() async {
    final session = widget.session;
    final action = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Solicitud de turno'),
        content: Text(
          '${_range(session)}'
          '${session.client?.person != null ? '\n${session.client!.person!.fullName}' : ''}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Rechazar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Aceptar')),
        ],
      ),
    );
    if (!mounted || action == null) return;
    action ? _accept() : await _reject();
  }
}
