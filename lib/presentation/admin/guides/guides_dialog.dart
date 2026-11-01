import 'package:flutter/material.dart';

import '../../../core/presentation/components/onboarding/tour_anchor.dart';
import 'admin_guides.dart';
import 'guide.dart';

/// Signo de pregunta del menú: abre el centro de ayuda ([showGuidesDialog]).
/// Va en el menú lateral (escritorio) y en la barra superior (celular).
class GuidesButton extends StatelessWidget {
  const GuidesButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TourAnchor(
      id: 'nav.help',
      child: IconButton(
        tooltip: 'Guías y ayuda',
        onPressed: () => showGuidesDialog(context),
        icon: const Icon(Icons.help_outline),
      ),
    );
  }
}

/// Centro de ayuda: buscador de guías. Al elegir una, cierra el diálogo y la
/// recorre. Diálogo en escritorio, pantalla completa en el celular.
Future<void> showGuidesDialog(BuildContext context, {List<Guide>? guides}) async {
  final available = (guides ?? AdminGuides.all).where((g) => g.isVisible).toList();
  final seen = <String>{
    for (final g in available)
      if (await g.hasSeen()) g.id,
  };
  if (!context.mounted) return;

  final compact = MediaQuery.sizeOf(context).width < 600;
  final picked = await showDialog<Guide>(
    context: context,
    builder: (dialogContext) {
      final panel = GuidesPanel(guides: available, seen: seen, onPick: (g) => Navigator.of(dialogContext).pop(g));
      if (compact) return Dialog.fullscreen(child: panel);
      return Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 24),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(width: 600, height: 640, child: panel),
      );
    },
  );
  if (picked != null) await picked.run();
}

/// Contenido del centro de ayuda (separado del diálogo para los tests).
class GuidesPanel extends StatefulWidget {
  const GuidesPanel({super.key, required this.guides, required this.onPick, this.seen = const {}});

  final List<Guide> guides;
  final ValueChanged<Guide> onPick;

  /// Ids de las guías que el admin ya recorrió.
  final Set<String> seen;

  @override
  State<GuidesPanel> createState() => _GuidesPanelState();
}

class _GuidesPanelState extends State<GuidesPanel> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final query = _search.text;
    final shown = widget.guides.where((g) => g.matches(query)).toList();

    // Sin búsqueda, agrupadas por sección en el orden del catálogo.
    final sections = <String, List<Guide>>{};
    for (final g in shown) {
      (sections[g.section] ??= []).add(g);
    }

    return Material(
      color: scheme.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
            child: Row(
              children: [
                Expanded(child: Text('Guías', style: text.titleLarge)),
                IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'Elegí una y te mostramos paso a paso cómo se usa esa parte del panel.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (shown.length == 1) widget.onPick(shown.first);
              },
              decoration: InputDecoration(
                hintText: 'Buscar una guía (ej. cobrar, torneo, tarifas)',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Borrar búsqueda',
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No encontramos guías con "$query".',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      for (final entry in sections.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                          child: Text(entry.key, style: text.labelLarge?.copyWith(color: scheme.primary)),
                        ),
                        for (final guide in entry.value)
                          _GuideRow(guide: guide, seen: widget.seen.contains(guide.id), onTap: () => widget.onPick(guide)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.guide, required this.seen, required this.onTap});

  final Guide guide;
  final bool seen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
        child: Icon(guide.icon, color: scheme.primary, size: 22),
      ),
      title: Text(guide.title),
      subtitle: Text(guide.description),
      trailing: seen
          ? Tooltip(message: 'Ya la viste', child: Icon(Icons.check_circle_outline, color: scheme.outline, size: 20))
          : const Icon(Icons.play_circle_outline),
      onTap: onTap,
    );
  }
}
