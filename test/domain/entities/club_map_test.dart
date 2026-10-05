import 'package:flutter_test/flutter_test.dart';

import 'package:turni/domain/entities/club_map/club_map.dart';

// Mismo shape que GET /admin/club-map (turni_mono_be).
final _json = {
  'map': {
    'width_m': 80,
    'height_m': 50,
    'updated_at': '2026-10-04T12:00:00.000Z',
    'elements': [
      {'partition_physical_id': 31, 'x_m': 0, 'y_m': 0, 'rotated': true},
    ],
  },
  'partitions': [
    {
      'club_partition_id': 300,
      'club_type_id': 10,
      'sport': 'Pádel',
      'court_size': {'length_m': 20, 'width_m': 10},
      'courts': [
        {'partition_physical_id': 31, 'name': 'Padel A', 'physical_identifier': 1, 'is_cover': true, 'max_players': 4, 'default_session_duration': 90},
        {'partition_physical_id': 32, 'name': 'Padel B', 'physical_identifier': 2, 'is_cover': false, 'max_players': 4, 'default_session_duration': 90},
      ],
    },
    {
      'club_partition_id': 300 + 30,
      'club_type_id': 30,
      'sport': 'Tenis',
      'court_size': {'length_m': 23.77, 'width_m': 10.97},
      'courts': [
        {'partition_physical_id': 61, 'name': 'Tenis 1', 'physical_identifier': 1, 'is_cover': false, 'max_players': null, 'default_session_duration': null},
      ],
    },
  ],
};

void main() {
  final view = ClubMapView.fromJson(_json);

  test('parsea el plano y las canchas', () {
    expect(view.map!.widthM, 80);
    expect(view.map!.elements.single.rotated, isTrue);
    expect(view.partitions[1].courtSize.lengthM, 23.77);
    expect(view.partitions[1].courtSize.label, '23,77 × 10,97 m');
    expect(view.partitions[0].courts.first.isCover, isTrue);
    expect(view.findCourt(61)!.partition.sport, 'Tenis');
    expect(view.partitionIdsInMap(view.map!.elements), {300});
  });

  test('ClubMapView sin plano', () {
    final empty = ClubMapView.fromJson({..._json, 'map': null});
    expect(empty.map, isNull);
  });

  test('toJson manda lo que espera PUT /admin/club-map', () {
    const layout = ClubMapLayout(widthM: 40, heightM: 30, elements: [ClubMapElement(courtId: 31, xM: 2, yM: 3, rotated: true)]);
    expect(layout.toJson(), {
      'width_m': 40,
      'height_m': 30,
      'elements': [
        {'partition_physical_id': 31, 'x_m': 2, 'y_m': 3, 'rotated': true},
      ],
    });
  });

  test('la cancha girada ocupa ancho x largo', () {
    const size = CourtSize(lengthM: 20, widthM: 10);
    expect(courtFootprint(size, false), (w: 20.0, h: 10.0));
    expect(courtFootprint(size, true), (w: 10.0, h: 20.0));
  });

  group('findIssues', () {
    test('canchas pegadas de lado no son encimadas', () {
      final issues = findIssues(view, const [
        ClubMapElement(courtId: 31, xM: 0, yM: 0, rotated: true),
        ClubMapElement(courtId: 32, xM: 10, yM: 0, rotated: true),
      ], 40, 30);
      expect(issues.isEmpty, isTrue);
    });

    test('marca las dos encimadas', () {
      final issues = findIssues(view, const [
        ClubMapElement(courtId: 31, xM: 0, yM: 0),
        ClubMapElement(courtId: 32, xM: 19, yM: 9),
      ], 40, 30);
      expect(issues.overlapping, {31, 32});
      expect(issues.outside, isEmpty);
    });

    test('marca la que queda afuera del predio (medida con decimales)', () {
      final issues = findIssues(view, const [ClubMapElement(courtId: 61, xM: 17, yM: 0)], 40, 30);
      expect(issues.outside, {61});
    });
  });

  test('firstFreeSpot deja 1 m de margen con lo que ya está', () {
    final spot = firstFreeSpot(view, const [ClubMapElement(courtId: 31, xM: 0, yM: 0)], const CourtSize(lengthM: 20, widthM: 10), 40, 30);
    // Al lado no entra (20 + 1 + 20 > 40): va abajo, a 1 m.
    expect(spot, (x: 1, y: 11));
  });

  test('clampToPlot redondea a metros y no deja salir del predio', () {
    expect(clampToPlot(-3.4, 2.6, 20, 10, 40, 30), (x: 0, y: 3));
    expect(clampToPlot(35, 25, 20, 10, 40, 30), (x: 20, y: 20));
    // Medida con decimales: no puede quedar a medio metro del borde.
    expect(clampToPlot(30, 0, 23.77, 10.97, 40, 30), (x: 16, y: 0));
  });

  test('presets de tamaño', () {
    expect(ClubMapSizePreset.match(80, 50)!.name, 'Mediano');
    expect(ClubMapSizePreset.match(81, 50), isNull);
  });
}
