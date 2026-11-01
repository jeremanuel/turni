import 'package:flutter/material.dart';

/// Opción elegible del Design System (medio de pago, cuota, motivo...):
/// transparente con borde `outline` cuando no está elegida y
/// `secondaryContainer` cuando sí. Radio 8. No usar los chips de Material
/// para esto: según dónde estén pintan un fondo oscuro que el diseño no tiene.
class OptionChip extends StatelessWidget {
  const OptionChip({
    super.key,
    required this.selected,
    required this.onTap,
    required this.label,
    this.subtitle,
  });

  final bool selected;
  final VoidCallback? onTap;
  final String label;

  /// Segunda línea más chica ("Vence el 10 nov"): la opción se hace más alta.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    final hasSubtitle = subtitle != null;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? scheme.secondaryContainer : scheme.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: hasSubtitle ? 0 : 40),
            padding: hasSubtitle ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10) : const EdgeInsets.symmetric(horizontal: 16),
            alignment: hasSubtitle ? null : Alignment.center,
            child: hasSubtitle
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: foreground)),
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(fontSize: 12, color: foreground)),
                  ])
                : Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: foreground)),
          ),
        ),
      ),
    );
  }
}
