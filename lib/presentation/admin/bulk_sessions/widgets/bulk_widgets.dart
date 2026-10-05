import 'package:flutter/material.dart';

import '../../../../core/presentation/components/dashed_rrect_painter.dart';

/// Piezas visuales de "Gestión masiva de turnos", 1:1 con el diseño aprobado
/// (https://claude.ai/artifact/YPicno37RysQQ3Ht63Xpfm). Todos los colores
/// salen del `ColorScheme` (mismo seed que el Turni Design System), nunca hex.

/// Chip de selección del diseño: 36px de alto, radio 8. Sin seleccionar:
/// borde `outline` y texto `onSurfaceVariant`; seleccionado: relleno
/// `secondaryContainer` sin borde, texto w500. Deshabilitado (sector/cancha
/// inactivo): borde punteado `outlineVariant` y texto tachado.
class BulkChoiceChip extends StatelessWidget {
  const BulkChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = selected && enabled;

    final text = Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: on ? FontWeight.w500 : FontWeight.w400,
        color: !enabled
            ? scheme.outline
            : on
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
        decoration: enabled ? null : TextDecoration.lineThrough,
        decorationColor: scheme.outline,
      ),
    );

    // Ancho = contenido (nunca `alignment` en el Container: lo estira a todo
    // el ancho disponible dentro de un Wrap).
    final chip = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: on ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: on || !enabled ? null : Border.all(color: scheme.outline),
      ),
      child: Center(widthFactor: 1, child: text),
    );

    if (!enabled) {
      return CustomPaint(
        painter: DashedRRectPainter(color: scheme.outlineVariant, radius: 8),
        child: chip,
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: chip,
        ),
      ),
    );
  }
}

/// Círculo de día de la semana, 44px. Seleccionado: relleno `primary`.
class BulkDayPill extends StatelessWidget {
  const BulkDayPill({
    super.key,
    required this.letter,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? scheme.primary : Colors.transparent,
              border: Border.all(color: selected ? scheme.primary : scheme.outline),
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Encabezado de sección dentro de una card: título 14 w500.
class BulkFieldLabel extends StatelessWidget {
  const BulkFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500));
  }
}

/// Título de card numerado ("1. ¿Qué turnos?") + bajada.
class BulkCardHeader extends StatelessWidget {
  const BulkCardHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12, height: 16 / 12, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Decoración de los inputs del diseño: label afuera (arriba, 12px), campo de
/// 44px con borde `outline` de 1px, radio 4, foco `primary` 2px.
InputDecoration bulkInputDecoration(BuildContext context, {String? suffixText, String? prefixText}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    constraints: const BoxConstraints(minHeight: 44),
    border: border(scheme.outline, 1),
    enabledBorder: border(scheme.outline, 1),
    focusedBorder: border(scheme.primary, 2),
    errorBorder: border(scheme.error, 1),
    focusedErrorBorder: border(scheme.error, 2),
    suffixText: suffixText,
    prefixText: prefixText,
  );
}

/// Label de 12px `onSurfaceVariant` arriba del campo, gap 4.
class BulkLabeledField extends StatelessWidget {
  const BulkLabeledField({super.key, required this.label, required this.child, this.width});

  final String label;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        // Los TextField toman su texto de `bodyLarge` (16px): el diseño usa 14.
        Theme(
          data: theme.copyWith(
            textTheme: theme.textTheme.copyWith(
              bodyLarge: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
            ),
          ),
          child: DefaultTextStyle.merge(style: const TextStyle(fontSize: 14), child: child),
        ),
      ],
    );
    return width == null ? content : SizedBox(width: width, child: content);
  }
}

/// Caja informativa con ícono (radio 8, padding 12, texto 12/16).
class BulkInfoBox extends StatelessWidget {
  const BulkInfoBox({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.child,
    this.iconColor,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: iconColor ?? foreground),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(fontSize: 12, height: 16 / 12, color: foreground),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Píldora de resumen de la vista previa (32px, radio 8): "96 coinciden".
class BulkSummaryChip extends StatelessWidget {
  const BulkSummaryChip({
    super.key,
    required this.count,
    required this.label,
    this.background,
    this.foreground,
    this.outlined = false,
  });

  final int count;
  final String label;
  final Color? background;
  final Color? foreground;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: outlined ? Border.all(color: scheme.outline) : null,
      ),
      child: Center(
        widthFactor: 1,
        child: Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 14, color: foreground ?? scheme.onSurface),
            children: [
              TextSpan(text: '$count', style: const TextStyle(fontWeight: FontWeight.w500)),
              TextSpan(text: ' $label'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge de la columna "Resultado" (28px, radio 8, 12px).
class BulkStatusBadge extends StatelessWidget {
  const BulkStatusBadge({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    this.bold = false,
  });

  final String text;
  final Color background;
  final Color foreground;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          height: 16 / 12,
          color: foreground,
          fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }
}

/// Texto de los botones del diseño (14, w500) SOBRE el `labelLarge` del tema:
/// un `TextStyle` suelto en `styleFrom(textStyle:)` reemplaza el del tema y
/// los botones pierden Roboto.
TextStyle bulkButtonTextStyle(BuildContext context) =>
    Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w500);
