import 'package:flutter/material.dart';

import '../../../core/presentation/components/permission_lock.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/utils/responsive_builder.dart';
import 'package:go_router/go_router.dart';

import 'club_config_focus.dart';
import 'club_config_tour.dart';
import '../../../domain/entities/club_info.dart';
import 'tabs/club_info_tab.dart';
import 'tabs/club_partitions_tab.dart';
import 'tabs/price_tariffs_tab.dart';
import 'tabs/products_tab.dart';
import 'tabs/session_request_settings_tab.dart';
import '../settings_screen/widgets/mercado_pago_account_card.dart';

/// Pantalla de configuración de admin para el club (reemplaza la vieja
/// `AdminSettingsPage`, que ahora vive como la tab "Solicitudes de turno").
///
/// En el celular las tabs pasan a ser una lista de secciones y cada una se
/// abre en su propia pantalla (diseño "Admin mobile").
class ClubConfigPage extends StatefulWidget {
  const ClubConfigPage({super.key, this.focus, this.modal = false});

  /// Tab + ítem a abrir/resaltar al entrar (ver [openClubConfig]).
  final ClubConfigFocus? focus;

  /// true cuando se abrió con [openClubConfig] encima de otra pantalla: el
  /// "atrás" cierra esa ruta en vez de navegar con go_router.
  final bool modal;

  @override
  State<ClubConfigPage> createState() => _ClubConfigPageState();
}

class _ClubConfigPageState extends State<ClubConfigPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: ClubConfigTab.count,
    initialIndex: widget.focus?.tab ?? ClubConfigTab.info,
    vsync: this,
  );
  final _tourKeys = ClubConfigTourKeys();

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Antes del primer paso del recorrido: la tab de información a la vista.
  Future<void> _showInfoTab() async {
    if (!mounted || _tabController.index == ClubConfigTab.info) return;
    _tabController.animateTo(ClubConfigTab.info);
    await Future<void>.delayed(kTabScrollDuration + const Duration(milliseconds: 50));
  }

  void _showTour(BuildContext context) => ClubConfigTour.show(context, _tourKeys, showInfoTab: _showInfoTab);

  /// Club recién dado de alta (sin dirección o ubicación): la primera vez se
  /// ofrece el recorrido.
  void _onInfoLoaded(BuildContext context, ClubInfo info) {
    if (!ClubConfigTour.isIncomplete(info) || !context.mounted) return;
    ClubConfigTour.showIfNew(context, _tourKeys, showInfoTab: _showInfoTab);
  }

  @override
  Widget build(BuildContext context) {
    final focus = widget.focus;
    final modal = widget.modal;
    final sections = _sections(focus, tourKeys: _tourKeys, onInfoLoaded: _onInfoLoaded, onHelp: _showTour);

    if (ResponsiveBuilder.isMobile(context)) {
      // Abierto apuntando a un ítem (ej. "configurar tarifa" desde la
      // agenda): directo a esa sección.
      if (focus != null) {
        final section = sections[focus.tab];
        return _ClubConfigSectionPage(section: section, modal: modal);
      }
      return _ClubConfigMobileList(sections: sections);
    }

    return Scaffold(
      // En el mockup solo la franja de arriba (appbar + tabs) usa el tono
      // más oscuro (`surface`); el cuerpo de cada tab usa el tono más
      // suave `surfaceContainer`, igual que `.content-panel`/`.page-body`.
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text("Configuración"),
        leading: IconButton(
          icon: Icon(modal ? Icons.close : Icons.arrow_back),
          tooltip: modal ? 'Cerrar' : null,
          onPressed: () => modal ? Navigator.of(context).pop() : context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Ver recorrido',
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showTour(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [for (final section in sections) Tab(key: section.tabKey, text: section.tabLabel)],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [for (final section in sections) section.builder()],
      ),
    );
  }
}

/// Una sección de la configuración: una tab en escritorio, una pantalla en
/// el celular.
class _ClubConfigSection {
  const _ClubConfigSection({
    required this.tabLabel,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
    this.tabKey,
    this.onHelp,
  });

  final String tabLabel;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;

  /// Para que el recorrido resalte la tab.
  final GlobalKey? tabKey;

  /// "Ver recorrido" en la barra de la sección (celular).
  final void Function(BuildContext context)? onHelp;
}

/// En el orden de [ClubConfigTab].
List<_ClubConfigSection> _sections(
  ClubConfigFocus? focus, {
  required ClubConfigTourKeys tourKeys,
  required void Function(BuildContext context, ClubInfo info) onInfoLoaded,
  required void Function(BuildContext context) onHelp,
}) =>
    [
      _ClubConfigSection(
        tabLabel: 'Información del establecimiento',
        title: 'Club',
        subtitle: 'Nombre, dirección y ubicación',
        icon: Icons.storefront_outlined,
        onHelp: onHelp,
        builder: () => Builder(
          builder: (context) => ClubInfoTab(
            tourKeys: tourKeys,
            onLoaded: (info) => onInfoLoaded(context, info),
          ),
        ),
      ),
      _ClubConfigSection(
        tabLabel: 'Servicios y espacios',
        title: 'Servicios y espacios',
        subtitle: 'Servicios del club y sus canchas o salas',
        icon: Icons.grid_view_outlined,
        tabKey: tourKeys.partitionsTab,
        builder: () => ClubPartitionsTab(
          focusClubPartitionId: focus?.tab == ClubConfigTab.partitions ? focus?.clubPartitionId : null,
          focusPartitionPhysicalId: focus?.partitionPhysicalId,
        ),
      ),
      _ClubConfigSection(
        tabLabel: 'Tarifas por horario',
        title: 'Tarifas por horario',
        subtitle: 'Precios según el día y la hora',
        icon: Icons.attach_money,
        tabKey: tourKeys.tariffsTab,
        builder: () => PriceTariffsTab(
          focusClubPartitionId: focus?.tab == ClubConfigTab.priceTariffs ? focus?.clubPartitionId : null,
          focusPriceTariffId: focus?.priceTariffId,
          focusPriceRuleId: focus?.priceRuleId,
        ),
      ),
      _ClubConfigSection(
        tabLabel: 'Productos',
        title: 'Productos',
        subtitle: 'Bebidas, alquileres y extras que se cobran en el turno',
        icon: Icons.shopping_bag_outlined,
        builder: () => const ProductsTab(),
      ),
      _ClubConfigSection(
        tabLabel: 'Solicitudes de turno',
        title: 'Solicitudes de turno',
        subtitle: 'Vencimiento, cancelación y seña',
        icon: Icons.schedule_outlined,
        builder: () => const SessionRequestSettingsTab(),
      ),
      _ClubConfigSection(
        tabLabel: 'Cobros online',
        title: 'Cobros online',
        subtitle: 'Cuenta de Mercado Pago del club',
        icon: Icons.credit_card,
        tabKey: tourKeys.paymentsTab,
        // Vincular la cuenta de Mercado Pago del club (antes estaba en la
        // vieja AdminSettingsPage, debajo de las solicitudes de turno).
        builder: () => Builder(builder: (context) => SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveBuilder.isMobile(context) ? 16 : 24),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ReadOnlyNotice(permissions: [Permissions.CONFIGURACION_COBROS_ONLINE]),
                  PermissionLock(
                    permissions: const [Permissions.CONFIGURACION_COBROS_ONLINE],
                    child: MercadoPagoAccountCard(),
                  ),
                ],
              ),
            ),
          ),
        )),
      ),
    ];

/// Celular: la lista de secciones (destino de nivel 1, sin flecha atrás).
class _ClubConfigMobileList extends StatelessWidget {
  const _ClubConfigMobileList({required this.sections});

  final List<_ClubConfigSection> sections;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Configuración'),
        automaticallyImplyLeading: false,
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, section) in sections.indexed) ...[
                  if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                  ListTile(
                    minVerticalPadding: 14,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                      child: Icon(section.icon, color: scheme.primary, size: 22),
                    ),
                    title: Text(section.title),
                    subtitle: Text(section.subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(builder: (_) => _ClubConfigSectionPage(section: section)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Celular: una sección a pantalla completa (nivel 2).
class _ClubConfigSectionPage extends StatelessWidget {
  const _ClubConfigSectionPage({required this.section, this.modal = false});

  final _ClubConfigSection section;
  final bool modal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      appBar: AppBar(
        // Igual que la barra del resto de las pantallas del celular.
        titleSpacing: 0,
        title: Text(section.title),
        actions: [
          if (section.onHelp != null)
            IconButton(
              tooltip: 'Ver recorrido',
              icon: const Icon(Icons.help_outline),
              onPressed: () => section.onHelp!(context),
            ),
        ],
        leading: IconButton(
          icon: Icon(modal ? Icons.close : Icons.arrow_back),
          tooltip: modal ? 'Cerrar' : 'Volver',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/admin/settings');
            }
          },
        ),
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      body: section.builder(),
    );
  }
}
