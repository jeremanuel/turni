import 'package:flutter_test/flutter_test.dart';

import 'package:turni/domain/entities/physical_partition.dart';
import 'package:turni/domain/entities/price_rule.dart';
import 'package:turni/domain/entities/price_tariff.dart';
import 'package:turni/domain/use_case/price/session_price_resolver.dart';

void main() {
  final court = PhysicalPartition(
    partitionPhysicalId: 10,
    clubPartitionId: 1,
    minPlayers: 1,
    maxPlayers: 4,
    physicalIdentifier: 1,
    isCover: '0',
    description: 'Cancha 1',
    defaultSessionPrice: 5000,
  );

  PriceRule rule({
    int id = 1,
    List<int> days = const [1, 2, 3, 4, 5],
    String start = '18:00',
    String end = '23:00',
    double price = 10000,
    bool active = true,
  }) =>
      PriceRule(
        priceRuleId: id,
        priceTariffId: 100,
        daysOfWeek: days,
        startTime: start,
        endTime: end,
        price: price,
        active: active,
      );

  PriceTariff tariff(List<PriceRule> rules, {bool active = true, List<int> members = const [10]}) =>
      PriceTariff(
        priceTariffId: 100,
        clubPartitionId: 1,
        name: 'Noche',
        active: active,
        memberPartitionPhysicalIds: members,
        rules: rules,
      );

  int at(int hour, [int minute = 0]) => hour * 60 + minute;

  test('aplica la franja cuando el día y el inicio del turno caen dentro', () {
    final resolver = SessionPriceResolver([tariff([rule()])]);

    final resolved = resolver.resolve(partition: court, dayOfWeek: 1, startMinutes: at(19));

    expect(resolved.price, 10000);
    expect(resolved.source, SessionPriceSource.tariffRule);
    expect(resolved.rule?.priceRuleId, 1);
    expect(resolved.tariff?.name, 'Noche');
  });

  test('el fin de la franja es exclusivo y el inicio inclusivo', () {
    final resolver = SessionPriceResolver([tariff([rule()])]);

    expect(resolver.resolve(partition: court, dayOfWeek: 1, startMinutes: at(18)).source,
        SessionPriceSource.tariffRule);
    expect(resolver.resolve(partition: court, dayOfWeek: 1, startMinutes: at(23)).source,
        SessionPriceSource.partitionDefault);
  });

  test('fuera de toda franja usa el precio base de la cancha (y sigue informando la tarifa)', () {
    final resolver = SessionPriceResolver([tariff([rule()])]);

    final sunday = resolver.resolve(partition: court, dayOfWeek: 7, startMinutes: at(19));

    expect(sunday.price, 5000);
    expect(sunday.source, SessionPriceSource.partitionDefault);
    expect(sunday.tariff?.priceTariffId, 100);
  });

  test('ignora franjas inactivas, tarifas inactivas y tarifas de otras canchas', () {
    expect(
      SessionPriceResolver([tariff([rule(active: false)])])
          .resolve(partition: court, dayOfWeek: 1, startMinutes: at(19))
          .source,
      SessionPriceSource.partitionDefault,
    );
    expect(
      SessionPriceResolver([tariff([rule()], active: false)])
          .resolve(partition: court, dayOfWeek: 1, startMinutes: at(19))
          .tariff,
      isNull,
    );
    expect(
      SessionPriceResolver([tariff([rule()], members: const [99])])
          .resolve(partition: court, dayOfWeek: 1, startMinutes: at(19))
          .price,
      5000,
    );
  });

  test('el precio manual pisa la tarifa', () {
    final resolver = SessionPriceResolver([tariff([rule()])]);

    final resolved = resolver.resolve(
      partition: court,
      dayOfWeek: 1,
      startMinutes: at(19),
      manualPrice: 7500,
    );

    expect(resolved.price, 7500);
    expect(resolved.source, SessionPriceSource.manual);
  });

  test('pricesByDayOfWeek resuelve los 7 días', () {
    final resolver = SessionPriceResolver([
      tariff([rule(), rule(id: 2, days: const [6, 7], price: 12000)]),
    ]);

    final prices = resolver.pricesByDayOfWeek(partition: court, startMinutes: at(20));

    expect(prices, {1: 10000, 2: 10000, 3: 10000, 4: 10000, 5: 10000, 6: 12000, 7: 12000});
  });
}
