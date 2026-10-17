import 'package:flutter/material.dart';

import '../../../core/utils/permissions.dart';
import '../fixed_sessions/fixed_sessions_tab.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router/app_routes.dart';
import '../create_session_screen/create_sessions_screen.dart';
import 'bulk_edit_tab.dart';

/// Tabs de Gestión masiva de turnos.
enum BulkSessionsTab {
  edit('edit'),
  add('add'),
  fixed('fixed');

  const BulkSessionsTab(this.query);

  /// Valor de `?tab=` en la ruta.
  final String query;

  static BulkSessionsTab fromQuery(String? value) =>
      BulkSessionsTab.values.firstWhere((t) => t.query == value, orElse: () => BulkSessionsTab.edit);
}

/// Gestión masiva de turnos: "Editar o eliminar" (por reglas), "Agregar
/// turnos" (el wizard de carga masiva de siempre, reutilizado tal cual) y
/// "Turnos fijos" (clientes con el mismo horario todas las semanas).
class BulkSessionsPage extends StatelessWidget {
  const BulkSessionsPage({super.key, this.initialTab = BulkSessionsTab.edit});

  final BulkSessionsTab initialTab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Tab tab(IconData icon, String label) => Tab(
          height: 48,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
          ),
        );

    // Cada tab según el rol; si la pedida no está, la primera disponible.
    final tabs = [
      if (Permissions.can(Permissions.AGENDA_GESTION_MASIVA)) BulkSessionsTab.edit,
      if (Permissions.can(Permissions.AGENDA_CREAR)) BulkSessionsTab.add,
      if (Permissions.can(Permissions.TURNOS_FIJOS_VER)) BulkSessionsTab.fixed,
    ];
    final initialIndex = tabs.contains(initialTab) ? tabs.indexOf(initialTab) : 0;

    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialIndex,
      child: Scaffold(
        // Cuerpo en surfaceContainer; solo la franja de arriba va en surface.
        backgroundColor: scheme.surfaceContainer,
        body: Column(
          children: [
            Material(
              color: scheme.surface,
              child: Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: scheme.outlineVariant))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: IconButton(
                              tooltip: 'Volver al gestor de turnos',
                              style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              icon: Icon(Icons.arrow_back, size: 22, color: scheme.onSurface),
                              onPressed: () => context.go(AppRoutes.SESSION_MANAGER_ROUTE.path),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Gestión masiva de turnos',
                                  style: TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w400),
                                ),
                                Text(
                                  'Cargar, editar o eliminar muchos turnos a la vez, y los turnos fijos',
                                  style: TextStyle(fontSize: 12, height: 16 / 12, color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(color: scheme.primary, width: 3),
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                        labelColor: scheme.primary,
                        unselectedLabelColor: scheme.onSurfaceVariant,
                        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        tabs: [
                          for (final t in tabs)
                            switch (t) {
                              BulkSessionsTab.edit => tab(Icons.edit_outlined, 'Editar o eliminar'),
                              BulkSessionsTab.add => tab(Icons.add, 'Agregar turnos'),
                              BulkSessionsTab.fixed => tab(Icons.event_repeat, 'Turnos fijos'),
                            },
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Cada tab se mantiene viva al cambiar a la otra: el wizard y las
            // reglas a medio cargar no se pierden por mirar la tab vecina.
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final t in tabs)
                    switch (t) {
                      BulkSessionsTab.edit => const _KeepAlive(child: BulkEditTab()),
                      BulkSessionsTab.add => const _KeepAlive(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CreateSessionScreen(showBackButton: false),
                          ),
                        ),
                      BulkSessionsTab.fixed => const _KeepAlive(child: FixedSessionsTab()),
                    },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
