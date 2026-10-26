import 'dart:async';

import 'package:flutter/material.dart';

/// Marca un widget para que un recorrido ([OnboardingStep.anchor]) lo pueda
/// resaltar por nombre, sin pasar `GlobalKey`s entre pantallas.
///
/// Los nombres van con el prefijo de la pantalla (`agenda.topBar`,
/// `clients.search`). Si hay varios montados con el mismo nombre (ej. una
/// card por turno), el recorrido usa el primero que se armó.
///
/// [onActivate] deja a la vista lo que el anchor representa (abrir esa tab,
/// esa sección o ese turno): un paso lo pide con [TourAnchors.activate] en
/// su `before`. Puede devolver el Future de un push: no se espera a que la
/// ruta se cierre.
class TourAnchor extends StatefulWidget {
  const TourAnchor({super.key, required this.id, required this.child, this.onActivate});

  final String id;
  final Widget child;
  final FutureOr<void> Function(BuildContext context)? onActivate;

  /// Activar = elegir la tab [index] del `TabController` de arriba (el de
  /// [controller] o el `DefaultTabController`), esperando la animación.
  static FutureOr<void> Function(BuildContext context) selectTab(int index, {TabController? controller}) =>
      (context) async {
        final tabs = controller ?? DefaultTabController.maybeOf(context);
        if (tabs == null || tabs.index == index) return;
        tabs.animateTo(index);
        await Future<void>.delayed(kTabScrollDuration + const Duration(milliseconds: 50));
      };

  @override
  State<TourAnchor> createState() => _TourAnchorState();
}

class _TourAnchorState extends State<TourAnchor> {
  late String _id = widget.id;

  @override
  void initState() {
    super.initState();
    TourAnchors._register(_id, this);
  }

  @override
  void didUpdateWidget(covariant TourAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      TourAnchors._unregister(_id, this);
      _id = widget.id;
      TourAnchors._register(_id, this);
    }
  }

  @override
  void dispose() {
    TourAnchors._unregister(_id, this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Registro de los [TourAnchor] montados.
class TourAnchors {
  TourAnchors._();

  static final _mounted = <String, List<_TourAnchorState>>{};

  static void _register(String id, _TourAnchorState state) => (_mounted[id] ??= []).add(state);

  static void _unregister(String id, _TourAnchorState state) {
    final list = _mounted[id];
    list?.remove(state);
    if (list != null && list.isEmpty) _mounted.remove(id);
  }

  /// El primero montado y visible (las ramas del menú que no se están
  /// mostrando quedan montadas, pero fuera de escena).
  static _TourAnchorState? _first(String id) {
    for (final state in _mounted[id] ?? const <_TourAnchorState>[]) {
      if (!state.mounted) continue;
      if (TickerMode.getValuesNotifier(state.context).value.enabled) return state;
    }
    return null;
  }

  static BuildContext? contextOf(String id) => _first(id)?.context;

  static bool isMounted(String id) => _first(id) != null;

  /// Corre el [TourAnchor.onActivate] del anchor [id]. Si todavía no está
  /// montado (ej. la pantalla está cargando) lo espera hasta [timeout].
  static Future<bool> activate(String id, {Duration timeout = const Duration(seconds: 5)}) async {
    final state = await _waitFor(id, timeout: timeout);
    final onActivate = state?.widget.onActivate;
    if (state == null || onActivate == null) return false;
    // Si abre una ruta, el Future es el del push y termina al cerrarla: se
    // espera solo lo que tarda una tab en cambiar.
    final result = onActivate(state.context);
    if (result is Future<void>) await Future.any([result, Future<void>.delayed(const Duration(milliseconds: 600))]);
    return true;
  }

  /// Espera a que el anchor [id] esté montado, hasta [timeout].
  static Future<BuildContext?> waitFor(String id, {Duration timeout = const Duration(seconds: 5)}) async =>
      (await _waitFor(id, timeout: timeout))?.context;

  static Future<_TourAnchorState?> _waitFor(String id, {required Duration timeout}) async {
    // Por intentos y no por reloj: en los tests el reloj de las esperas es falso.
    for (var tries = timeout.inMilliseconds ~/ 100;; tries--) {
      final state = _first(id);
      if (state != null) return state;
      if (tries <= 0) return null;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}
