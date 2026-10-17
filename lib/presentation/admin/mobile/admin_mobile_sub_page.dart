import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Una sub-pantalla que no es una ruta propia (ej. "Cobrar" dentro del
/// detalle del turno). Mientras está abierta, la barra superior del celular
/// muestra su título y la flecha atrás vuelve a la pantalla anterior dentro
/// de la misma ruta, en vez de que la sub-pantalla dibuje un segundo
/// encabezado con otra flecha.
class AdminMobileSubPage {
  const AdminMobileSubPage({required this.title, required this.onBack, this.backTooltip, this.location = ''});

  final String title;

  /// Ruta en la que se abrió. Las ramas de la barra inferior siguen vivas en
  /// segundo plano: al pasar a otra (ej. Clientes) la sub-pantalla no se
  /// desmonta, así que el layout solo la usa mientras se está en esta ruta.
  final String location;
  final VoidCallback onBack;
  final String? backTooltip;

  /// La sub-pantalla abierta; la escucha [AdminMobileLayout].
  static final current = ValueNotifier<AdminMobileSubPage?>(null);
}

/// Registra [subPage] como la sub-pantalla abierta mientras este widget esté
/// montado.
class AdminMobileSubPageScope extends StatefulWidget {
  const AdminMobileSubPageScope({super.key, required this.subPage, required this.child});

  final AdminMobileSubPage subPage;
  final Widget child;

  @override
  State<AdminMobileSubPageScope> createState() => _AdminMobileSubPageScopeState();
}

class _AdminMobileSubPageScopeState extends State<AdminMobileSubPageScope> {
  @override
  void initState() {
    super.initState();
    _publish();
  }

  @override
  void didUpdateWidget(covariant AdminMobileSubPageScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _publish();
  }

  // Después del frame: el layout no puede reconstruirse en medio de otro build.
  void _publish() {
    final s = widget.subPage;
    final subPage = AdminMobileSubPage(
      title: s.title,
      onBack: s.onBack,
      backTooltip: s.backTooltip,
      location: GoRouterState.of(context).uri.path,
    );
    _published = subPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AdminMobileSubPage.current.value = subPage;
    });
  }

  AdminMobileSubPage? _published;

  @override
  void dispose() {
    final mine = _published;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (identical(AdminMobileSubPage.current.value, mine)) AdminMobileSubPage.current.value = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
