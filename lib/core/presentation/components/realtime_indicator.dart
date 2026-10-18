import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/realtime/realtime_service.dart';

/// Color y título de cada estado de la conexión en vivo.
(Color, String) realtimeLook(RealtimeStatus status, ColorScheme scheme) => switch (status) {
      RealtimeStatus.connected => (const Color(0xFF34A853), 'Actualizado en tiempo real'),
      RealtimeStatus.connecting || RealtimeStatus.reconnecting => (const Color(0xFFF9AB00), 'Conectando…'),
      RealtimeStatus.disconnected => (scheme.error, 'Sin conexión en vivo'),
      RealtimeStatus.idle => (scheme.outline, 'Sin conexión en vivo'),
    };

String realtimeExplanation(RealtimeStatus status) => switch (status) {
      RealtimeStatus.connected => 'La agenda, las solicitudes, los pagos y los torneos se actualizan solos.',
      RealtimeStatus.connecting || RealtimeStatus.reconnecting => 'Conectando para mostrar los cambios al instante.',
      RealtimeStatus.disconnected || RealtimeStatus.idle =>
        'El panel funciona igual. Los datos se actualizan al volver a la pestaña o al recargar.',
    };

/// Estado que se muestra: el amarillo aparece recién después de un segundo,
/// para que una reconexión rápida no haga parpadear el punto.
class _ShownStatus extends ValueNotifier<RealtimeStatus> {
  static const _yellowDelay = Duration(seconds: 1);

  final RealtimeService _service;
  Timer? _pending;

  _ShownStatus(this._service) : super(_service.status.value) {
    _service.status.addListener(_onStatus);
  }

  void _onStatus() {
    final next = _service.status.value;
    _pending?.cancel();
    final yellow = next == RealtimeStatus.connecting || next == RealtimeStatus.reconnecting;
    if (yellow && value == RealtimeStatus.connected) {
      _pending = Timer(_yellowDelay, () => value = _service.status.value);
      return;
    }
    value = next;
  }

  @override
  void dispose() {
    _pending?.cancel();
    _service.status.removeListener(_onStatus);
    super.dispose();
  }
}

/// Punto verde, amarillo o rojo según si el panel recibe los cambios en vivo
/// (ver [RealtimeService]). Con [interactive], al tocarlo explica qué pasa y,
/// en rojo, ofrece reintentar.
class RealtimeIndicator extends StatefulWidget {
  final double size;

  /// Borde del color del fondo, para que se lea encima de un avatar o un ícono.
  final Color? borderColor;
  final bool interactive;

  const RealtimeIndicator({super.key, this.size = 10, this.borderColor, this.interactive = true});

  @override
  State<RealtimeIndicator> createState() => _RealtimeIndicatorState();
}

class _RealtimeIndicatorState extends State<RealtimeIndicator> {
  late final _shown = _ShownStatus(RealtimeService.instance);

  @override
  void dispose() {
    _shown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<RealtimeStatus>(
      valueListenable: _shown,
      builder: (context, status, _) {
        final (color, label) = realtimeLook(status, scheme);
        final dot = AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: widget.borderColor != null ? Border.all(color: widget.borderColor!, width: 2) : null,
          ),
        );
        if (!widget.interactive) return Semantics(label: label, child: dot);
        return Tooltip(
          message: label,
          child: Semantics(
            label: label,
            button: true,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => showRealtimeStatusDialog(context),
              child: Padding(padding: const EdgeInsets.all(4), child: dot),
            ),
          ),
        );
      },
    );
  }
}

/// Estado de la conexión en una línea, con "Reintentar" cuando está en rojo
/// (menú «Más» del celular y diálogo del indicador).
class RealtimeStatusTile extends StatelessWidget {
  const RealtimeStatusTile({super.key});

  @override
  Widget build(BuildContext context) {
    final service = RealtimeService.instance;
    return ValueListenableBuilder<RealtimeStatus>(
      valueListenable: service.status,
      builder: (context, status, _) {
        final (_, label) = realtimeLook(status, Theme.of(context).colorScheme);
        return ListTile(
          leading: const SizedBox(width: 24, child: Center(child: RealtimeIndicator(size: 12, interactive: false))),
          title: Text(label),
          subtitle: Text(realtimeExplanation(status)),
          trailing: status == RealtimeStatus.disconnected
              ? TextButton(onPressed: service.retry, child: const Text('Reintentar'))
              : null,
        );
      },
    );
  }
}

Future<void> showRealtimeStatusDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      content: const SizedBox(width: 380, child: RealtimeStatusTile()),
      actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cerrar'))],
    ),
  );
}
