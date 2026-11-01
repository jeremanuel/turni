import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../infrastructure/localstorage/provider/local_storage.dart';
import 'tour_anchor.dart';

/// Un paso del recorrido: resalta [target] (o el [TourAnchor] [anchor]) y
/// explica qué es.
class OnboardingStep {
  const OnboardingStep({
    this.target,
    this.anchor,
    required this.title,
    required this.body,
    this.before,
    this.optional = false,
    this.waitFor,
  }) : assert(target != null || anchor != null, 'El paso necesita un target o un anchor');

  /// Widget a resaltar. Si al llegar al paso no está en pantalla, el paso se saltea.
  final GlobalKey? target;

  /// Nombre del [TourAnchor] a resaltar (alternativa a [target]).
  final String? anchor;

  final String title;

  final String body;

  /// Se corre antes de mostrar el paso, para dejar visible el [target]
  /// (ej. cambiar de tab). El recorrido espera a que termine.
  final Future<void> Function()? before;

  /// Puede faltar sin que sea un error: depende de los datos (ej. que haya
  /// solicitudes por aprobar) o de los permisos del rol. Lo usan los tests
  /// que recorren las guías ([OnboardingResult.missing]).
  final bool optional;

  /// Cuánto esperar a que aparezca el target (pantallas que cargan datos).
  /// Por defecto, más tiempo en el primer paso y después de un [before].
  final Duration? waitFor;

  BuildContext? get targetContext => target?.currentContext ?? (anchor == null ? null : TourAnchors.contextOf(anchor!));
}

/// Cómo terminó un recorrido.
class OnboardingResult {
  const OnboardingResult({required this.shown, required this.skipped, required this.completed});

  /// Índices de los pasos que se mostraron.
  final List<int> shown;

  /// Índices de los pasos salteados porque su target no estaba en pantalla.
  final List<int> skipped;

  /// Llegó hasta "Listo" (no se salteó ni se cerró antes).
  final bool completed;

  static const none = OnboardingResult(shown: [], skipped: [], completed: false);

  /// Pasos obligatorios que no aparecieron.
  List<int> missing(List<OnboardingStep> steps) => [for (final i in skipped) if (!steps[i].optional) i];
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
///
/// El recorrido va en el overlay raíz, por encima de las rutas: sigue en
/// pantalla aunque un paso navegue a otra (ver las guías de `admin/guides`).
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

  /// Hay un recorrido en pantalla.
  static bool get isShowing => _showing;

  /// Muestra el recorrido si [id] todavía no se vio.
  static Future<void> showIfNew(BuildContext context, {required String id, required List<OnboardingStep> steps}) async {
    if (await hasSeen(id)) return;
    if (!context.mounted) return;
    await show(context, id: id, steps: steps);
  }

  /// Muestra el recorrido. Termina cuando se completa o se saltea.
  static Future<OnboardingResult> show(BuildContext context, {required String id, required List<OnboardingStep> steps}) async {
    if (_showing || steps.isEmpty) return OnboardingResult.none;
    // El del Navigator raíz: también sirve su propio context (el de
    // `rootNavigatorKey`), que no tiene un Overlay arriba.
    final overlay = Navigator.maybeOf(context, rootNavigator: true)?.overlay ?? Overlay.of(context, rootOverlay: true);
    _showing = true;

    final completer = Completer<OnboardingResult>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _OnboardingOverlay(
        steps: steps,
        onClose: (result) {
          entry.remove();
          entry.dispose();
          _showing = false;
          markSeen(id);
          completer.complete(result);
        },
      ),
    );
    overlay.insert(entry);
    return completer.future;
  }
}

class _OnboardingOverlay extends StatefulWidget {
  const _OnboardingOverlay({required this.steps, required this.onClose});

  final List<OnboardingStep> steps;
  final void Function(OnboardingResult result) onClose;

  @override
  State<_OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<_OnboardingOverlay> {
  final _focusNode = FocusNode();
  int _index = 0;
  bool _ready = false;
  Rect? _lastHole;
  bool _closed = false;
  final _shown = <int>{};
  final _skipped = <int>{};

  /// Última medida del target. Se vuelve a medir seguido: la pantalla de
  /// abajo puede moverse (datos que terminan de cargar, una tab que anima).
  Rect? _measured;
  Timer? _remeasure;

  @override
  void initState() {
    super.initState();
    _remeasure = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted || !_ready) return;
      if (_targetRect() != _measured) setState(() {});
    });
    _goTo(0, forward: true);
  }

  @override
  void dispose() {
    _remeasure?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _close({bool completed = false}) {
    if (_closed) return;
    _closed = true;
    _remeasure?.cancel();
    widget.onClose(OnboardingResult(
      shown: _shown.toList()..sort(),
      skipped: _skipped.difference(_shown).toList()..sort(),
      completed: completed,
    ));
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

      final targetContext = await _waitForTarget(step, first: i == 0);
      if (!mounted) return;
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
        _shown.add(i);
        _focusNode.requestFocus();
        return;
      }
      _skipped.add(i);
      i += forward ? 1 : -1;
    }

    if (forward) {
      _close(completed: true);
    } else {
      // Para atrás no quedó ninguno visible: se queda en el que estaba.
      await _goTo(from, forward: true);
    }
  }

  /// El target del paso, esperándolo un rato si la pantalla está cargando.
  Future<BuildContext?> _waitForTarget(OnboardingStep step, {required bool first}) async {
    final timeout = step.waitFor ??
        (first || step.before != null ? const Duration(seconds: 4) : const Duration(milliseconds: 600));
    // Por intentos y no por reloj: en los tests el reloj de las esperas es falso.
    for (var tries = timeout.inMilliseconds ~/ 100; mounted; tries--) {
      final context = step.targetContext;
      final box = context != null && context.mounted ? context.findRenderObject() : null;
      if (box is RenderBox && box.attached && box.hasSize) return context;
      if (tries <= 0) return null;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }

  Rect? _targetRect() {
    final box = widget.steps[_index].targetContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    // Depender del tamaño de la pantalla: si cambia, se vuelve a medir.
    final screen = MediaQuery.sizeOf(context);
    _measured = _ready ? _targetRect() : null;
    final rect = _measured?.inflate(6);
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
          if (rect != null)
            _buildCard(context, rect, screen)
          else
            // Entre pasos (la pantalla de abajo puede estar cargando): que se
            // vea que el recorrido sigue y que se puede cortar.
            Positioned(
              right: 16,
              bottom: 16,
              child: Material(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      const Text('Cargando…'),
                      const SizedBox(width: 8),
                      TextButton(onPressed: _close, child: const Text('Salir')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      _close(completed: true);
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

    // Debajo del target si entra, si no arriba; si no entra en ninguno de
    // los dos (un target que ocupa casi toda la pantalla, ej. toda la
    // agenda), adentro, abajo. Horizontalmente alineado a él sin salirse de
    // la pantalla.
    const cardRoom = 220.0 + gap;
    final below = screen.height - target.bottom >= cardRoom;
    final above = !below && target.top >= cardRoom;
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
      top: below ? target.bottom + gap : null,
      bottom: below ? null : above ? screen.height - target.top + gap : margin,
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
    // Par-impar y no `Path.combine`: en la web la diferencia no recortaba el
    // hueco y el target quedaba tan oscuro como el resto.
    final path = screen
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
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
