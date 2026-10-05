import '../../entities/physical_partition.dart';
import '../../entities/price_rule.dart';
import '../../entities/price_tariff.dart';

/// De dónde sale el precio de un turno en la carga masiva.
enum SessionPriceSource {
  /// El admin lo pisó a mano para ese turno en esa cancha.
  manual,

  /// Una franja horaria activa de la tarifa (activa) de la cancha.
  tariffRule,

  /// Ninguna franja aplica: precio fijo (`default_session_price`) de la cancha.
  partitionDefault,
}

/// Precio resuelto de un turno + qué regla lo determinó (para mostrarle al
/// admin "por qué" ese turno vale eso y poder abrir la configuración ahí).
class ResolvedSessionPrice {
  const ResolvedSessionPrice({
    required this.price,
    required this.source,
    this.tariff,
    this.rule,
  });

  final double price;
  final SessionPriceSource source;

  /// Tarifa activa de la cancha, si tiene (aunque ninguna franja aplique a
  /// ese horario — así se puede ofrecer "agregar una franja" en esa tarifa).
  final PriceTariff? tariff;

  /// Franja que aplica, solo cuando [source] es [SessionPriceSource.tariffRule].
  final PriceRule? rule;
}

/// Resuelve el precio de un turno según las tarifas por horario del club,
/// con la misma semántica que muestra la pantalla de Tarifas: una franja
/// aplica si está activa, su tarifa está activa e incluye la cancha, el día
/// de semana está en la franja y el INICIO del turno cae en
/// `[start_time, end_time)`. Fuera de toda franja se cobra el precio fijo de
/// la cancha. El backend no permite franjas solapadas dentro de una tarifa ni
/// una cancha en dos tarifas, así que a lo sumo una franja aplica.
class SessionPriceResolver {
  SessionPriceResolver(List<PriceTariff> tariffs)
      : _tariffByPartition = {
          for (final tariff in tariffs.where((t) => t.active))
            for (final id in tariff.memberPartitionPhysicalIds) id: tariff,
        };

  final Map<int, PriceTariff> _tariffByPartition;

  PriceTariff? tariffFor(int partitionPhysicalId) =>
      _tariffByPartition[partitionPhysicalId];

  /// [dayOfWeek]: 1 = lunes ... 7 = domingo (ISO-8601, igual que `DateTime.weekday`).
  ResolvedSessionPrice resolve({
    required PhysicalPartition partition,
    required int dayOfWeek,
    required int startMinutes,
    double? manualPrice,
  }) {
    final tariff = tariffFor(partition.partitionPhysicalId);

    if (manualPrice != null) {
      return ResolvedSessionPrice(
        price: manualPrice,
        source: SessionPriceSource.manual,
        tariff: tariff,
      );
    }

    final rule = tariff?.rules.where((rule) => _applies(rule, dayOfWeek, startMinutes)).firstOrNull;
    if (rule != null) {
      return ResolvedSessionPrice(
        price: rule.price,
        source: SessionPriceSource.tariffRule,
        tariff: tariff,
        rule: rule,
      );
    }

    return ResolvedSessionPrice(
      price: partition.defaultSessionPrice ?? 0,
      source: SessionPriceSource.partitionDefault,
      tariff: tariff,
    );
  }

  /// Precio para cada día de la semana (1..7) — lo que se manda al backend
  /// como `price_by_day_of_week`, ya que la plantilla se repite en días distintos.
  Map<int, double> pricesByDayOfWeek({
    required PhysicalPartition partition,
    required int startMinutes,
    double? manualPrice,
  }) {
    return {
      for (var day = 1; day <= 7; day++)
        day: resolve(
          partition: partition,
          dayOfWeek: day,
          startMinutes: startMinutes,
          manualPrice: manualPrice,
        ).price,
    };
  }

  static bool _applies(PriceRule rule, int dayOfWeek, int startMinutes) {
    if (!rule.active || !rule.daysOfWeek.contains(dayOfWeek)) return false;
    final start = parseMinutes(rule.startTime);
    final end = parseMinutes(rule.endTime);
    if (start == null || end == null) return false;
    return startMinutes >= start && startMinutes < end;
  }

  /// "HH:mm" (o "HH:mm:ss") -> minutos desde las 00:00.
  static int? parseMinutes(String time) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(time.trim());
    if (match == null) return null;
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }
}
