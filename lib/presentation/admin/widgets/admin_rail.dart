import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/services/app_version/app_version.dart';
import '../../../core/presentation/components/onboarding/tour_anchor.dart';
import '../../../infrastructure/localstorage/provider/local_storage.dart';
import '../../core/cubit/auth/auth_cubit.dart';
import '../guides/guides_dialog.dart';
import '../notifications/notification_widgets.dart';
import '../notifications/notifications_panel.dart';
import 'admin_destinations.dart';

/// Iniciales del admin logueado (avatar del menú lateral y del menú «Más»).
String adminInitials() {
  final person = sl<AuthCubit>().state.userCredential?.admin?.person;
  if (person == null) return '';
  String first(String s) => s.trim().isEmpty ? '' : s.trim().substring(0, 1).toUpperCase();
  return '${first(person.name)}${first(person.lastName)}';
}

String _adminName() {
  final person = sl<AuthCubit>().state.userCredential?.admin?.person;
  if (person == null) return '';
  return '${person.name} ${person.lastName}'.trim();
}

/// Medidas del menú lateral (diseño "Menú lateral sin overflow", opción C + A).
class RailMetrics {
  RailMetrics._();

  static const collapsedWidth = 72.0;
  static const expandedWidth = 256.0;
  static const padding = 12.0;
  static const rowHeight = 44.0;
  static const rowGap = 2.0;

  /// Separador entre grupos (cerrado) y título del grupo (abierto).
  static const dividerHeight = 13.0;
  static const groupTitleHeight = 30.0;

  /// Encabezado: logo arriba del botón de abrir (cerrado) o en la misma fila (abierto).
  static const collapsedHeader = 84.0;
  static const expandedHeader = 40.0;

  /// Duración de abrir/cerrar.
  static const duration = Duration(milliseconds: 280);
}

/// Grupos del menú, en orden. Los vacíos (sin permisos) no se muestran.
const adminRailGroups = <(String, List<AdminDestination>)>[
  ('Operación', [AdminDestinations.inicio, AdminDestinations.turnos, AdminDestinations.clientes, AdminDestinations.pagos]),
  ('Club', [AdminDestinations.mapa, AdminDestinations.torneos]),
  ('Administración', [AdminDestinations.configuracion, AdminDestinations.usuarios]),
];

/// Alto de una lista cerrada: filas, separadores entre grupos y, si va, «Más».
double collapsedListHeight(List<(String, List<AdminDestination>)> groups, {bool withMore = false}) {
  final filled = groups.where((g) => g.$2.isNotEmpty).toList();
  final rows = filled.fold<int>(withMore ? 1 : 0, (sum, g) => sum + g.$2.length);
  final dividers = math.max(0, filled.length - 1);
  return rows * RailMetrics.rowHeight + math.max(0, rows - 1) * RailMetrics.rowGap + dividers * RailMetrics.dividerHeight;
}

/// Qué destinos entran en el menú cerrado y cuáles van a «Más» (vacía si
/// entra todo). [active] siempre queda a la vista: si no entraba, toma el
/// último lugar antes de «Más».
({List<(String, List<AdminDestination>)> shown, List<AdminDestination> hidden}) splitForHeight(
  List<(String, List<AdminDestination>)> groups,
  double available, {
  AdminDestination? active,
}) {
  if (collapsedListHeight(groups) <= available) return (shown: groups, hidden: const []);

  final flat = [for (final (_, items) in groups) ...items];
  List<(String, List<AdminDestination>)> take(int n) {
    final keep = flat.take(n).toList();
    if (active != null && flat.contains(active) && !keep.contains(active) && keep.isNotEmpty) {
      keep[keep.length - 1] = active;
    }
    return [
      for (final (title, items) in groups) (title, items.where(keep.contains).toList()),
    ].where((g) => g.$2.isNotEmpty).toList();
  }

  var count = flat.length - 1;
  while (count > 1 && collapsedListHeight(take(count), withMore: true) > available) {
    count--;
  }
  final shown = take(count);
  final visible = {for (final (_, items) in shown) ...items};
  return (shown: shown, hidden: flat.where((d) => !visible.contains(d)).toList());
}

/// Menú lateral del admin. Cerrado: solo íconos, con separadores entre
/// grupos y «Más» si no entran todos. Abierto: grupos con título y nombres;
/// si no entran, la lista scrollea con la barra siempre visible. El pie
/// (guías, campana y cuenta) queda fijo. Se recuerda abierto/cerrado.
///
/// Cada destino apunta a una rama del `StatefulShellRoute` (`buildBranches`)
/// y solo se muestra si el rol tiene alguno de sus permisos.
class AdminRail extends StatefulWidget {
  const AdminRail({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// Clave de LocalStorage con la preferencia (abierto/cerrado).
  static const storageKey = 'admin_rail_expanded';

  @override
  State<AdminRail> createState() => _AdminRailState();
}

class _AdminRailState extends State<AdminRail> with SingleTickerProviderStateMixin {
  late final AnimationController _expand = AnimationController(vsync: this, duration: RailMetrics.duration);
  final _railKey = GlobalKey();
  final _scroll = ScrollController();

  /// Elegido desde «Más»: se queda a la vista en el menú cerrado.
  AdminDestination? _pinned;

  @override
  void initState() {
    super.initState();
    LocalStorage.read(AdminRail.storageKey).then((value) {
      if (mounted && value == 'true') _expand.value = 1;
    });
  }

  @override
  void dispose() {
    _expand.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toggle() {
    final open = _expand.value < 0.5;
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : RailMetrics.duration;
    _expand.animateTo(open ? 1 : 0, duration: duration);
    LocalStorage.save(AdminRail.storageKey, '$open');
  }

  void _go(AdminDestination destination, {bool fromMore = false}) {
    final shell = widget.shell;
    if (fromMore) setState(() => _pinned = destination);
    shell.goBranch(destination.branch, initialLocation: shell.currentIndex == destination.branch);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final groups = [
      for (final (title, items) in adminRailGroups) (title, AdminDestinations.visible(items)),
    ].where((g) => g.$2.isNotEmpty).toList();
    final all = [for (final (_, items) in groups) ...items];
    final active = all.where((d) => d.branch == widget.shell.currentIndex).firstOrNull;

    return AnimatedBuilder(
      animation: _expand,
      builder: (context, _) {
        final t = _expand.value;
        // El ancho con curva suave; los textos aparecen cuando ya hay lugar
        // (al abrir) y se van antes de achicar (al cerrar).
        final e = Curves.easeInOutCubic.transform(t);
        final labels = Curves.easeOut.transform(((t - 0.45) / 0.55).clamp(0.0, 1.0));
        final width = lerpDouble(RailMetrics.collapsedWidth, RailMetrics.expandedWidth, e)!;
        final rowWidth = width - RailMetrics.padding * 2;

        return Container(
          key: _railKey,
          width: width,
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(right: BorderSide(color: scheme.surfaceContainerHigh)),
          ),
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(t: e, labels: labels, width: width, onToggle: _toggle),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  // Cerrado del todo: si no entra, «Más». Abriendo o abierto: lista que scrollea.
                  if (t == 0) {
                    final split = splitForHeight(groups, constraints.maxHeight, active: _pinned ?? active);
                    return _CollapsedList(
                      groups: split.shown,
                      hidden: split.hidden,
                      active: active,
                      rowWidth: rowWidth,
                      railKey: _railKey,
                      onTap: _go,
                    );
                  }
                  return _ExpandedList(
                    groups: groups,
                    active: active,
                    labels: labels,
                    rowWidth: rowWidth,
                    controller: _scroll,
                    showScrollbar: t == 1,
                    onTap: _go,
                  );
                }),
              ),
              const SizedBox(height: 8),
              _Footer(labels: labels, rowWidth: rowWidth, railKey: _railKey),
            ],
          ),
        );
      },
    );
  }
}

/// Logo (y «Turni» al abrir) y el botón de abrir/cerrar. Cerrado, el botón
/// va debajo del logo; abierto, a la derecha. Se mueve con la animación.
class _Header extends StatelessWidget {
  const _Header({required this.t, required this.labels, required this.width, required this.onToggle});

  final double t;
  final double labels;
  final double width;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = lerpDouble(RailMetrics.collapsedHeader, RailMetrics.expandedHeader, t)!;
    final open = t > 0.5;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          left: 20,
          top: lerpDouble(0, 4, t),
          child: SvgPicture.asset(
            'assets/img/isotype_white.svg',
            width: 32,
            height: 32,
            semanticsLabel: 'Turni',
            colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
          ),
        ),
        if (labels > 0)
          Positioned(
            left: 62,
            top: 6,
            child: Opacity(
              opacity: labels,
              child: Transform.translate(
                offset: Offset(-6 * (1 - labels), 0),
                child: Text('Turni', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: scheme.onSurface)),
              ),
            ),
          ),
        Positioned(
          left: lerpDouble((RailMetrics.collapsedWidth - 40) / 2, width - 52, t),
          top: lerpDouble(44, 0, t),
          child: IconButton(
            tooltip: open ? 'Achicar el menú' : 'Agrandar el menú',
            onPressed: onToggle,
            style: IconButton.styleFrom(minimumSize: const Size(40, 40), fixedSize: const Size(40, 40), padding: EdgeInsets.zero),
            icon: Transform.rotate(
              angle: t * math.pi,
              child: Icon(Icons.keyboard_double_arrow_right, size: 22, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Un destino: el ícono siempre en el mismo lugar (no salta al abrir) y el
/// nombre a su derecha. Cerrado, el nombre va en el tooltip.
class _NavRow extends StatelessWidget {
  const _NavRow({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.labels,
    required this.width,
    required this.onTap,
    this.badge = false,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  /// Opacidad del nombre (0 cerrado, 1 abierto).
  final double labels;
  final double width;
  final VoidCallback onTap;

  /// Puntito: la sección actual está adentro de «Más».
  final bool badge;

  /// «Más» con su menú abierto.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(lerpDouble(12, 22, labels)!);
    final background = selected ? scheme.secondaryContainer : (highlighted ? scheme.primaryContainer : Colors.transparent);
    final foreground = selected ? scheme.onSecondaryContainer : (highlighted ? scheme.onPrimaryContainer : scheme.onSurfaceVariant);
    final row = Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            width: width,
            height: RailMetrics.rowHeight,
            child: Stack(children: [
              Positioned(
                left: 13,
                top: 0,
                bottom: 0,
                child: Center(child: Icon(icon, size: 22, color: foreground)),
              ),
              if (badge)
                Positioned(
                  left: 32,
                  top: 9,
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle)),
                ),
              if (labels > 0)
                Positioned(
                  left: 50,
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: labels,
                    child: Transform.translate(
                      offset: Offset(-6 * (1 - labels), 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? scheme.onSecondaryContainer : scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
    if (labels > 0) return row;
    return Tooltip(message: label, preferBelow: false, waitDuration: const Duration(milliseconds: 300), child: row);
  }
}

/// Título del grupo (abierto) o separador (cerrado), con cross-fade.
class _GroupHead extends StatelessWidget {
  const _GroupHead({required this.title, required this.labels, required this.first});

  final String title;
  final double labels;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = lerpDouble(first ? 0 : RailMetrics.dividerHeight, RailMetrics.groupTitleHeight, labels)!;
    if (height == 0) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: Stack(children: [
        if (!first && labels < 1)
          Positioned(
            left: 4,
            right: 4,
            top: (height - 1) / 2,
            child: Opacity(opacity: 1 - labels, child: Container(height: 1, color: scheme.surfaceContainerHigh)),
          ),
        if (labels > 0)
          Positioned(
            left: 12,
            bottom: 4,
            child: Opacity(
              opacity: labels,
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                style: TextStyle(fontSize: 11, height: 16 / 11, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
      ]),
    );
  }
}

List<Widget> _groupRows({
  required List<(String, List<AdminDestination>)> groups,
  required AdminDestination? active,
  required double labels,
  required double rowWidth,
  required void Function(AdminDestination) onTap,
}) {
  final rows = <Widget>[];
  for (final (i, (title, items)) in groups.indexed) {
    rows.add(_GroupHead(title: title, labels: labels, first: i == 0));
    for (final (j, destination) in items.indexed) {
      if (j > 0) rows.add(const SizedBox(height: RailMetrics.rowGap));
      rows.add(TourAnchor(
        id: destination.anchor,
        child: _NavRow(
          icon: destination.icon,
          label: destination.label,
          selected: destination == active,
          labels: labels,
          width: rowWidth,
          onTap: () => onTap(destination),
        ),
      ));
    }
  }
  return rows;
}

/// Abierto (o abriéndose): todos los destinos; si no entran, scrollean con
/// la barra siempre visible.
class _ExpandedList extends StatelessWidget {
  const _ExpandedList({
    required this.groups,
    required this.active,
    required this.labels,
    required this.rowWidth,
    required this.controller,
    required this.showScrollbar,
    required this.onTap,
  });

  final List<(String, List<AdminDestination>)> groups;
  final AdminDestination? active;
  final double labels;
  final double rowWidth;
  final ScrollController controller;
  final bool showScrollbar;
  final void Function(AdminDestination) onTap;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: showScrollbar,
        child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: RailMetrics.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _groupRows(groups: groups, active: active, labels: labels, rowWidth: rowWidth, onTap: onTap),
          ),
        ),
      ),
    );
  }
}

/// Cerrado: los destinos que entran y «Más» con el resto.
class _CollapsedList extends StatefulWidget {
  const _CollapsedList({
    required this.groups,
    required this.hidden,
    required this.active,
    required this.rowWidth,
    required this.railKey,
    required this.onTap,
  });

  final List<(String, List<AdminDestination>)> groups;
  final List<AdminDestination> hidden;
  final AdminDestination? active;
  final double rowWidth;
  final GlobalKey railKey;
  final void Function(AdminDestination, {bool fromMore}) onTap;

  @override
  State<_CollapsedList> createState() => _CollapsedListState();
}

class _CollapsedListState extends State<_CollapsedList> {
  final _more = OverlayPortalController();
  final _moreKey = GlobalKey();

  void _toggleMore() {
    _more.isShowing ? _more.hide() : _more.show();
    setState(() {});
  }

  void _closeMore() {
    _more.hide();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hidden = widget.hidden;
    Widget more = _NavRow(
      key: _moreKey,
      icon: Icons.more_horiz,
      label: 'Más',
      selected: false,
      highlighted: _more.isShowing,
      badge: widget.active != null && hidden.contains(widget.active),
      labels: 0,
      width: widget.rowWidth,
      onTap: _toggleMore,
    );
    // Las guías que apuntan a un destino escondido muestran «Más».
    for (final destination in hidden) {
      more = TourAnchor(id: destination.anchor, child: more);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RailMetrics.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._groupRows(groups: widget.groups, active: widget.active, labels: 0, rowWidth: widget.rowWidth, onTap: widget.onTap),
          if (hidden.isNotEmpty) ...[
            const SizedBox(height: RailMetrics.rowGap),
            OverlayPortal(
              controller: _more,
              overlayChildBuilder: (context) => _MorePopover(
                anchorKey: _moreKey,
                railKey: widget.railKey,
                items: hidden,
                active: widget.active,
                onPick: (destination) {
                  _closeMore();
                  widget.onTap(destination, fromMore: true);
                },
                onClose: _closeMore,
              ),
              child: more,
            ),
          ],
        ],
      ),
    );
  }
}

/// El menú «Más»: sale del botón, a la derecha del menú lateral, con la
/// flechita apuntándolo (como la bandeja de avisos). Crece hacia arriba.
class _MorePopover extends StatelessWidget {
  const _MorePopover({
    required this.anchorKey,
    required this.railKey,
    required this.items,
    required this.active,
    required this.onPick,
    required this.onClose,
  });

  final GlobalKey anchorKey;
  final GlobalKey railKey;
  final List<AdminDestination> items;
  final AdminDestination? active;
  final void Function(AdminDestination) onPick;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final anchor = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final rail = railKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlay == null || anchor == null || rail == null || !anchor.attached || !rail.attached) return const SizedBox.shrink();
    final center = anchor.localToGlobal(anchor.size.center(Offset.zero), ancestor: overlay);
    final left = rail.localToGlobal(Offset(rail.size.width, 0), ancestor: overlay).dx + 12;
    final bottom = overlay.size.height - (center.dy + 36);

    final popover = Container(
      width: 248,
      decoration: notificationSurface(scheme, caretSide: CaretSide.left),
      padding: const EdgeInsets.all(8),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Text(
                'MÁS SECCIONES',
                style: TextStyle(fontSize: 11, height: 16 / 11, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: scheme.onSurfaceVariant),
              ),
            ),
            for (final destination in items)
              _MoreRow(destination: destination, selected: destination == active, onTap: () => onPick(destination)),
            // Llega hasta el centro de «Más» para que la flechita lo apunte.
            const SizedBox(height: 6),
          ],
        ),
      ),
    );

    return Positioned.fill(
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
        child: Focus(
          autofocus: true,
          child: Stack(children: [
            Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onClose)),
            Positioned(
              left: left,
              bottom: bottom,
              child: MediaQuery.disableAnimationsOf(context)
                  ? popover
                  : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: popover,
                      builder: (context, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(-8 * (1 - v), 0),
                          child: Transform.scale(scale: 0.97 + 0.03 * v, alignment: Alignment.bottomLeft, child: child),
                        ),
                      ),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.destination, required this.selected, required this.onTap});

  final AdminDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Row(children: [
              const SizedBox(width: 12),
              Icon(destination.icon, size: 20, color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? scheme.onSecondaryContainer : scheme.onSurface),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Pie fijo: guías, campana y la cuenta (con el nombre al abrir).
class _Footer extends StatelessWidget {
  const _Footer({required this.labels, required this.rowWidth, required this.railKey});

  final double labels;
  final double rowWidth;
  final GlobalKey railKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RailMetrics.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GuidesButton(),
          const SizedBox(height: 4),
          NotificationsButton(edgeKey: railKey),
          const SizedBox(height: 12),
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            position: PopupMenuPosition.over,
            offset: Offset(rowWidth + 12, -8),
            onSelected: (value) {
              if (value == 'logout') sl<AuthCubit>().signOutGoogle();
              if (value == 'platform_clubs') context.push(AppRoutes.PLATFORM_CLUBS_ROUTE.path);
            },
            itemBuilder: (_) => [
              if (sl<AuthCubit>().isPlatformOperator())
                const PopupMenuItem(
                  value: 'platform_clubs',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.add_business_outlined),
                    title: Text('Alta de establecimiento'),
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                ),
              ),
              PopupMenuItem(
                enabled: false,
                height: 32,
                child: Text('Versión ${AppVersion.label}', style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
            child: SizedBox(
              width: rowWidth,
              height: 44,
              child: Stack(children: [
                Positioned(
                  left: 2,
                  top: 0,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primaryContainer,
                      border: Border.all(color: scheme.outlineVariant, width: 2),
                    ),
                    child: Text(
                      adminInitials(),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
                    ),
                  ),
                ),
                if (labels > 0)
                  Positioned(
                    left: 58,
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: labels,
                      child: Transform.translate(
                        offset: Offset(-6 * (1 - labels), 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _adminName(),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface),
                              ),
                              Text('Mi cuenta', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
