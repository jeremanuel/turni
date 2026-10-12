import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/app_routes.dart';

/// Links a entidades del admin. Regla (ver CLAUDE.md): todo nombre de cliente
/// que se muestre es un [ClientLink] a su ficha, y todo turno que aparezca en
/// la ficha del cliente abre ese turno en la agenda. Ambos se subrayan al
/// pasar el mouse.

void openClient(BuildContext context, int clientId) =>
    context.goNamed(AppRoutes.CLIENT_ROUTE.name, pathParameters: {'clientId': '$clientId'});

void openSession(BuildContext context, int sessionId) =>
    context.goNamed(AppRoutes.SESSION_MANAGER_RESERVE_ROUTE.name, pathParameters: {'idSession': '$sessionId'});

/// Zona clickeable con cursor de link; [builder] recibe si está con hover para
/// subrayar lo que corresponda.
class HoverLink extends StatefulWidget {
  const HoverLink({super.key, required this.onTap, required this.builder});

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool hovered) builder;

  @override
  State<HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<HoverLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.builder(context, false);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(context, _hovered),
      ),
    );
  }
}

/// Texto subrayado con hover.
TextStyle? linkStyle(TextStyle? style, bool hovered) => hovered
    ? (style ?? const TextStyle()).copyWith(decoration: TextDecoration.underline, decorationColor: style?.color)
    : style;

/// Nombre de un cliente que abre su ficha. Sin [clientId] es texto plano.
class ClientLink extends StatelessWidget {
  const ClientLink({
    super.key,
    required this.clientId,
    required this.name,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.onTap,
  });

  final int? clientId;
  final String name;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Navegación propia (ej. pasar `extra` a la ruta); por defecto abre la ficha.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final id = clientId;
    return HoverLink(
      onTap: id == null ? null : (onTap ?? () => openClient(context, id)),
      builder: (context, hovered) => Text(
        name,
        maxLines: maxLines,
        overflow: overflow,
        style: linkStyle(style ?? DefaultTextStyle.of(context).style, hovered),
      ),
    );
  }
}

/// Un tramo de [ClientLinksText]: texto plano o el nombre de un cliente.
class LinkSegment {
  const LinkSegment.text(this.text) : clientId = null, isClient = false;
  const LinkSegment.client(this.clientId, this.text) : isClient = true;

  final String text;
  final int? clientId;
  final bool isClient;
}

/// Texto corrido con nombres de clientes clickeables (ej. "Con Juan y Ana"):
/// cada nombre abre su ficha y se subraya solo él con hover.
class ClientLinksText extends StatefulWidget {
  const ClientLinksText(this.segments, {super.key, this.style, this.maxLines, this.overflow});

  /// "Con A, B y C" a partir de una lista de clientes.
  factory ClientLinksText.people(
    List<(int?, String)> people, {
    Key? key,
    String prefix = '',
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    final segments = <LinkSegment>[if (prefix.isNotEmpty) LinkSegment.text(prefix)];
    for (final (i, (id, name)) in people.indexed) {
      if (i > 0) segments.add(LinkSegment.text(i == people.length - 1 ? ' y ' : ', '));
      segments.add(LinkSegment.client(id, name));
    }
    return ClientLinksText(segments, key: key, style: style, maxLines: maxLines, overflow: overflow);
  }

  final List<LinkSegment> segments;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<ClientLinksText> createState() => _ClientLinksTextState();
}

class _ClientLinksTextState extends State<ClientLinksText> {
  final _recognizers = <int, TapGestureRecognizer>{};
  int? _hovered;

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _recognizer(int index, int clientId) =>
      (_recognizers[index] ??= TapGestureRecognizer())..onTap = () => openClient(context, clientId);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          for (final (i, s) in widget.segments.indexed)
            if (!s.isClient || s.clientId == null)
              TextSpan(text: s.text)
            else
              TextSpan(
                text: s.text,
                recognizer: _recognizer(i, s.clientId!),
                mouseCursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hovered = i),
                onExit: (_) => setState(() => _hovered = null),
                style: _hovered == i ? const TextStyle(decoration: TextDecoration.underline) : null,
              ),
        ],
      ),
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
