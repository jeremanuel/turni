import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/presentation/components/loading/app_skeleton.dart';

import '../../../domain/entities/admin_notification.dart';
import 'notification_texts.dart';

/// Piezas del diseño "Bandeja de notificaciones" que comparten la bandeja y
/// los avisos flotantes.

/// Color de fondo y de ícono del cuadrado de cada tipo de aviso. Se
/// distinguen también por claridad, no solo por tono.
({Color background, Color foreground, IconData icon}) notificationTileStyle(ColorScheme scheme, NotificationKind kind) => switch (kind) {
  NotificationKind.request => (background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer, icon: Icons.event_outlined),
  NotificationKind.deposit => (background: scheme.tertiaryContainer, foreground: scheme.onTertiaryContainer, icon: Icons.payments_outlined),
  NotificationKind.tournament => (background: scheme.secondaryContainer, foreground: scheme.onSecondaryContainer, icon: Icons.emoji_events_outlined),
  NotificationKind.gym => (background: scheme.secondaryContainer, foreground: scheme.onSecondaryContainer, icon: Icons.fitness_center),
  NotificationKind.other => (background: scheme.surfaceContainerHighest, foreground: scheme.onSurfaceVariant, icon: Icons.notifications_outlined),
};

/// El cuadrado redondeado con el ícono del tipo (la forma del logo).
class NotificationKindTile extends StatelessWidget {
  const NotificationKindTile({super.key, required this.kind, this.dimmed = false});

  final NotificationKind kind;

  /// Los leídos se ven más apagados.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final style = notificationTileStyle(Theme.of(context).colorScheme, kind);
    return Opacity(
      opacity: dimmed ? 0.7 : 1,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: style.background, borderRadius: BorderRadius.circular(12)),
        child: Icon(style.icon, size: 20, color: style.foreground),
      ),
    );
  }
}

/// "**Martina López** pidió la Cancha 2 para hoy a las 19:00."
class NotificationSentence extends StatelessWidget {
  const NotificationSentence({super.key, required this.notification, required this.now});

  final AdminNotification notification;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sentence = notificationSentence(notification, now);
    if (sentence.who.isEmpty && sentence.rest.isEmpty) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 14, height: 20 / 14, color: scheme.onSurfaceVariant),
        children: [
          if (sentence.who.isNotEmpty)
            TextSpan(
              text: sentence.who,
              style: TextStyle(fontWeight: FontWeight.w500, color: scheme.onSurface),
            ),
          TextSpan(text: sentence.rest),
        ],
      ),
    );
  }
}

/// La etiqueta de contexto ("Cancha 2 · Hoy 19:00 · 90 min") y el monto.
class NotificationContextChips extends StatelessWidget {
  const NotificationContextChips({super.key, required this.notification, required this.now, this.withClock = true});

  final AdminNotification notification;
  final DateTime now;

  /// En los avisos flotantes la etiqueta va sin el reloj.
  final bool withClock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = notificationContextLabel(notification, now);
    final amount = notificationAmountLabel(notification);
    if (label == null && amount == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (label != null)
            _Chip(
              background: scheme.surfaceContainerHighest,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (withClock) ...[Icon(Icons.schedule, size: 14, color: scheme.onSurfaceVariant), const SizedBox(width: 6)],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 12, color: scheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (amount != null)
            _Chip(
              background: scheme.tertiaryContainer,
              child: Text(
                amount,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: scheme.onTertiaryContainer),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
    child: Align(alignment: Alignment.centerLeft, widthFactor: 1, child: child),
  );
}

/// "✓ Aceptada por Sol Paz" / "Venció sin respuesta".
class NotificationStatusLine extends StatelessWidget {
  const NotificationStatusLine({super.key, required this.text, required this.ok});

  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ok ? scheme.primary : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ok) ...[Icon(Icons.check, size: 16, color: color), const SizedBox(width: 6)],
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color),
          ),
        ),
      ],
    );
  }
}

/// Botón tonal ("Aceptar") y con borde ("Rechazar", "Resolver partido") del
/// diseño: 32 de alto (44 en el celular), radio 4.
class NotificationActionButton extends StatelessWidget {
  const NotificationActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tonal = false,
    this.trailingArrow = false,
    this.large = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool tonal;
  final bool trailingArrow;
  final bool large;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));
    final size = Size(0, large ? 44 : 32);
    final padding = EdgeInsets.symmetric(horizontal: tonal ? 14 : 12);
    final text = TextStyle(fontSize: large ? 14 : 13, fontWeight: FontWeight.w500);
    final content = busy
        ? InlineSpinner(size: 16, color: tonal ? scheme.onPrimaryContainer : scheme.onSurface)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (trailingArrow) ...[const SizedBox(width: 6), const Icon(Icons.arrow_forward, size: 16)],
            ],
          );
    if (tonal) {
      return FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          disabledBackgroundColor: scheme.primaryContainer,
          minimumSize: size,
          padding: padding,
          shape: shape,
          textStyle: text,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: content,
      );
    }
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline),
        minimumSize: size,
        padding: padding,
        shape: shape,
        textStyle: text,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: content,
    );
  }
}

/// Lado del que sale la flechita que apunta a la campana.
enum CaretSide { left, top }

/// Rectángulo redondeado con una flechita: la bandeja y los avisos flotantes
/// salen de la campana. [caretOffset] es la distancia del centro de la
/// flechita al borde de abajo (lado izquierdo) o al borde izquierdo (arriba).
class CaretBorder extends ShapeBorder {
  const CaretBorder({required this.side, this.radius = 16, this.caretSide, this.caretOffset = 35});

  final BorderSide side;
  final double radius;

  /// Null: sin flechita.
  final CaretSide? caretSide;
  final double caretOffset;

  static const _half = 8.5;
  static const _depth = 7.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  Path _path(Rect rect) {
    final body = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    if (caretSide == null) return body;
    final caret = Path();
    if (caretSide == CaretSide.left) {
      final cy = rect.bottom - caretOffset;
      caret
        ..moveTo(rect.left + 1, cy - _half)
        ..lineTo(rect.left - _depth, cy)
        ..lineTo(rect.left + 1, cy + _half)
        ..close();
    } else {
      final cx = rect.left + caretOffset;
      caret
        ..moveTo(cx - _half, rect.top + 1)
        ..lineTo(cx, rect.top - _depth)
        ..lineTo(cx + _half, rect.top + 1)
        ..close();
    }
    return Path.combine(PathOperation.union, body, caret);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_path(rect.deflate(side.width / 2)), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) => CaretBorder(side: side.scale(t), radius: radius * t, caretSide: caretSide, caretOffset: caretOffset);
}

/// Caja de la bandeja y de los avisos: surfaceContainerHigh, borde y sombra.
ShapeDecoration notificationSurface(ColorScheme scheme, {CaretSide? caretSide, double caretOffset = 35}) => ShapeDecoration(
  color: scheme.surfaceContainerHigh,
  shape: CaretBorder(
    side: BorderSide(color: scheme.outlineVariant),
    caretSide: caretSide,
    caretOffset: caretOffset,
  ),
  shadows: const [
    BoxShadow(color: Color(0x73000000), blurRadius: 48, offset: Offset(0, 24)),
    BoxShadow(color: Color(0x4D000000), blurRadius: 12, offset: Offset(0, 4)),
  ],
);

/// Las formas del logo (cuadrado redondeado + círculo): estado vacío.
class TurniShapes extends StatelessWidget {
  const TurniShapes({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final square = size * 58 / 88;
    final circle = size * 54 / 88;
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: square,
                height: square,
                decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(size * 14 / 88)),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: circle,
                height: circle,
                decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.85), shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un mensaje centrado de la bandeja: vacío, al día o sin conexión.
class NotificationsMessage extends StatelessWidget {
  const NotificationsMessage({super.key, required this.art, required this.title, required this.message, this.action});

  final Widget art;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            art,
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: scheme.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 20 / 14, color: scheme.onSurfaceVariant),
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

/// El cuadrado de 56 de los mensajes ("Estás al día", "Sin conexión").
class MessageTile extends StatelessWidget {
  const MessageTile({super.key, required this.icon, required this.background, required this.foreground});

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
    child: Icon(icon, size: 28, color: foreground),
  );
}

/// Esqueleto de la primera carga: tres filas.
class NotificationsSkeleton extends StatelessWidget {
  const NotificationsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strong = scheme.surfaceContainerHighest;
    final soft = Color.lerp(scheme.surfaceContainerHigh, scheme.surfaceContainerHighest, 0.5)!;
    Widget bar(double widthFactor, double height, Color color, double radius) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
      ),
    );
    Widget row(double a, double b, double c) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: strong, borderRadius: BorderRadius.circular(12)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [bar(a, 12, strong, 6), const SizedBox(height: 8), bar(b, 10, soft, 5), const SizedBox(height: 8), bar(c, 18, soft, 8)],
          ),
        ),
      ],
    );
    return Semantics(
      label: 'Cargando avisos',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 10,
              decoration: BoxDecoration(color: strong, borderRadius: BorderRadius.circular(5)),
            ),
            const SizedBox(height: 22),
            row(0.6, 0.9, 0.45),
            const SizedBox(height: 22),
            row(0.5, 0.8, 0.4),
            const SizedBox(height: 22),
            row(0.65, 0.85, 0.5),
          ],
        ),
      ),
    );
  }
}

/// Rotación de la campana al llegar un aviso (grados), según el avance 0..1
/// de los primeros 700 ms: se balancea y se amortigua.
double bellSwing(double t) {
  const keys = [0.0, 16.0, -13.0, 9.0, -6.0, 3.0, -1.0, 0.0];
  const stops = [0.0, 0.12, 0.26, 0.40, 0.54, 0.68, 0.82, 1.0];
  final x = t.clamp(0.0, 1.0);
  for (var i = 1; i < stops.length; i++) {
    if (x <= stops[i]) {
      final local = (x - stops[i - 1]) / (stops[i] - stops[i - 1]);
      return keys[i - 1] + (keys[i] - keys[i - 1]) * Curves.easeOut.transform(local);
    }
  }
  return 0;
}

/// Escala del número al llegar un aviso: salta a 1.3 y vuelve.
double badgePop(double t) {
  final x = t.clamp(0.0, 1.0);
  if (x < 0.55) return 0.3 + (1.3 - 0.3) * Curves.easeOut.transform(x / 0.55);
  return 1.3 - 0.3 * Curves.easeInOut.transform((x - 0.55) / 0.45);
}

const degrees = math.pi / 180;
