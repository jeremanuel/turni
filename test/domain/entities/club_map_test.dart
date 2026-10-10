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
    'spaces': [
      {'type': 'BAR', 'label': 'Buffet', 'x_m': 60, 'y_m': 40, 'width_m': 10, 'height_m': 8},
      {'type': 'PARKING', 'label': null, 'x_m': 0, 'y_m': 30, 'width_m': 20, 'height_m': 15},
    ],
  },
  'space_types': [
    {'type': 'BAR', 'name': 'Bar', 'default_width_m': 10, 'default_height_m': 8},
    {'type': 'PARKING', 'name': 'Estacionamiento', 'default_width_m': 20, 'default_height_m': 15},
  ],
  'partitions': [
    {
      'club_partition_id': 300,
      'club_type_id': 10,
      'sport': 'Pádel',
      'court_size': {'length_m': 20, 'width_m': 10},
      'courts': [
        {'partition_physical_id': 31, 'name': 'Padel A', 'physical_identifier': 1, 'is_cover': true, 'max_players': 4, 'default_session_duration': 90},
        {'partition_physical_id': 32, 'name': 'Padel B', 'physical_identifier': 2, 'is_cover': false, 'max_players': 4, 'default_session_duration': 90, 'court_size': {'length_m': 18, 'width_m': 9}},
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

  test('parsea medidas propias, espacios y tipos de espacio', () {
    expect(view.findCourt(31)!.court.ownSize, isNull);
    expect(view.courtSizeOf(31), const CourtSize(lengthM: 20, widthM: 10));
    expect(view.courtSizeOf(32), const CourtSize(lengthM: 18, widthM: 9));
    expect(view.map!.spaces, hasLength(2));
    expect(view.spaceName(view.map!.spaces[0]), 'Buffet');
    expect(view.spaceName(view.map!.spaces[1]), 'Estacionamiento');
    expect(view.spaceTypes.map((t) => t.name), ['Bar', 'Estacionamiento']);
  });

  test('withCourtSize cambia solo esa cancha', () {
    final edited = view.withCourtSize(31, const CourtSize(lengthM: 22, widthM: 11));
    expect(edited.courtSizeOf(31), const CourtSize(lengthM: 22, widthM: 11));
    expect(edited.courtSizeOf(32), const CourtSize(lengthM: 18, widthM: 9));
    expect(view.courtSizeOf(31), const CourtSize(lengthM: 20, widthM: 10));
    expect(edited.withCourtSize(31, null).courtSizeOf(31), const CourtSize(lengthM: 20, widthM: 10));
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
      'spaces': [],
      'connections': [],
    });
  });

  test('toJson manda court_size solo de las canchas que cambiaron, y los espacios', () {
    const layout = ClubMapLayout(
      widthM: 40,
      heightM: 30,
      elements: [ClubMapElement(courtId: 31, xM: 0, yM: 0), ClubMapElement(courtId: 32, xM: 0, yM: 12), ClubMapElement(courtId: 61, xM: 0, yM: 22)],
      spaces: [ClubMapSpace(type: 'ENTRANCE', xM: 30, yM: 27, widthM: 6, heightM: 3)],
      courtSizes: {31: CourtSize(lengthM: 18.5, widthM: 9), 32: null},
    );
    final json = layout.toJson();
    final elements = json['elements'] as List;
    expect(elements[0], {'partition_physical_id': 31, 'x_m': 0, 'y_m': 0, 'rotated': false, 'court_size': {'length_m': 18.5, 'width_m': 9.0}});
    expect(elements[1], {'partition_physical_id': 32, 'x_m': 0, 'y_m': 12, 'rotated': false, 'court_size': null});
    expect((elements[2] as Map).containsKey('court_size'), isFalse);
    expect(json['spaces'], [
      {'type': 'ENTRANCE', 'label': null, 'x_m': 30, 'y_m': 27, 'width_m': 6, 'height_m': 3},
    ]);
  });

  test('findIssues: espacios encimados con canchas o afuera del predio', () {
    final issues = findIssues(
      view,
      const [ClubMapElement(courtId: 31, xM: 0, yM: 0)],
      40,
      30,
      spaces: const [
        ClubMapSpace(type: 'BAR', xM: 15, yM: 5, widthM: 10, heightM: 8), // pisa la cancha (20 x 10)
        ClubMapSpace(type: 'PARKING', xM: 30, yM: 20, widthM: 20, heightM: 15), // se sale
        ClubMapSpace(type: 'ENTRANCE', xM: 20, yM: 0, widthM: 6, heightM: 3), // pegada a la cancha: ok
      ],
    );
    expect(issues.overlapping, {31});
    expect(issues.overlappingSpaces, {0});
    expect(issues.outsideSpaces, {1});
    expect(issues.spaceHasIssue(2), isFalse);
    expect(issues.isEmpty, isFalse);
  });

  test('la medida propia cuenta para encimadas', () {
    // Padel A (20 x 10) ocupa y 0..10 y Padel B (18 x 9 propia) arranca en y=10: se tocan sin encimarse.
    // Si Padel A pasa a medir 11 de ancho, se enciman.
    final issues = findIssues(view, const [ClubMapElement(courtId: 31, xM: 0, yM: 0), ClubMapElement(courtId: 32, xM: 0, yM: 10)], 40, 30);
    expect(issues.isEmpty, isTrue);
    final grown = view.withCourtSize(31, const CourtSize(lengthM: 20, widthM: 11));
    expect(findIssues(grown, const [ClubMapElement(courtId: 31, xM: 0, yM: 0), ClubMapElement(courtId: 32, xM: 0, yM: 10)], 40, 30).overlapping, {31, 32});
  });

  test('firstFreeSpot esquiva los espacios', () {
    final spot = firstFreeSpot(view, const [], 6, 3, 40, 30, spaces: const [ClubMapSpace(type: 'BAR', xM: 0, yM: 0, widthM: 10, heightM: 8)]);
    expect(spot, (x: 11, y: 1));
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
    final spot = firstFreeSpot(view, const [ClubMapElement(courtId: 31, xM: 0, yM: 0)], 20, 10, 40, 30);
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

  group('Caminos', () {
  test('connectionPath dobla por donde no hay nada en el medio', () {
    // De abajo a la izquierda hacia arriba a la derecha, con una calle
    // abajo: la L horizontal primero pasaría por debajo de la calle.
    const entrance = MapRect(0, 47, 6, 3);
    const court = MapRect(20, 31, 20, 10);
    const street = MapRect(8, 47, 72, 3);
    final path = connectionPath(entrance, court, obstacles: const [entrance, court, street]);
    expect(path.map((p) => (p.x, p.y)).toList(), [(3.0, 47.0), (3.0, 36.0), (20.0, 36.0)]);
  });

    test('parsea, descarta lo que no tiene forma y vuelve a mandar', () {
      final layout = ClubMapLayout.fromJson({
        'width_m': 80,
        'height_m': 50,
        'elements': [],
        'spaces': [],
        'connections': [
          {'from': {'space': 0}, 'to': {'court': 31}},
          {'from': {'nada': 1}, 'to': {'court': 31}},
        ],
      });

      expect(layout.connections, hasLength(1));
      expect(layout.connections.single.toJson(), {'from': {'space': 0}, 'to': {'court': 31}});
      expect(layout.toJson()['connections'], [
        {'from': {'space': 0}, 'to': {'court': 31}},
      ]);
    });

    test('joins no tiene dirección', () {
      const c = ClubMapConnection(ClubMapNodeRef.court(31), ClubMapNodeRef.space(0));
      expect(c.joins(const ClubMapNodeRef.space(0), const ClubMapNodeRef.court(31)), isTrue);
      expect(c.other(const ClubMapNodeRef.court(31)), const ClubMapNodeRef.space(0));
    });

    test('sacar un espacio tira sus caminos y corre los de después', () {
      final result = connectionsWithoutSpace(const [
        ClubMapConnection(ClubMapNodeRef.space(0), ClubMapNodeRef.court(31)),
        ClubMapConnection(ClubMapNodeRef.space(1), ClubMapNodeRef.court(31)),
        ClubMapConnection(ClubMapNodeRef.space(2), ClubMapNodeRef.court(32)),
      ], 1);

      expect(result.map((c) => c.toJson()).toList(), [
        {'from': {'space': 0}, 'to': {'court': 31}},
        {'from': {'space': 1}, 'to': {'court': 32}},
      ]);
    });

    test('connectionPath: recto si se enfrentan, en L si no', () {
      // Uno arriba del otro, compartiendo x de 5 a 10: vertical en x = 7,5.
      final vertical = connectionPath(const MapRect(0, 0, 10, 5), const MapRect(5, 20, 10, 5));
      expect(vertical.map((p) => (p.x, p.y)).toList(), [(7.5, 5.0), (7.5, 20.0)]);

      // Lado a lado, compartiendo y de 2 a 6.
      final horizontal = connectionPath(const MapRect(0, 0, 10, 6), const MapRect(30, 2, 10, 10));
      expect(horizontal.map((p) => (p.x, p.y)).toList(), [(10.0, 4.0), (30.0, 4.0)]);

      // En diagonal: L, primero horizontal.
      final l = connectionPath(const MapRect(0, 0, 10, 10), const MapRect(30, 30, 10, 10));
      expect(l.map((p) => (p.x, p.y)).toList(), [(10.0, 5.0), (35.0, 5.0), (35.0, 30.0)]);
    });
  });
}
