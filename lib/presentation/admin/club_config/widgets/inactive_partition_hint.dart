import 'dart:async';

import 'package:flutter/material.dart';

import '../club_config_focus.dart';

/// Envuelve una opción (chip, ítem de combo, fila) que representa un sector o
/// cancha INACTIVO: al pasar el mouse (o tocarla, en touch) muestra un aviso
/// "se encuentra inactiva" con un enlace que abre la configuración apuntando
/// a ese sector/cancha. Si [inactive] es false devuelve [child] tal cual.
///
/// No usa `Tooltip` porque el `Tooltip` de Material no es interactivo (no se
/// puede clickear nada adentro): el aviso queda abierto mientras el mouse
/// esté sobre la opción o sobre el propio aviso, para poder llegar al enlace.
/// Deshabilitar la opción en sí (sin `onTap`/`enabled: false`) queda a cargo
/// de quien lo usa.
class InactivePartitionHint extends StatefulWidget {
  const InactivePartitionHint({
    super.key,
    required this.inactive,
    required this.message,
    required this.focus,
    required this.child,
    this.onConfigClosed,
  });

  final bool inactive;

  /// Ej. "Esta modalidad se encuentra inactiva."
  final String message;

  /// A dónde apunta el enlace "Abrir configuración".
  final ClubConfigFocus focus;
  final Widget child;

  /// Se llama al cerrar la configuración abierta desde el enlace — para
  /// recargar lo que el admin pudo haber cambiado (ej. reactivar la cancha).
  final VoidCallback? onConfigClosed;

  /// Mensajes estándar, para que todas las pantallas digan lo mismo.
  static const clubPartitionMessage = 'Esta modalidad se encuentra inactiva.';
  static const physicalPartitionMessage = 'Esta cancha se encuentra inactiva.';

  @override
  State<InactivePartitionHint> createState() => _InactivePartitionHintState();
}

class _InactivePartitionHintState extends State<InactivePartitionHint> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _show() {
    _hideTimer?.cancel();
    if (!_controller.isShowing) _controller.show();
  }

  void _hide() {
    _hideTimer?.cancel();
    if (_controller.isShowing) _controller.hide();
  }

  /// Con delay para poder cruzar el hueco entre la opción y el aviso sin que
  /// se cierre en el medio.
  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) _hide();
    });
  }

  Future<void> _openConfig() async {
    _hide();
    await openClubConfig(context, widget.focus);
    widget.onConfigClosed?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.inactive) return widget.child;

    return TapRegion(
      groupId: this,
      onTapOutside: (_) => _hide(),
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _controller,
          overlayChildBuilder: _buildOverlay,
          child: MouseRegion(
            onEnter: (_) => _show(),
            onExit: (_) => _scheduleHide(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _controller.isShowing ? _hide() : _show(),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CompositedTransformFollower(
      link: _link,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 6),
      child: Align(
        alignment: Alignment.topLeft,
        child: TapRegion(
          groupId: this,
          child: MouseRegion(
            onEnter: (_) => _show(),
            onExit: (_) => _scheduleHide(),
            child: Material(
              color: colorScheme.inverseSurface,
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.block, size: 16, color: colorScheme.onInverseSurface),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onInverseSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _openConfig,
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.inversePrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Abrir configuración'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
