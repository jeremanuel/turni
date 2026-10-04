import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'tabs/club_info_tab.dart';
import 'tabs/club_partitions_tab.dart';
import 'tabs/price_tariffs_tab.dart';
import 'tabs/products_tab.dart';
import 'tabs/session_request_settings_tab.dart';

/// Pantalla de configuración de admin para el club (reemplaza la vieja
/// `AdminSettingsPage`, que ahora vive como la tab "Solicitudes de turno").
class ClubConfigPage extends StatelessWidget {
  const ClubConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        // En el mockup solo la franja de arriba (appbar + tabs) usa el tono
        // más oscuro (`surface`); el cuerpo de cada tab usa el tono más
        // suave `surfaceContainer`, igual que `.content-panel`/`.page-body`.
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        appBar: AppBar(
          title: const Text("Configuración"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Información del club"),
              Tab(text: "Deportes y canchas"),
              Tab(text: "Tarifas por horario"),
              Tab(text: "Productos"),
              Tab(text: "Solicitudes de turno"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ClubInfoTab(),
            ClubPartitionsTab(),
            PriceTariffsTab(),
            ProductsTab(),
            SessionRequestSettingsTab(),
          ],
        ),
      ),
    );
  }
}
