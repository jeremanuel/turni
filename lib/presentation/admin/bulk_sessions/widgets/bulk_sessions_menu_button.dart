import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/app_routes.dart';
import '../bulk_sessions_page.dart';
import 'bulk_widgets.dart';

/// "Gestión masiva ▾" del gestor de turnos: abre Gestión masiva en la tab
/// "Agregar turnos" (el agregador de siempre) o "Editar o eliminar".
/// `MenuAnchor` se posiciona solo pegado al botón (nunca una posición fija).
class BulkSessionsMenuButton extends StatelessWidget {
  const BulkSessionsMenuButton({super.key});

  void _go(BuildContext context, BulkSessionsTab tab) {
    context.go('${AppRoutes.BULK_SESSIONS_ROUTE.path}?tab=${tab.query}');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget item(BulkSessionsTab tab, IconData icon, String title, String subtitle) => MenuItemButton(
          onPressed: () => _go(context, tab),
          style: MenuItemButton.styleFrom(
            minimumSize: const Size(300, 56),
            maximumSize: const Size(300, double.infinity),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          leadingIcon: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: scheme.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
          ),
        );

    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
      ),
      menuChildren: [
        item(BulkSessionsTab.add, Icons.add, 'Agregar turnos', 'Plantilla repetida en varias canchas y días'),
        item(BulkSessionsTab.edit, Icons.edit_outlined, 'Editar o eliminar turnos',
            'Precio, duración u horario por reglas'),
      ],
      builder: (context, controller, _) => FilledButton(
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: bulkButtonTextStyle(context),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view, size: 18),
            SizedBox(width: 8),
            Text('Gestión masiva'),
            SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }
}
