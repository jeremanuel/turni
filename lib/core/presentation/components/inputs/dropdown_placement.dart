import 'package:flutter/material.dart';

/// Dónde abrir una lista desplegable pegada a un campo (con
/// `CompositedTransformFollower`): abajo si entra, o si abajo hay más lugar
/// que arriba; si no, arriba. El alto se recorta al lugar que hay, así la
/// lista nunca queda cortada por el borde de la pantalla (ej. el último campo
/// de una página larga).
class DropdownPlacement {
  const DropdownPlacement._({required this.above, required this.maxHeight, required this.gap});

  /// [field]: el contexto del campo (el `CompositedTransformTarget`).
  /// [preferredHeight]: el alto máximo de la lista si hubiera lugar.
  factory DropdownPlacement.of(BuildContext? field, {required double preferredHeight, double gap = 4, double margin = 8}) {
    final box = field?.findRenderObject() as RenderBox?;
    final overlay = field == null ? null : Overlay.maybeOf(field)?.context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null || !box.hasSize || !box.attached) {
      return DropdownPlacement._(above: false, maxHeight: preferredHeight, gap: gap);
    }
    final top = box.localToGlobal(Offset.zero, ancestor: overlay).dy;
    final keyboard = MediaQuery.viewInsetsOf(field!).bottom;
    final below = overlay.size.height - keyboard - (top + box.size.height) - gap - margin;
    final aboveSpace = top - gap - margin;
    final up = below < preferredHeight && aboveSpace > below;
    final space = up ? aboveSpace : below;
    return DropdownPlacement._(above: up, maxHeight: space.clamp(0.0, preferredHeight), gap: gap);
  }

  final bool above;
  final double maxHeight;
  final double gap;

  Alignment get targetAnchor => above ? Alignment.topLeft : Alignment.bottomLeft;
  Alignment get followerAnchor => above ? Alignment.bottomLeft : Alignment.topLeft;
  Offset get offset => Offset(0, above ? -gap : gap);

  /// Para el `Align` hijo del follower: lo pega al campo de su lado.
  Alignment get alignment => above ? Alignment.bottomLeft : Alignment.topLeft;
}
