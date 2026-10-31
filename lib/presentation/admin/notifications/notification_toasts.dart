import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/admin_notification.dart';
import 'notification_texts.dart';
import 'notification_widgets.dart';
import 'notifications_cubit.dart';
import 'notifications_panel.dart';

/// Cuánto queda a la vista un aviso que se cierra solo, y uno ya respondido.
const toastDuration = Duration(seconds: 7);
const resolvedToastDuration = Duration(milliseconds: 2500);

/// Los avisos flotantes que salen de la campana cuando llega uno con la app
/// abierta (diseño "Bandeja de notificaciones", "Cuando entra un aviso").
///
/// - Se ven como máximo 2: el más nuevo pegado a la campana. Si hay más,
///   "+N avisos más · Ver en la bandeja".
/// - Las solicitudes de turno esperan Aceptar, Rechazar o la X; las demás se
///   cierran solas a los 7 s (la barra se frena con el mouse encima).
class NotificationToasts extends StatefulWidget {
  const NotificationToasts({super.key, required this.cubit, required this.anchor, required this.onOpenPanel, required this.onEmpty});

  final NotificationsCubit cubit;
  final BellAnchor anchor;
  final VoidCallback onOpenPanel;

  /// Se cerró el último: se puede sacar la capa.
  final VoidCallback onEmpty;

  @override
  State<NotificationToasts> createState() => NotificationToastsState();
}

class _Entry {
  _Entry(this.notification);

  AdminNotification notification;

  /// Respondida desde el aviso: `true` aceptada, `false` rechazada.
  bool? accepted;
  bool busy = false;
}

class NotificationToastsState extends State<NotificationToasts> {
  final List<_Entry> _entries = [];

  /// Suma los avisos que llegaron (sin repetir).
  void add(List<AdminNotification> fresh) {
    final known = _entries.map((e) => e.notification.id).toSet();
    setState(() {
      // Llegan del más nuevo al más viejo: el más nuevo queda último (pegado a la campana).
      for (final n in fresh.reversed) {
        if (!known.contains(n.id)) _entries.add(_Entry(n));
      }
    });
  }

  void _remove(_Entry entry) {
    setState(() => _entries.remove(entry));
    if (_entries.isEmpty) widget.onEmpty();
  }

  Future<void> _open(_Entry entry) async {
    final router = GoRouter.of(context);
    _remove(entry);
    await widget.cubit.markRead(entry.notification);
    router.go(adminNotificationLocation({...entry.notification.data, 'type': entry.notification.type}));
  }

  Future<void> _respond(_Entry entry, {required bool accept}) async {
    setState(() => entry.busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final error = await widget.cubit.respond(entry.notification, accept: accept);
    if (!mounted) return;
    setState(() {
      entry.busy = false;
      if (error == null) entry.accepted = accept;
    });
    if (error != null) messenger?.showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final anchor = widget.anchor;
    final compact = anchor.inTopBar;
    final visible = _entries.length <= 2 ? _entries : _entries.sublist(_entries.length - 2);
    final extra = _entries.length - visible.length;

    Widget toast(_Entry entry, {required bool anchored}) => _Toast(
      key: ValueKey(entry.notification.id),
      entry: entry,
      compact: compact,
      caretSide: anchored ? (compact ? CaretSide.top : CaretSide.left) : null,
      caretOffset: compact ? anchor.caretFromLeft : 35,
      onOpen: () => _open(entry),
      onClose: () => _remove(entry),
      onAccept: () => _respond(entry, accept: true),
      onReject: () => _respond(entry, accept: false),
    );

    final more = extra > 0
        ? Material(
            color: scheme.surfaceContainerHigh,
            elevation: 6,
            shadowColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onOpenPanel,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                child: Text(
                  '+$extra ${extra == 1 ? 'aviso más' : 'avisos más'} · Ver en la bandeja',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: scheme.primary),
                ),
              ),
            ),
          )
        : null;

    if (compact) {
      // Celular: bajan de la barra, el más nuevo arriba (con la flechita).
      final ordered = visible.reversed.toList();
      return Positioned(
        left: 8,
        right: 8,
        top: anchor.panelTop,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, entry) in ordered.indexed) ...[if (i > 0) const SizedBox(height: 8), toast(entry, anchored: i == 0)],
            if (more != null) ...[const SizedBox(height: 8), more],
          ],
        ),
      );
    }

    return Positioned(
      left: anchor.panelLeft,
      bottom: anchor.screen.height - anchor.panelBottom,
      width: 384,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (more != null) ...[more, const SizedBox(height: 8)],
          for (final (i, entry) in visible.indexed) ...[if (i > 0) const SizedBox(height: 8), toast(entry, anchored: i == visible.length - 1)],
        ],
      ),
    );
  }
}

class _Toast extends StatefulWidget {
  const _Toast({
    super.key,
    required this.entry,
    required this.compact,
    required this.caretSide,
    required this.caretOffset,
    required this.onOpen,
    required this.onClose,
    required this.onAccept,
    required this.onReject,
  });

  final _Entry entry;
  final bool compact;
  final CaretSide? caretSide;
  final double caretOffset;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 280))..forward();
  AnimationController? _timer;

  AdminNotification get _n => widget.entry.notification;

  /// Las solicitudes no se van solas hasta que se responden.
  bool get _timed => _n.kind != NotificationKind.request || widget.entry.accepted != null;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _Toast oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimer();
  }

  void _syncTimer() {
    if (!_timed) return;
    final duration = widget.entry.accepted != null ? resolvedToastDuration : toastDuration;
    if (_timer?.duration == duration) return;
    _timer?.dispose();
    _timer = AnimationController(vsync: this, duration: duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onClose();
      })
      ..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _timer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entry = widget.entry;
    final now = DateTime.now();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final compact = widget.compact;

    final Widget? footer;
    if (entry.accepted != null) {
      footer = NotificationStatusLine(text: entry.accepted! ? 'Aceptada · el turno quedó confirmado' : 'Rechazada · le avisamos al cliente', ok: true);
    } else if (_n.isPendingRequest || (_n.kind == NotificationKind.request && _n.context == null)) {
      final accept = NotificationActionButton(label: 'Aceptar', tonal: true, large: compact, busy: entry.busy, onPressed: widget.onAccept);
      final reject = NotificationActionButton(label: 'Rechazar', large: compact, onPressed: entry.busy ? null : widget.onReject);
      footer = compact
          ? Row(
              children: [
                Expanded(child: accept),
                const SizedBox(width: 8),
                Expanded(child: reject),
              ],
            )
          : Row(children: [accept, const SizedBox(width: 8), reject]);
    } else if (_n.isDispute) {
      footer = NotificationActionButton(label: 'Resolver partido', large: compact, onPressed: widget.onOpen);
    } else {
      footer = null;
    }

    final card = DecoratedBox(
      decoration: notificationSurface(scheme, caretSide: widget.caretSide, caretOffset: widget.caretOffset),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onOpen,
          child: Semantics(
            liveRegion: true,
            container: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 14, compact ? 6 : 8, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NotificationKindTile(kind: _n.kind),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notificationTitle(_n),
                                    style: TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w700, color: scheme.onSurface),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ahora',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: scheme.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            NotificationSentence(notification: _n, now: now),
                            NotificationContextChips(notification: _n, now: now, withClock: false),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: compact ? 44 : 32,
                        height: compact ? 44 : 32,
                        child: IconButton(
                          tooltip: 'Cerrar aviso',
                          padding: EdgeInsets.zero,
                          onPressed: widget.onClose,
                          icon: Icon(Icons.close, size: 18, color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(padding: EdgeInsets.fromLTRB(66, footer == null ? 0 : (compact ? 12 : 10), 14, 14), child: footer ?? const SizedBox(height: 4)),
                if (_timer != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Transform.translate(
                      offset: const Offset(0, -1),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                        child: SizedBox(
                          height: 3,
                          child: ColoredBox(
                            color: scheme.surfaceContainerHighest,
                            child: AnimatedBuilder(
                              animation: _timer!,
                              builder: (context, _) => FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: 1 - _timer!.value,
                                child: ColoredBox(color: scheme.primary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final hoverable = MouseRegion(
      // La barra se frena con el mouse encima.
      onEnter: (_) => _timer?.stop(),
      onExit: (_) {
        if (_timer != null && !_timer!.isCompleted) _timer!.forward();
      },
      child: card,
    );

    if (reduceMotion) return hoverable;
    return AnimatedBuilder(
      animation: _enter,
      child: hoverable,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_enter.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: compact ? Offset(0, -14 * (1 - t)) : Offset(-14 * (1 - t), 0),
            child: Transform.scale(scale: 0.96 + 0.04 * t, alignment: compact ? Alignment.topRight : Alignment.bottomLeft, child: child),
          ),
        );
      },
    );
  }
}
