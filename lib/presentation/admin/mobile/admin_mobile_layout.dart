import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router/app_routes.dart';
import '../notifications/notifications_panel.dart';
import 'admin_bottom_nav.dart';
import 'admin_mobile_sub_page.dart';

/// Layout del admin en el celular (diseño "Admin mobile — layout y
/// navegación"). Tres niveles de pantalla:
///
/// - **Destino** (Turnos, Clientes, Pagos, Torneos y lo que está en «Más»):
///   barra superior con el título y barra de navegación inferior.
/// - **Detalle / formulario** (un turno, un torneo, un alta...): barra
///   superior con flecha atrás y sin barra inferior.
/// - Las rutas que dibujan su propio `Scaffold` (`usesScaffold: false`, ej.
///   la ficha del cliente) se muestran tal cual.
class AdminMobileLayout extends StatelessWidget {
  const AdminMobileLayout({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// Destinos de nivel 1 y su título en la barra superior.
  static const _topLevelTitles = {
    'DASHBOARD': 'Inicio',
    'SESSION_MANAGER': 'Turnos',
    'CLIENTS_LIST': 'Clientes',
    'PAYMENTS': 'Pagos',
    'CLUB_MAP': 'Mapa',
    'TOURNAMENTS': 'Torneos',
    'ADMIN_SETTINGS': 'Configuración',
    'USERS': 'Usuarios',
  };

  /// Pantallas que ya dibujan su propio `AppBar` (con título, tabs y
  /// acciones): el layout no agrega otro encima.
  static const _pagesWithOwnAppBar = {
    'TOURNAMENTS',
    'TOURNAMENT_NEW',
    'TOURNAMENT_DETAIL',
    'TOURNAMENT_EDIT',
    'TOURNAMENT_SCHEDULE',
    'USERS',
    'ADMIN_SETTINGS',
    // Gestión masiva tiene su propio encabezado con flecha atrás.
    'BULK_SESSIONS',
    'ADD_SESSIONS_MASSIVE',
  };

  @override
  Widget build(BuildContext context) {
    final state = GoRouter.of(context).state;
    final routeName = state.topRoute?.name ?? state.name;
    final definition = AppRoutes.routesMap[routeName];

    if (definition != null && !definition.usesScaffold) return shell;

    final scheme = Theme.of(context).colorScheme;
    final topTitle = _topLevelTitles[routeName];
    final isTopLevel = topTitle != null;
    final pageHasAppBar = _pagesWithOwnAppBar.contains(routeName);

    return ValueListenableBuilder<AdminMobileSubPage?>(
      valueListenable: AdminMobileSubPage.current,
      builder: (context, registered, _) {
        final subPage = registered?.location == state.uri.path ? registered : null;
        return PopScope(
        // Atrás (del sistema o de la barra) cierra primero la sub-pantalla.
        canPop: subPage == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) subPage?.onBack();
        },
        child: Scaffold(
          backgroundColor: scheme.surfaceContainer,
          appBar: pageHasAppBar ? null : AppBar(
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            titleSpacing: isTopLevel && subPage == null ? 16 : 0,
            leading: isTopLevel && subPage == null
                ? null
                : IconButton(
                    tooltip: subPage?.backTooltip ?? 'Volver',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: subPage?.onBack ?? () => goBack(context, definition),
                  ),
            title: Text(subPage?.title ?? topTitle ?? definition?.mobileAppBar?.title ?? ''),
            actions: isTopLevel && subPage == null
                ? const [NotificationsButton(), SizedBox(width: 8)]
                : null,
            shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          body: shell,
          bottomNavigationBar: isTopLevel && subPage == null ? AdminBottomNav(shell: shell) : null,
        ),
      );
      },
    );
  }

  /// Vuelve a la pantalla anterior: la del historial si la hay; si no (se
  /// llegó con `go` o por un link), a la de [RouteDefinition.mobileAppBar]
  /// o a la ruta padre.
  static void goBack(BuildContext context, RouteDefinition? definition) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final backTo = definition?.mobileAppBar?.backToPath;
    if (backTo != null) {
      router.go(backTo);
      return;
    }
    final segments = router.state.uri.pathSegments;
    router.go(segments.length <= 1 ? '/' : '/${segments.sublist(0, segments.length - 1).join('/')}');
  }
}
