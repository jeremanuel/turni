import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../utils/responsive_builder.dart';

/// En el celular el teclado nunca se abre solo: un campo de texto toma el
/// foco únicamente si la persona lo tocó. Lo demás (un `autofocus`, el foco
/// que Flutter devuelve al volver a una pantalla, un `requestFocus` de
/// código) se descarta.
///
/// La excepción son los flujos de búsqueda, que se abren para escribir (ej.
/// "Agregar ejercicio", el buscador de clientes a pantalla completa): su
/// campo va dentro de [AllowAutoKeyboard].
///
/// En escritorio y tablet no cambia nada. Se instala una vez en `main`.
class KeyboardGuard {
  KeyboardGuard._();

  static bool _installed = false;
  static Offset? _lastDown;
  static PointerDeviceKind? _lastKind;
  static Duration? _lastDownAt;
  static final _clock = Stopwatch();

  static FocusManager? _manager;

  static void install() {
    if (!_installed) {
      _installed = true;
      _clock.start();
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    }
    // Una sola vez por FocusManager (los tests arman uno por test).
    final manager = FocusManager.instance;
    if (identical(manager, _manager)) return;
    _manager = manager;
    manager.addListener(_onFocusChanged);
  }

  static void _onPointer(PointerEvent event) {
    if (event is! PointerDownEvent) return;
    _lastDown = event.position;
    _lastKind = event.kind;
    _lastDownAt = _clock.elapsed;
  }

  /// Celular: se toca con el dedo, o (antes del primer toque) la pantalla es
  /// angosta.
  static bool get _mobile {
    if (_lastKind != null) return _lastKind == PointerDeviceKind.touch && _narrow;
    return _narrow;
  }

  static bool get _narrow {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return false;
    final view = views.first;
    return view.physicalSize.width / view.devicePixelRatio < ResponsiveBuilder.mobileMaxWidth;
  }

  static void _onFocusChanged() {
    final node = FocusManager.instance.primaryFocus;
    final context = node?.context;
    if (node == null || context == null || !context.mounted) return;
    if (!_mobile) return;
    // Solo los campos de texto abren el teclado.
    if (context.findAncestorStateOfType<EditableTextState>() == null) return;
    if (context.findAncestorWidgetOfExactType<AllowAutoKeyboard>() != null) return;
    if (_tappedInside(node)) return;
    node.unfocus();
  }

  /// El último toque cayó sobre el campo, recién (el foco llega al soltar).
  static bool _tappedInside(FocusNode node) {
    final down = _lastDown;
    final at = _lastDownAt;
    if (down == null || at == null) return false;
    if (_clock.elapsed - at > const Duration(seconds: 2)) return false;
    // Margen: el dedo cae cerca del borde o sobre el label del campo.
    return node.rect.inflate(16).contains(down);
  }
}

/// Deja que el campo de adentro tome el foco solo (y abra el teclado) en el
/// celular: un flujo de búsqueda que se abre para escribir. Ver
/// [KeyboardGuard].
class AllowAutoKeyboard extends StatelessWidget {
  const AllowAutoKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
