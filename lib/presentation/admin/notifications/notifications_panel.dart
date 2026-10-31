import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/onboarding/tour_anchor.dart';
import '../../../domain/entities/admin_notification.dart';
import 'notification_texts.dart';
import 'notification_toasts.dart';
import 'notification_widgets.dart';
import 'notifications_cubit.dart';

/// Cuándo llegó un aviso, corto: "Recién", "Hace 5 min", "Hoy 18:30",
/// "Ayer 09:15" o "12/10 · 18:30".
String notificationTimeLabel(DateTime at, DateTime now) {
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return 'Recién';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';

  final hhmm = DateFormat('HH:mm').format(at);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  if (day == today) return 'Hoy $hhmm';
  if (day == today.subtract(const Duration(days: 1))) return 'Ayer $hhmm';
  return '${DateFormat('dd/MM').format(at)} · $hhmm';
}

/// Ícono de la categoría de un aviso (`SESSION`, `PAYMENT`, `TOURNAMENT`, `GYM`).
IconData notificationIconFor(String category) => switch (category) {
  'SESSION' => Icons.event_outlined,
  'PAYMENT' => Icons.payments_outlined,
  'TOURNAMENT' => Icons.emoji_events_outlined,
  'GYM' => Icons.fitness_center,
  _ => Icons.notifications_outlined,
};

/// Dónde está la campana en la pantalla, y si está en el menú lateral
/// (escritorio: la bandeja sale a su derecha y crece hacia arriba) o en la
/// barra de arriba (celular: baja de la barra).
class BellAnchor {
  const BellAnchor(this.rect, this.screen);

  final Rect rect;
  final Size screen;

  bool get inTopBar => rect.center.dy < 120;

  /// Escritorio: el borde izquierdo de la bandeja (el menú lateral + 12).
  double get panelLeft => rect.right + 32;

  /// Escritorio: el borde de abajo de la bandeja, 36 por debajo del centro de la campana.
  double get panelBottom => rect.center.dy + 36;

  /// Celular: el borde de arriba, 6 por debajo de la barra.
  double get panelTop => rect.bottom + 14;

  /// Celular: dónde va la flechita, medido desde el borde izquierdo de la bandeja.
  double get caretFromLeft => rect.center.dx - 8;
}

/// Campanita con la cantidad de avisos sin leer. Abre la bandeja anclada a
/// ella y muestra los avisos flotantes cuando llega uno (diseño "Bandeja de
/// notificaciones"). Va en el menú lateral (escritorio) y en la barra
/// superior (celular).
class NotificationsButton extends StatefulWidget {
  const NotificationsButton({super.key, this.cubit});

  final NotificationsCubit? cubit;

  @override
  State<NotificationsButton> createState() => _NotificationsButtonState();
}

class _NotificationsButtonState extends State<NotificationsButton> with SingleTickerProviderStateMixin {
  late final NotificationsCubit _cubit = widget.cubit ?? sl<NotificationsCubit>();
  final _panel = OverlayPortalController();
  final _toastsPortal = OverlayPortalController();
  final _toasts = GlobalKey<NotificationToastsState>();
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  StreamSubscription<List<AdminNotification>>? _arrivals;

  @override
  void initState() {
    super.initState();
    // Los avisos que llegaron mientras el panel estaba cerrado.
    _cubit.refreshUnread();
    _arrivals = _cubit.arrivals.listen(_onArrivals);
  }

  @override
  void dispose() {
    _arrivals?.cancel();
    _ring.dispose();
    super.dispose();
  }

  void _onArrivals(List<AdminNotification> fresh) {
    if (!mounted || _panel.isShowing) return;
    _toastsPortal.show();
    WidgetsBinding.instance.addPostFrameCallback((_) => _toasts.currentState?.add(fresh));
  }

  BellAnchor? _anchor(BuildContext overlayContext) {
    final box = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null || !box.attached) return null;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    return BellAnchor(topLeft & box.size, overlay.size);
  }

  void _open() {
    _toastsPortal.hide();
    _cubit.panelOpened();
    _panel.show();
    setState(() {});
  }

  void _close() {
    _panel.hide();
    if (mounted) setState(() {});
  }

  void _toggle() => _panel.isShowing ? _close() : _open();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final bell = BlocConsumer<NotificationsCubit, NotificationsState>(
      bloc: _cubit,
      listenWhen: (a, b) => b.rings > a.rings,
      listener: (_, _) => _ring.forward(from: 0),
      buildWhen: (a, b) => a.unread != b.unread || a.attention != b.attention,
      builder: (context, state) => AnimatedBuilder(
        animation: _ring,
        builder: (context, _) {
          final t = _ring.value;
          final ringing = _ring.isAnimating;
          final highlighted = state.attention || _panel.isShowing || ringing;
          final background = ringing
              ? Color.lerp(scheme.primary, scheme.primaryContainer, Curves.easeOut.transform(t))!
              : (highlighted ? scheme.primaryContainer : Colors.transparent);
          final iconColor = ringing
              ? Color.lerp(scheme.onPrimary, scheme.onPrimaryContainer, Curves.easeOut.transform(t))!
              : (highlighted ? scheme.onPrimaryContainer : scheme.onSurfaceVariant);
          final swing = ringing && !reduceMotion ? bellSwing(t / 0.78) * degrees : 0.0;
          final pop = ringing && !reduceMotion ? badgePop(t / 0.5) : 1.0;
          return Semantics(
            button: true,
            expanded: _panel.isShowing,
            label: state.unread > 0 ? 'Notificaciones, ${state.unread} sin leer' : 'Notificaciones',
            excludeSemantics: true,
            child: Tooltip(
              message: 'Notificaciones',
              child: Material(
                color: background,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _toggle,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: swing,
                          alignment: const Alignment(0, -0.73),
                          child: Icon(Icons.notifications_outlined, size: 22, color: iconColor),
                        ),
                        if (state.unread > 0)
                          Positioned(
                            top: 6,
                            right: 5,
                            child: Transform.scale(
                              scale: pop,
                              child: _UnreadBadge(count: state.unread),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    return TourAnchor(
      id: 'nav.notifications',
      // La guía de avisos abre la bandeja (sin esperar a que se cierre).
      onActivate: (_) {
        if (!_panel.isShowing) _open();
      },
      child: OverlayPortal(
        controller: _toastsPortal,
        overlayChildBuilder: (overlayContext) {
          final anchor = _anchor(overlayContext);
          if (anchor == null) return const SizedBox.shrink();
          return NotificationToasts(key: _toasts, cubit: _cubit, anchor: anchor, onOpenPanel: _open, onEmpty: () => _toastsPortal.hide());
        },
        child: OverlayPortal(
          controller: _panel,
          overlayChildBuilder: (overlayContext) {
            final anchor = _anchor(overlayContext);
            if (anchor == null) return const SizedBox.shrink();
            return _PanelOverlay(anchor: anchor, cubit: _cubit, onClose: _close);
          },
          child: bell,
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: scheme.error, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(fontSize: 11, height: 1, fontWeight: FontWeight.w700, color: scheme.onError),
      ),
    );
  }
}

/// La bandeja abierta: un tap afuera o Escape la cierra.
class _PanelOverlay extends StatelessWidget {
  const _PanelOverlay({required this.anchor, required this.cubit, required this.onClose});

  final BellAnchor anchor;
  final NotificationsCubit cubit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = anchor.inTopBar;
    final padding = MediaQuery.paddingOf(context);
    final panel = NotificationsPanel(cubit: cubit, compact: compact, onClose: onClose);

    final Widget positioned;
    if (compact) {
      positioned = Positioned(
        left: 8,
        right: 8,
        top: anchor.panelTop,
        bottom: 16 + padding.bottom,
        child: _Appear(
          fromTop: true,
          child: DecoratedBox(
            decoration: notificationSurface(scheme, caretSide: CaretSide.top, caretOffset: anchor.caretFromLeft),
            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: panel),
          ),
        ),
      );
    } else {
      final bottom = anchor.screen.height - anchor.panelBottom;
      final height = (anchor.panelBottom - 16).clamp(240.0, 680.0);
      positioned = Positioned(
        left: anchor.panelLeft,
        bottom: bottom,
        width: 404,
        height: height,
        child: _Appear(
          fromTop: false,
          child: DecoratedBox(
            decoration: notificationSurface(scheme, caretSide: CaretSide.left),
            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: panel),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose,
                  // En el celular la pantalla de atrás se oscurece, menos la barra.
                  child: compact
                      ? Padding(
                          padding: EdgeInsets.only(top: anchor.rect.bottom + 8),
                          child: const ColoredBox(color: Color(0x66000000)),
                        )
                      : const SizedBox.expand(),
                ),
              ),
              positioned,
            ],
          ),
        ),
      ),
    );
  }
}

/// Entrada de la bandeja: aparece desde la campana.
class _Appear extends StatelessWidget {
  const _Appear({required this.child, required this.fromTop});

  final Widget child;
  final bool fromTop;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.97 + 0.03 * t, alignment: fromTop ? Alignment.topRight : Alignment.bottomLeft, child: child),
      ),
    );
  }
}

/// El contenido de la bandeja: encabezado con filtros y los avisos
/// agrupados por día, de a 20, cargando más al llegar al final.
class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key, required this.cubit, this.compact = false, this.onClose, this.now});

  final NotificationsCubit cubit;

  /// Celular: encabezado más chico, con botón de cerrar y botones más grandes.
  final bool compact;
  final VoidCallback? onClose;
  final DateTime Function()? now;

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  NotificationsCubit get _cubit => widget.cubit;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    // Si ya estaba cargada, se ve lo que había mientras se actualiza.
    _cubit.load(silent: _cubit.state.loaded);
  }

  Future<void> _open(AdminNotification notification) async {
    final router = GoRouter.of(context);
    widget.onClose?.call();
    await _cubit.markRead(notification);
    router.go(adminNotificationLocation({...notification.data, 'type': notification.type}));
  }

  Future<void> _respond(AdminNotification notification, {required bool accept}) async {
    setState(() => _busy.add(notification.id));
    final messenger = ScaffoldMessenger.maybeOf(context);
    final error = await _cubit.respond(notification, accept: accept);
    if (!mounted) return;
    setState(() => _busy.remove(notification.id));
    if (error != null) messenger?.showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        bloc: _cubit,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, state),
            Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
            Expanded(
              child: TourAnchor(id: 'notifications.panel', child: _body(context, state)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, NotificationsState state) {
    final scheme = Theme.of(context).colorScheme;
    final canMark = state.unread > 0;
    final markColor = canMark ? scheme.primary : scheme.outline;

    final Widget title;
    if (widget.compact) {
      title = Row(
        children: [
          Expanded(
            child: Text(
              'Notificaciones',
              style: TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w500, color: scheme.onSurface),
            ),
          ),
          TourAnchor(
            id: 'notifications.readAll',
            child: IconButton(
              tooltip: 'Marcar todo como leído',
              onPressed: canMark ? _cubit.markAllRead : null,
              icon: Icon(Icons.done_all, size: 20, color: markColor),
              style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: widget.onClose,
            icon: Icon(Icons.close, size: 20, color: scheme.onSurfaceVariant),
            style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
          ),
        ],
      );
    } else {
      title = Row(
        children: [
          Expanded(
            child: Text(
              'Notificaciones',
              style: TextStyle(fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w500, color: scheme.onSurface),
            ),
          ),
          TourAnchor(
            id: 'notifications.readAll',
            child: Tooltip(
              message: 'Marcar todo como leído',
              child: TextButton.icon(
                onPressed: canMark ? _cubit.markAllRead : null,
                icon: Icon(Icons.done_all, size: 18, color: markColor),
                label: Text(
                  'Marcar todo leído',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: markColor),
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: widget.compact ? const EdgeInsets.fromLTRB(16, 12, 8, 12) : const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          SizedBox(height: widget.compact ? 10 : 12),
          Semantics(
            container: true,
            label: 'Filtrar',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'Todas', selected: state.filter == NotificationFilter.all, onTap: () => _cubit.setFilter(NotificationFilter.all)),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Sin leer',
                    count: state.unread,
                    selected: state.filter == NotificationFilter.unread,
                    onTap: () => _cubit.setFilter(NotificationFilter.unread),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Para resolver',
                    count: state.actionCount,
                    selected: state.filter == NotificationFilter.action,
                    onTap: () => _cubit.setFilter(NotificationFilter.action),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, NotificationsState state) {
    final scheme = Theme.of(context).colorScheme;

    if (state.loading && state.items.isEmpty) {
      return const SingleChildScrollView(child: NotificationsSkeleton());
    }
    if (state.error != null && state.items.isEmpty) {
      return NotificationsMessage(
        art: MessageTile(icon: Icons.cloud_off_outlined, background: scheme.surfaceContainerHighest, foreground: scheme.onSurfaceVariant),
        title: 'No pudimos cargar los avisos',
        message: 'Revisá la conexión e intentá de nuevo.',
        action: OutlinedButton(
          onPressed: _cubit.load,
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.primary,
            side: BorderSide(color: scheme.outline),
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('Reintentar'),
        ),
      );
    }

    final visible = state.visible;
    if (visible.isEmpty) {
      if (state.filter == NotificationFilter.all) {
        return const NotificationsMessage(
          art: TurniShapes(),
          title: 'Todavía no hay avisos',
          message: 'Acá vas a ver las solicitudes de turno, las señas que se acreditan y los resultados en disputa de los torneos.',
        );
      }
      final action = state.filter == NotificationFilter.action;
      return NotificationsMessage(
        art: MessageTile(icon: Icons.check, background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer),
        title: 'Estás al día',
        message: action ? 'No hay solicitudes ni partidos esperando una respuesta tuya.' : 'Ya leíste todos los avisos.',
        action: TextButton(
          onPressed: () => _cubit.setFilter(NotificationFilter.all),
          child: Text(
            'Ver todas',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.primary),
          ),
        ),
      );
    }

    final now = (widget.now ?? DateTime.now)();
    final rows = <Widget>[];
    String? group;
    for (final notification in visible) {
      final label = notificationGroup(notification.createdAt, now);
      if (label != group) {
        group = label;
        rows.add(_GroupHeader(label: label, compact: widget.compact));
      } else {
        rows.add(const SizedBox(height: 2));
      }
      rows.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 6 : 8),
          child: _NotificationRow(
            notification: notification,
            now: now,
            compact: widget.compact,
            busy: _busy.contains(notification.id),
            onOpen: () => _open(notification),
            onAccept: () => _respond(notification, accept: true),
            onReject: () => _respond(notification, accept: false),
          ),
        ),
      );
    }
    if (state.hasMore) {
      // Llegó al final: pide la página siguiente.
      rows.add(
        Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _cubit.loadMore());
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.only(top: widget.compact ? 0 : 4, bottom: widget.compact ? 8 : 12),
      children: rows,
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(compact ? 16 : 20, compact ? 12 : 14, 20, 6),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 11, height: 16 / 11, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.count = 0});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? scheme.secondaryContainer : scheme.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 32,
            padding: EdgeInsets.only(left: 12, right: count > 0 ? 10 : 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: selected ? scheme.primary : scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(9)),
                    child: Text(
                      '$count',
                      style: TextStyle(fontSize: 11, height: 1, fontWeight: FontWeight.w700, color: selected ? scheme.onPrimary : scheme.onSurface),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Una fila de la bandeja: el cuadrado del tipo, título, hora, el texto, la
/// etiqueta de contexto y, abajo, las acciones o cómo terminó.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.now,
    required this.compact,
    required this.busy,
    required this.onOpen,
    required this.onAccept,
    required this.onReject,
  });

  final AdminNotification notification;
  final DateTime now;
  final bool compact;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unread = !notification.isRead;
    final status = notificationStatus(notification);

    final Widget? footer;
    if (notification.isPendingRequest) {
      final accept = NotificationActionButton(label: 'Aceptar', tonal: true, large: compact, busy: busy, onPressed: onAccept);
      final reject = NotificationActionButton(label: 'Rechazar', large: compact, onPressed: busy ? null : onReject);
      footer = compact
          ? Row(
              children: [
                Expanded(child: accept),
                const SizedBox(width: 8),
                Expanded(child: reject),
              ],
            )
          : Row(children: [accept, const SizedBox(width: 8), reject]);
    } else if (notification.isDispute) {
      footer = Align(
        alignment: Alignment.centerLeft,
        child: NotificationActionButton(label: 'Resolver partido', trailingArrow: !compact, large: compact, onPressed: onOpen),
      );
    } else if (status != null) {
      footer = NotificationStatusLine(text: status.text, ok: status.ok);
    } else {
      footer = null;
    }

    return Material(
      color: unread ? scheme.primary.withValues(alpha: 0.07) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        hoverColor: scheme.onSurface.withValues(alpha: 0.05),
        onTap: onOpen,
        child: Padding(
          padding: compact ? const EdgeInsets.symmetric(horizontal: 10, vertical: 12) : const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NotificationKindTile(kind: notification.kind, dimmed: !unread),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notificationTitle(notification),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 20 / 14,
                                  fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                                  color: unread ? scheme.onSurface : scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(notificationTimeLabel(notification.createdAt, now), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                            if (unread) ...[
                              const SizedBox(width: 8),
                              Semantics(
                                label: 'Sin leer',
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        NotificationSentence(notification: notification, now: now),
                        NotificationContextChips(notification: notification, now: now, withClock: !compact),
                      ],
                    ),
                  ),
                ],
              ),
              if (compact)
                (footer != null ? Padding(padding: const EdgeInsets.only(left: 52, top: 10), child: footer) : const SizedBox.shrink())
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(52, 8, 0, 12),
                  child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 8), child: footer ?? const SizedBox.shrink()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
