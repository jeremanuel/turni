import 'package:flutter/material.dart';

import '../../../core/presentation/components/permission_lock.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/utils/responsive_builder.dart';
import 'package:go_router/go_router.dart';

import 'club_config_focus.dart';
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
class ClubConfigPage extends StatelessWidget {
  const ClubConfigPage({super.key, this.focus, this.modal = false});

  /// Tab + ítem a abrir/resaltar al entrar (ver [openClubConfig]).
  final ClubConfigFocus? focus;

  /// true cuando se abrió con [openClubConfig] encima de otra pantalla: el
  /// "atrás" cierra esa ruta en vez de navegar con go_router.
  final bool modal;

  @override
  Widget build(BuildContext context) {
    final sections = _sections(focus);

    if (ResponsiveBuilder.isMobile(context)) {
      // Abierto apuntando a un ítem (ej. "configurar tarifa" desde la
      // agenda): directo a esa sección.
      if (focus != null) {
        final section = sections[focus!.tab];
        return _ClubConfigSectionPage(section: section, modal: modal);
      }
      return _ClubConfigMobileList(sections: sections);
    }

    final focusTab = focus?.tab;

    return DefaultTabController(
      length: sections.length,
      initialIndex: focusTab ?? ClubConfigTab.info,
      child: Scaffold(
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
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final section in sections) Tab(text: section.tabLabel)],
          ),
        ),
        body: TabBarView(
          children: [for (final section in sections) section.builder()],
        ),
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
  });

  final String tabLabel;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;
}

/// En el orden de [ClubConfigTab].
List<_ClubConfigSection> _sections(ClubConfigFocus? focus) => [
      _ClubConfigSection(
        tabLabel: 'Información del establecimiento',
        title: 'Club',
        subtitle: 'Nombre, dirección y ubicación',
        icon: Icons.storefront_outlined,
        builder: () => const ClubInfoTab(),
      ),
      _ClubConfigSection(
        tabLabel: 'Servicios y espacios',
        title: 'Servicios y espacios',
        subtitle: 'Servicios del club y sus canchas o salas',
        icon: Icons.grid_view_outlined,
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
        // Vincular la cuenta de Mercado Pago del club (antes estaba en la
        // vieja AdminSettingsPage, debajo de las solicitudes de turno).
        builder: () => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
        ),
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
        title: Text(section.title),
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
