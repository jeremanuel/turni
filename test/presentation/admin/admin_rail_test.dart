import 'package:flutter_test/flutter_test.dart';
import 'package:turni/presentation/admin/widgets/admin_destinations.dart';
import 'package:turni/presentation/admin/widgets/admin_rail.dart';

void main() {
  final groups = adminRailGroups;

  test('alto de la lista cerrada: filas, separadores y «Más»', () {
    // 8 filas de 44, 7 espacios de 2 y 2 separadores de 13.
    expect(collapsedListHeight(groups), 8 * 44 + 7 * 2 + 2 * 13);
    expect(collapsedListHeight(groups, withMore: true), 9 * 44 + 8 * 2 + 2 * 13);
  });

  test('si entra todo, no hay «Más»', () {
    final split = splitForHeight(groups, 1000);
    expect(split.hidden, isEmpty);
    expect(split.shown, groups);
  });

  test('si no entra, lo que sobra va a «Más» en orden', () {
    final split = splitForHeight(groups, 380);
    final shown = [for (final (_, items) in split.shown) ...items];
    expect(collapsedListHeight(split.shown, withMore: true), lessThanOrEqualTo(380));
    expect(shown, [AdminDestinations.inicio, AdminDestinations.turnos, AdminDestinations.clientes, AdminDestinations.pagos, AdminDestinations.mapa, AdminDestinations.torneos]);
    expect(split.hidden, [AdminDestinations.configuracion, AdminDestinations.usuarios]);
  });

  test('la sección actual nunca queda escondida: toma el último lugar', () {
    final split = splitForHeight(groups, 380, active: AdminDestinations.usuarios);
    final shown = [for (final (_, items) in split.shown) ...items];
    expect(shown.last, AdminDestinations.usuarios);
    expect(split.hidden, contains(AdminDestinations.torneos));
    expect(split.hidden, isNot(contains(AdminDestinations.usuarios)));
    // Los grupos vacíos no quedan: Administración solo con Usuarios.
    expect(split.shown.last.$1, 'Administración');
    expect(split.shown.last.$2, [AdminDestinations.usuarios]);
  });

  test('con muy poco alto quedan al menos uno y «Más»', () {
    final split = splitForHeight(groups, 60);
    expect([for (final (_, items) in split.shown) ...items], hasLength(1));
    expect(split.hidden, hasLength(7));
  });
}
