import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/utils/domain_error.dart';
import 'package:turni/core/utils/either.dart';
import 'package:turni/domain/entities/club_info.dart';
import 'package:turni/domain/entities/club_partition.dart';
import 'package:turni/domain/entities/club_type.dart';
import 'package:turni/domain/entities/physical_partition.dart';
import 'package:turni/domain/entities/admin_product.dart';
import 'package:turni/domain/entities/price_rule.dart';
import 'package:turni/domain/entities/price_tariff.dart';
import 'package:turni/domain/entities/product_category.dart';
import 'package:turni/domain/repositories/admin_repository.dart';
import 'package:turni/domain/repositories/club_info_repository.dart';
import 'package:turni/domain/repositories/club_partition_admin_repository.dart';
import 'package:turni/domain/repositories/price_tariff_repository.dart';
import 'package:turni/domain/repositories/product_admin_repository.dart';
import 'package:turni/presentation/admin/club_config/club_config_page.dart';
import 'package:turni/presentation/admin/club_config/tabs/price_tariffs_tab.dart';
import 'package:turni/presentation/admin/club_config/tabs/products_tab.dart';

class FakeAdminRepo implements AdminRepository {
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();

  @override
  Future<Either<DomainError, int>> getPendingRequestTtlMinutes() async =>
      Either.right(60);
}

class FakeClubInfoRepo implements ClubInfoRepository {
  @override
  Future<Either<DomainError, ClubInfo>> getClubInfo() async =>
      Either.right(ClubInfo(name: 'Test Club', address: 'Test 123'));

  @override
  Future<Either<DomainError, ClubInfo>> updateClubInfo({
    String? name,
    String? address,
    double? lat,
    double? lng,
  }) async =>
      Either.right(ClubInfo(name: name, address: address, lat: lat, lng: lng));
}

class FakeClubPartitionAdminRepo implements ClubPartitionAdminRepository {
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();

  @override
  Future<Either<DomainError, List<ClubType>>> listClubTypes() async =>
      Either.right([ClubType(clubTypeId: 1, name: 'Pádel')]);

  @override
  Future<Either<DomainError, List<ClubPartition>>> listClubPartitions({
    bool includeInactive = true,
  }) async =>
      Either.right([
        ClubPartition(
          club_partition_id: 1,
          club_id: 1,
          club_type_id: 1,
          physicalPartitionName: 'Sector Pádel',
        ),
      ]);

  @override
  Future<Either<DomainError, List<PhysicalPartition>>> listPartitionPhysical(
    int clubPartitionId, {
    bool includeInactive = true,
  }) async =>
      Either.right([]);
}

class FakePriceTariffRepo implements PriceTariffRepository {
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();

  @override
  Future<Either<DomainError, List<PriceTariff>>> listByClubPartition(int clubPartitionId) async =>
      Either.right([
        PriceTariff(
          priceTariffId: 1,
          clubPartitionId: clubPartitionId,
          name: 'Canchas 1 y 2',
          active: true,
          memberPartitionPhysicalIds: const [],
          rules: [
            PriceRule(
              priceRuleId: 1,
              priceTariffId: 1,
              daysOfWeek: const [1, 2, 3, 4, 5],
              startTime: '08:00',
              endTime: '14:00',
              price: 8000,
              active: true,
            ),
          ],
        ),
      ]);
}

class FakeProductAdminRepo implements ProductAdminRepository {
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();

  @override
  Future<Either<DomainError, List<ProductCategory>>> listCategories({bool includeInactive = true}) async =>
      Either.right([ProductCategory(categoryId: 1, clubId: 1, name: 'Bebidas', active: true)]);

  @override
  Future<Either<DomainError, List<AdminProduct>>> listProducts({bool includeInactive = true}) async =>
      Either.right([
        AdminProduct(productId: 1, clubId: 1, categoryId: 1, name: 'Agua mineral', price: 1200, active: true),
      ]);
}

void main() {
  setUp(() {
    if (sl.isRegistered<AdminRepository>()) sl.unregister<AdminRepository>();
    if (sl.isRegistered<ClubInfoRepository>()) sl.unregister<ClubInfoRepository>();
    if (sl.isRegistered<ClubPartitionAdminRepository>()) {
      sl.unregister<ClubPartitionAdminRepository>();
    }
    if (sl.isRegistered<PriceTariffRepository>()) sl.unregister<PriceTariffRepository>();
    if (sl.isRegistered<ProductAdminRepository>()) sl.unregister<ProductAdminRepository>();

    sl.registerSingleton<AdminRepository>(FakeAdminRepo());
    sl.registerSingleton<ClubInfoRepository>(FakeClubInfoRepo());
    sl.registerSingleton<ClubPartitionAdminRepository>(FakeClubPartitionAdminRepo());
    sl.registerSingleton<PriceTariffRepository>(FakePriceTariffRepo());
    sl.registerSingleton<ProductAdminRepository>(FakeProductAdminRepo());
  });

  testWidgets('ClubConfigPage builds with its tabs and loads club info', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ClubConfigPage()));
    await tester.pumpAndSettle();

    expect(find.text('Configuración'), findsOneWidget);
    expect(find.text('Información del club'), findsWidgets);
    expect(find.text('Deportes y canchas'), findsWidgets);
    expect(find.text('Tarifas por horario'), findsWidgets);
    expect(find.text('Productos'), findsWidgets);
    expect(find.text('Solicitudes de turno'), findsWidgets);
    expect(find.text('Test Club'), findsOneWidget);
  });

  testWidgets('PriceTariffsTab shows tariffs and rules for the selected sector', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PriceTariffsTab()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Canchas 1 y 2'), findsWidgets);
    expect(find.text('08:00 – 14:00'), findsOneWidget);
    expect(find.text('\$8.000'), findsOneWidget);
  });

  testWidgets('ProductsTab shows products and categories', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ProductsTab()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Agua mineral'), findsOneWidget);
    expect(find.text('Bebidas'), findsWidgets);
    expect(find.text('\$1.200'), findsOneWidget);
  });
}
