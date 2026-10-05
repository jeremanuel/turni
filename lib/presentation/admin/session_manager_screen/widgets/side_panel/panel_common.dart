import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/thousands_format.dart';
import '../../../../../domain/entities/session.dart';

/// Piezas comunes del panel lateral del gestor de turnos (diseño "Gestor de
/// turnos: layout, menú lateral y panel del turno").

String panelPrice(num value) => '\$${ThousandsFormat.formatPrice(value)}';

String panelHm(DateTime value) => DateFormat('HH:mm').format(value);

String panelRange(Session session) => '${panelHm(session.startTime)} – ${panelHm(session.endTime as DateTime)}';

String panelInitials(String fullName) {
  final words = fullName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return (words.first.substring(0, 1) + words.last.substring(0, 1)).toUpperCase();
}

/// "Lunes 5 de octubre".
String panelDayTitle(DateTime date) {
  final text = DateFormat("EEEE d 'de' MMMM", 'es').format(date);
  return text[0].toUpperCase() + text.substring(1);
}

TextStyle panelButtonText(BuildContext context, {double size = 14}) =>
    Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: size, fontWeight: FontWeight.w500);

/// Estructura del panel: contenido con scroll y pie fijo opcional.
class PanelFrame extends StatelessWidget {
  const PanelFrame({super.key, required this.children, this.footer, this.gap = 16});

  final List<Widget> children;
  final Widget? footer;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(height: gap),
                  children[i],
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: scheme.outlineVariant))),
            child: footer,
          ),
      ],
    );
  }
}

/// Encabezado de un sub-panel (cobrar, agregar consumo, nuevo cliente):
/// flecha para volver, título y bajada.
class PanelSubHeader extends StatelessWidget {
  const PanelSubHeader({super.key, required this.title, required this.subtitle, required this.onBack, this.backTooltip});

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final String? backTooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Transform.translate(
          offset: const Offset(-8, 0),
          child: IconButton(
            tooltip: backTooltip ?? 'Volver al turno',
            onPressed: onBack,
            style: IconButton.styleFrom(
              foregroundColor: scheme.onSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 22, height: 28 / 22, color: scheme.onSurface)),
              Text(subtitle, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Encabezado del detalle de un turno: estado, cerrar, horario y bajada.
class PanelSessionHeader extends StatelessWidget {
  const PanelSessionHeader({
    super.key,
    required this.status,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final Widget status;
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            status,
            const Spacer(),
            IconButton(
              tooltip: 'Cerrar detalle',
              onPressed: onClose,
              style: IconButton.styleFrom(
                foregroundColor: scheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 22, height: 28 / 22, color: scheme.onSurface)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Chip de estado (24px, radio 8).
class PanelStatusChip extends StatelessWidget {
  const PanelStatusChip({super.key, required this.label, this.background, this.foreground, this.dashedBorder});

  final String label;
  final Color? background;
  final Color? foreground;

  /// Borde punteado (estado "Libre").
  final Color? dashedBorder;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Center(
        widthFactor: 1,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: foreground)),
      ),
    );
    if (dashedBorder == null) return chip;
    return CustomPaint(foregroundPainter: _Dashed(dashedBorder!), child: chip);
  }
}

class _Dashed extends CustomPainter {
  _Dashed(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Dashed oldDelegate) => oldDelegate.color != color;
}

/// Card del panel: `surfaceContainerHigh`, radio 12.
class PanelCard extends StatelessWidget {
  const PanelCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// Avatar circular con iniciales.
class PanelAvatar extends StatelessWidget {
  const PanelAvatar({super.key, required this.name, this.size = 40, this.background, this.foreground});

  final String name;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background ?? scheme.primary),
      child: Text(
        panelInitials(name),
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w700,
          color: foreground ?? scheme.onPrimary,
          height: 1,
        ),
      ),
    );
  }
}

/// Botón principal del pie (40px, radio 4). Deshabilitado:
/// `surfaceContainerHighest` con texto `outline`.
class PanelFilledButton extends StatelessWidget {
  const PanelFilledButton({super.key, required this.label, required this.onPressed, this.icon, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: scheme.surfaceContainerHighest,
        disabledForegroundColor: scheme.outline,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: panelButtonText(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.outline))
          else if (icon != null)
            Icon(icon, size: 18),
          if (loading || icon != null) const SizedBox(width: 8),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// Botón de texto del pie (40px, padding 12, radio 4).
class PanelTextButton extends StatelessWidget {
  const PanelTextButton({super.key, required this.label, required this.onPressed, this.color, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: color ?? scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: panelButtonText(context),
      ),
      child: icon == null
          ? Text(label)
          : Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)]),
    );
  }
}

/// Confirmación simple para acciones destructivas del panel.
Future<bool> confirmPanelAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Campo de texto del panel (44px, borde `outline`; con foco, 2px `primary`).
InputDecoration panelInputDecoration(BuildContext context, {String? hintText, Widget? prefixIcon}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
    prefixIcon: prefixIcon,
    prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 18),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    enabledBorder: border(scheme.outline, 1),
    border: border(scheme.outline, 1),
    focusedBorder: border(scheme.primary, 2),
    errorBorder: border(scheme.error, 1),
    focusedErrorBorder: border(scheme.error, 2),
  );
}

/// Chip seleccionable de 36px (medios de pago, categorías).
class PanelChoiceChip extends StatelessWidget {
  const PanelChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 36,
    this.fontSize = 14,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: selected ? BorderSide.none : BorderSide(color: scheme.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
