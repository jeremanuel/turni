import 'package:flutter/material.dart';

import '../../../core/presentation/components/permission_lock.dart';
import '../../../core/utils/permissions.dart';
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
class ClubConfigPage extends StatelessWidget {
  const ClubConfigPage({super.key, this.focus, this.modal = false});

  /// Tab + ítem a abrir/resaltar al entrar (ver [openClubConfig]).
  final ClubConfigFocus? focus;

  /// true cuando se abrió con [openClubConfig] encima de otra pantalla: el
  /// "atrás" cierra esa ruta en vez de navegar con go_router.
  final bool modal;

  @override
  Widget build(BuildContext context) {
    final focus = this.focus;

    return DefaultTabController(
      length: 6,
      initialIndex: focus?.tab ?? ClubConfigTab.info,
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
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Información del club"),
              Tab(text: "Deportes y canchas"),
              Tab(text: "Tarifas por horario"),
              Tab(text: "Productos"),
              Tab(text: "Solicitudes de turno"),
              Tab(text: "Cobros online"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const ClubInfoTab(),
            ClubPartitionsTab(
              focusClubPartitionId: focus?.tab == ClubConfigTab.partitions
                  ? focus?.clubPartitionId
                  : null,
              focusPartitionPhysicalId: focus?.partitionPhysicalId,
            ),
            PriceTariffsTab(
              focusClubPartitionId: focus?.tab == ClubConfigTab.priceTariffs
                  ? focus?.clubPartitionId
                  : null,
              focusPriceTariffId: focus?.priceTariffId,
              focusPriceRuleId: focus?.priceRuleId,
            ),
            const ProductsTab(),
            const SessionRequestSettingsTab(),
            // Vincular la cuenta de Mercado Pago del club (antes estaba en
            // la vieja AdminSettingsPage, debajo de las solicitudes de turno).
            SingleChildScrollView(
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
          ],
        ),
      ),
    );
  }
}
