import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../infrastructure/localstorage/provider/local_storage.dart';

/// Un paso del recorrido: resalta [target] y explica qué es.
class OnboardingStep {
  const OnboardingStep({
    required this.target,
    required this.title,
    required this.body,
    this.before,
  });

  /// Widget a resaltar. Si al llegar al paso no está en pantalla, el paso se saltea.
  final GlobalKey target;

  final String title;

  final String body;

  /// Se corre antes de mostrar el paso, para dejar visible el [target]
  /// (ej. cambiar de tab). El recorrido espera a que termine.
  final Future<void> Function()? before;
}

/// Recorrido guiado ("tour") reutilizable: oscurece la pantalla, resalta un
/// widget por paso con un globo de texto y Saltear / Atrás / Siguiente.
///
/// Uso:
/// ```dart
/// OnboardingTour.showIfNew(context, id: 'club_config:$userId', steps: [...]);
/// ```
/// [id] identifica el recorrido y a quién se le mostró (incluir el usuario):
/// queda como visto al terminarlo o saltearlo, y [showIfNew] no lo repite.
/// [show] lo muestra igual (ej. un botón "Ver recorrido").
class OnboardingTour {
  OnboardingTour._();

  static String _storageKey(String id) => 'onboarding_seen:$id';

  static Future<bool> hasSeen(String id) async {
    try {
      return await LocalStorage.read(_storageKey(id)) == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen(String id) async {
    try {
      await LocalStorage.save(_storageKey(id), 'true');
    } catch (_) {
      // Sin almacenamiento el recorrido se vuelve a ofrecer: no es grave.
    }
  }

  static bool _showing = false;

  /// Muestra el recorrido si [id] todavía no se vio.
  static Future<void> showIfNew(BuildContext context, {required String id, required List<OnboardingStep> steps}) async {
    if (await hasSeen(id)) return;
    if (!context.mounted) return;
    await show(context, id: id, steps: steps);
  }

  /// Muestra el recorrido. Termina cuando se completa o se saltea.
  static Future<void> show(BuildContext context, {required String id, required List<OnboardingStep> steps}) async {
    if (_showing || steps.isEmpty) return;
    _showing = true;

    final completer = Completer<void>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _OnboardingOverlay(
        steps: steps,
        onClose: () {
          entry.remove();
          entry.dispose();
          _showing = false;
          markSeen(id);
          completer.complete();
        },
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    return completer.future;
  }
}

class _OnboardingOverlay extends StatefulWidget {
  const _OnboardingOverlay({required this.steps, required this.onClose});

  final List<OnboardingStep> steps;
  final VoidCallback onClose;

  @override
  State<_OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<_OnboardingOverlay> {
  final _focusNode = FocusNode();
  int _index = 0;
  bool _ready = false;
  Rect? _lastHole;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _goTo(0, forward: true);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    widget.onClose();
  }

  /// Va al paso [index]; si su target no está montado, sigue al próximo en
  /// la misma dirección (y cierra si no queda ninguno).
  Future<void> _goTo(int index, {required bool forward}) async {
    final from = _index;
    var i = index;
    setState(() => _ready = false);

    while (i >= 0 && i < widget.steps.length) {
      final step = widget.steps[i];
      await step.before?.call();
      // Que termine la animación del cambio (ej. de tab) antes de medir.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final targetContext = step.target.currentContext;
      if (targetContext != null && targetContext.mounted) {
        await Scrollable.ensureVisible(
          targetContext,
          alignment: 0.3,
          duration: const Duration(milliseconds: 250),
        );
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        setState(() {
          _index = i;
          _ready = true;
        });
        _focusNode.requestFocus();
        return;
      }
      i += forward ? 1 : -1;
    }

    if (forward) {
      _close();
    } else {
      // Para atrás no quedó ninguno visible: se queda en el que estaba.
      await _goTo(from, forward: true);
    }
  }

  Rect? _targetRect() {
    final box = widget.steps[_index].target.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    // Depender del tamaño de la pantalla: si cambia, se vuelve a medir.
    final screen = MediaQuery.sizeOf(context);
    final rect = _ready ? _targetRect()?.inflate(6) : null;
    // Entre paso y paso (sin rect) el hueco se queda donde estaba.
    if (rect != null) _lastHole = rect;
    final hole = _lastHole;
    final colorScheme = Theme.of(context).colorScheme;
    final scrim = colorScheme.scrim.withValues(alpha: 0.74);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          _close();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight && _ready) {
          _next();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft && _ready && _index > 0) {
          _goTo(_index - 1, forward: false);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        children: [
          // Bloquea la pantalla de abajo mientras dura el recorrido.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: hole == null
                  ? CustomPaint(
                      size: screen,
                      painter: _SpotlightPainter(hole: null, scrim: scrim, outline: colorScheme.primary),
                    )
                  : TweenAnimationBuilder<Rect?>(
                      tween: RectTween(begin: hole, end: hole),
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      builder: (context, animated, _) => CustomPaint(
                        size: screen,
                        painter: _SpotlightPainter(hole: animated, scrim: scrim, outline: colorScheme.primary),
                      ),
                    ),
            ),
          ),
          if (rect != null) _buildCard(context, rect, screen),
        ],
      ),
    );
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      _close();
    } else {
      _goTo(_index + 1, forward: true);
    }
  }

  Widget _buildCard(BuildContext context, Rect target, Size screen) {
    const margin = 16.0;
    const gap = 12.0;
    final width = math.min(360.0, screen.width - margin * 2);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final step = widget.steps[_index];
    final isLast = _index == widget.steps.length - 1;

    // Debajo del target si entra, si no arriba; horizontalmente alineado a
    // él sin salirse de la pantalla.
    final spaceBelow = screen.height - target.bottom;
    final below = spaceBelow >= 220 || spaceBelow >= target.top;
    final left = (target.left).clamp(margin, math.max(margin, screen.width - width - margin)).toDouble();

    final card = Material(
      color: colorScheme.surfaceContainerHighest,
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paso ${_index + 1} de ${widget.steps.length}',
              style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(step.title, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                step.body,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isLast) TextButton(onPressed: _close, child: const Text('Saltear')),
                const Spacer(),
                if (_index > 0)
                  TextButton(
                    onPressed: () => _goTo(_index - 1, forward: false),
                    child: const Text('Atrás'),
                  ),
                const SizedBox(width: 4),
                FilledButton(onPressed: _next, child: Text(isLast ? 'Listo' : 'Siguiente')),
              ],
            ),
          ],
        ),
      ),
    );

    return Positioned(
      left: left,
      width: width,
      top: below ? math.min(target.bottom + gap, screen.height - margin) : null,
      bottom: below ? null : math.max(screen.height - target.top + gap, margin),
      child: card,
    );
  }
}

/// Scrim de pantalla completa con un hueco redondeado sobre el target.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.hole, required this.scrim, required this.outline});

  final Rect? hole;
  final Color scrim;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    final hole = this.hole;
    if (hole == null) {
      canvas.drawPath(screen, Paint()..color = scrim);
      return;
    }

    final rrect = RRect.fromRectAndRadius(hole, const Radius.circular(12));
    final path = Path.combine(PathOperation.difference, screen, Path()..addRRect(rrect));
    canvas.drawPath(path, Paint()..color = scrim);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.scrim != scrim || oldDelegate.outline != outline;
}
