import 'package:flutter/material.dart';

import 'club_config_page.dart';

/// Índices de las tabs de [ClubConfigPage].
abstract final class ClubConfigTab {
  static const info = 0;
  static const partitions = 1;
  static const priceTariffs = 2;
  static const products = 3;
  static const sessionRequests = 4;
  static const onlinePayments = 5;
}

/// A qué parte de la configuración apunta un acceso directo desde otra
/// pantalla (ej. "esta cancha está inactiva", "este turno usa tal tarifa"):
/// la tab a abrir y el ítem a seleccionar/resaltar dentro de ella.
class ClubConfigFocus {
  const ClubConfigFocus._({
    required this.tab,
    this.clubPartitionId,
    this.partitionPhysicalId,
    this.priceTariffId,
    this.priceRuleId,
  });

  /// Un deporte/sector, en "Deportes y canchas".
  const ClubConfigFocus.clubPartition(int clubPartitionId)
      : this._(tab: ClubConfigTab.partitions, clubPartitionId: clubPartitionId);

  /// Una cancha puntual, en "Deportes y canchas".
  const ClubConfigFocus.physicalPartition({
    required int clubPartitionId,
    required int partitionPhysicalId,
  }) : this._(
          tab: ClubConfigTab.partitions,
          clubPartitionId: clubPartitionId,
          partitionPhysicalId: partitionPhysicalId,
        );

  /// Las tarifas de un sector, con [priceTariffId] (y opcionalmente la franja
  /// [priceRuleId]) seleccionada si viene.
  const ClubConfigFocus.priceTariff({
    required int clubPartitionId,
    int? priceTariffId,
    int? priceRuleId,
  }) : this._(
          tab: ClubConfigTab.priceTariffs,
          clubPartitionId: clubPartitionId,
          priceTariffId: priceTariffId,
          priceRuleId: priceRuleId,
        );

  final int tab;
  final int? clubPartitionId;
  final int? partitionPhysicalId;
  final int? priceTariffId;
  final int? priceRuleId;
}

/// Abre la configuración del club como pantalla completa ENCIMA de la actual
/// (no navega con go_router), para que al cerrarla el admin vuelva exactamente
/// a donde estaba — ej. a mitad del wizard de carga de turnos, que pierde todo
/// su estado si se sale de la ruta. El `Future` completa al cerrarla, para
/// que quien la abrió recargue lo que pudo haber cambiado.
Future<void> openClubConfig(BuildContext context, ClubConfigFocus focus) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ClubConfigPage(focus: focus, modal: true),
    ),
  );
}
