/// Plano del club (`GET`/`PUT /admin/club-map`): un predio rectangular, en
/// metros, donde el admin ubica sus canchas. Todo viaja en metros; la
/// pantalla elige la escala.
library;

/// Medida de una cancha (largo x ancho, en metros): la de referencia del
/// deporte o la propia de una cancha.
class CourtSize {
  final double lengthM;
  final double widthM;

  /// Límites de una medida propia (el backend valida lo mismo).
  static const minSideM = 1.0;
  static const maxSideM = 200.0;

  const CourtSize({required this.lengthM, required this.widthM});

  factory CourtSize.fromJson(Map<String, dynamic> json) => CourtSize(
        lengthM: (json['length_m'] as num).toDouble(),
        widthM: (json['width_m'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'length_m': lengthM, 'width_m': widthM};

  String get label => '${_m(lengthM)} × ${_m(widthM)} m';

  @override
  bool operator ==(Object other) => other is CourtSize && other.lengthM == lengthM && other.widthM == widthM;

  @override
  int get hashCode => Object.hash(lengthM, widthM);
}

/// Metros con coma decimal y sin decimales de más: 36 → "36", 23.77 → "23,77".
String formatMeters(double value) => _m(value);

String _m(double value) {
  // Hasta 2 decimales, sin ceros de más: 36 → "36", 18.5 → "18,5", 23.77 → "23,77".
  final text = value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return text.replaceAll('.', ',');
}

class ClubMapCourt {
  final int id;
  final String name;
  final int? physicalIdentifier;
  final bool isCover;
  final int? maxPlayers;
  final int? defaultSessionDuration;

  /// Medida propia de la cancha. `null`: usa la del deporte.
  final CourtSize? ownSize;

  const ClubMapCourt({
    required this.id,
    required this.name,
    this.physicalIdentifier,
    required this.isCover,
    this.maxPlayers,
    this.defaultSessionDuration,
    this.ownSize,
  });

  factory ClubMapCourt.fromJson(Map<String, dynamic> json) => ClubMapCourt(
        id: json['partition_physical_id'] as int,
        name: json['name'] as String,
        physicalIdentifier: json['physical_identifier'] as int?,
        isCover: json['is_cover'] as bool? ?? false,
        maxPlayers: (json['max_players'] as num?)?.toInt(),
        defaultSessionDuration: (json['default_session_duration'] as num?)?.toInt(),
        ownSize: json['court_size'] == null ? null : CourtSize.fromJson(json['court_size'] as Map<String, dynamic>),
      );

  ClubMapCourt withOwnSize(CourtSize? size) => ClubMapCourt(
        id: id,
        name: name,
        physicalIdentifier: physicalIdentifier,
        isCover: isCover,
        maxPlayers: maxPlayers,
        defaultSessionDuration: defaultSessionDuration,
        ownSize: size,
      );
}

/// Tipo de espacio del plano que no es una cancha (catálogo del backend).
class ClubMapSpaceType {
  final String type;
  final String name;
  final int defaultWidthM;
  final int defaultHeightM;

  const ClubMapSpaceType({required this.type, required this.name, required this.defaultWidthM, required this.defaultHeightM});

  factory ClubMapSpaceType.fromJson(Map<String, dynamic> json) => ClubMapSpaceType(
        type: json['type'] as String,
        name: json['name'] as String,
        defaultWidthM: (json['default_width_m'] as num).toInt(),
        defaultHeightM: (json['default_height_m'] as num).toInt(),
      );
}

/// Espacio del predio que no es una cancha (entrada, vestuarios, bar...):
/// un rectángulo en metros enteros.
class ClubMapSpace {
  final String type;

  /// Nombre opcional. `null`: se muestra el del tipo.
  final String? label;
  final int xM;
  final int yM;
  final int widthM;
  final int heightM;

  static const maxLabelLength = 40;

  const ClubMapSpace({required this.type, this.label, required this.xM, required this.yM, required this.widthM, required this.heightM});

  factory ClubMapSpace.fromJson(Map<String, dynamic> json) => ClubMapSpace(
        type: json['type'] as String,
        label: json['label'] as String?,
        xM: json['x_m'] as int,
        yM: json['y_m'] as int,
        widthM: json['width_m'] as int,
        heightM: json['height_m'] as int,
      );

  Map<String, dynamic> toJson() => {'type': type, 'label': label, 'x_m': xM, 'y_m': yM, 'width_m': widthM, 'height_m': heightM};

  ClubMapSpace copyWith({int? xM, int? yM, int? widthM, int? heightM, String? Function()? label}) => ClubMapSpace(
        type: type,
        label: label != null ? label() : this.label,
        xM: xM ?? this.xM,
        yM: yM ?? this.yM,
        widthM: widthM ?? this.widthM,
        heightM: heightM ?? this.heightM,
      );

  MapRect get rect => MapRect(xM.toDouble(), yM.toDouble(), widthM.toDouble(), heightM.toDouble());
}

/// Un deporte del club (club_partition) con sus canchas.
class ClubMapPartition {
  final int id;
  final int clubTypeId;
  final String sport;
  final CourtSize courtSize;
  final List<ClubMapCourt> courts;

  const ClubMapPartition({
    required this.id,
    required this.clubTypeId,
    required this.sport,
    required this.courtSize,
    required this.courts,
  });

  ClubMapPartition withCourts(List<ClubMapCourt> courts) =>
      ClubMapPartition(id: id, clubTypeId: clubTypeId, sport: sport, courtSize: courtSize, courts: courts);

  factory ClubMapPartition.fromJson(Map<String, dynamic> json) => ClubMapPartition(
        id: json['club_partition_id'] as int,
        clubTypeId: (json['club_type_id'] as num).toInt(),
        sport: json['sport'] as String,
        courtSize: CourtSize.fromJson(json['court_size'] as Map<String, dynamic>),
        courts: (json['courts'] as List).map((c) => ClubMapCourt.fromJson(c as Map<String, dynamic>)).toList(),
      );
}

/// Una cancha ubicada: esquina superior izquierda en metros.
class ClubMapElement {
  final int courtId;
  final int xM;
  final int yM;

  /// `false`: el largo va en horizontal. `true`: girada 90°.
  final bool rotated;

  const ClubMapElement({required this.courtId, required this.xM, required this.yM, this.rotated = false});

  factory ClubMapElement.fromJson(Map<String, dynamic> json) => ClubMapElement(
        courtId: json['partition_physical_id'] as int,
        xM: json['x_m'] as int,
        yM: json['y_m'] as int,
        rotated: json['rotated'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {'partition_physical_id': courtId, 'x_m': xM, 'y_m': yM, 'rotated': rotated};

  ClubMapElement copyWith({int? xM, int? yM, bool? rotated}) =>
      ClubMapElement(courtId: courtId, xM: xM ?? this.xM, yM: yM ?? this.yM, rotated: rotated ?? this.rotated);
}

/// Extremo de un camino: una cancha (por id) o un espacio (por su posición
/// en `spaces`; los espacios se guardan enteros en cada PUT, así que la
/// posición es lo estable).
class ClubMapNodeRef {
  final int? courtId;
  final int? spaceIndex;

  const ClubMapNodeRef.court(int id)
      : courtId = id,
        spaceIndex = null;

  const ClubMapNodeRef.space(int index)
      : spaceIndex = index,
        courtId = null;

  static ClubMapNodeRef? fromJson(Object? json) {
    if (json is! Map) return null;
    final court = json['court'];
    final space = json['space'];
    if (court is int) return ClubMapNodeRef.court(court);
    if (space is int) return ClubMapNodeRef.space(space);
    return null;
  }

  Map<String, dynamic> toJson() => courtId != null ? {'court': courtId} : {'space': spaceIndex};

  @override
  bool operator ==(Object other) => other is ClubMapNodeRef && other.courtId == courtId && other.spaceIndex == spaceIndex;

  @override
  int get hashCode => Object.hash(courtId, spaceIndex);
}

/// Camino entre dos elementos del plano. Sin dirección: A-B es lo mismo que B-A.
class ClubMapConnection {
  final ClubMapNodeRef from;
  final ClubMapNodeRef to;

  const ClubMapConnection(this.from, this.to);

  static ClubMapConnection? fromJson(Object? json) {
    if (json is! Map) return null;
    final from = ClubMapNodeRef.fromJson(json['from']);
    final to = ClubMapNodeRef.fromJson(json['to']);
    return from == null || to == null ? null : ClubMapConnection(from, to);
  }

  Map<String, dynamic> toJson() => {'from': from.toJson(), 'to': to.toJson()};

  bool touches(ClubMapNodeRef ref) => from == ref || to == ref;

  bool joins(ClubMapNodeRef a, ClubMapNodeRef b) => (from == a && to == b) || (from == b && to == a);

  /// El otro extremo, si [ref] es uno de los dos.
  ClubMapNodeRef? other(ClubMapNodeRef ref) => from == ref ? to : (to == ref ? from : null);
}

/// Los caminos después de sacar el espacio en la posición [index]: se caen
/// los que lo usaban y se corren los de los espacios que venían después.
List<ClubMapConnection> connectionsWithoutSpace(List<ClubMapConnection> connections, int index) {
  ClubMapNodeRef shift(ClubMapNodeRef ref) =>
      ref.spaceIndex != null && ref.spaceIndex! > index ? ClubMapNodeRef.space(ref.spaceIndex! - 1) : ref;
  final removed = ClubMapNodeRef.space(index);
  return [
    for (final c in connections)
      if (!c.touches(removed)) ClubMapConnection(shift(c.from), shift(c.to)),
  ];
}

/// Recorrido de un camino en metros, de borde a borde: recto si los dos
/// rectángulos se enfrentan, si no en L (primero horizontal, después
/// vertical, o al revés si así pasa menos por debajo de [obstacles]).
List<({double x, double y})> connectionPath(MapRect a, MapRect b, {List<MapRect> obstacles = const []}) =>
    _trimToEdges(_centerPath(a, b, obstacles), a, b);

List<({double x, double y})> _centerPath(MapRect a, MapRect b, List<MapRect> obstacles) {
  final ax = a.x + a.w / 2, ay = a.y + a.h / 2;
  final bx = b.x + b.w / 2, by = b.y + b.h / 2;

  // Se enfrentan en vertical: una línea recta en el medio de lo que comparten.
  final left = a.x > b.x ? a.x : b.x;
  final right = (a.x + a.w) < (b.x + b.w) ? a.x + a.w : b.x + b.w;
  if (right - left >= 1) {
    final x = (left + right) / 2;
    return [(x: x, y: ay), (x: x, y: by)];
  }
  // Se enfrentan en horizontal.
  final top = a.y > b.y ? a.y : b.y;
  final bottom = (a.y + a.h) < (b.y + b.h) ? a.y + a.h : b.y + b.h;
  if (bottom - top >= 1) {
    final y = (top + bottom) / 2;
    return [(x: ax, y: y), (x: bx, y: y)];
  }
  // Hay que doblar: de las dos L, la que menos pasa por debajo de otras
  // cosas del plano ([obstacles]).
  final horizontalFirst = [(x: ax, y: ay), (x: bx, y: ay), (x: bx, y: by)];
  final verticalFirst = [(x: ax, y: ay), (x: ax, y: by), (x: bx, y: by)];
  return _hiddenLength(verticalFirst, obstacles, a, b) < _hiddenLength(horizontalFirst, obstacles, a, b)
      ? verticalFirst
      : horizontalFirst;
}

/// El recorrido arranca en el borde de [a] y termina en el borde de [b]: el
/// camino une los dos elementos, no se mete adentro.
List<({double x, double y})> _trimToEdges(List<({double x, double y})> points, MapRect a, MapRect b) {
  ({double x, double y}) toEdge(({double x, double y}) inside, ({double x, double y}) toward, MapRect r) {
    if (inside.y == toward.y) return (x: toward.x > inside.x ? r.x + r.w : r.x, y: inside.y);
    return (x: inside.x, y: toward.y > inside.y ? r.y + r.h : r.y);
  }

  final n = points.length;
  return [
    toEdge(points[0], points[1], a),
    for (var i = 1; i < n - 1; i++) points[i],
    toEdge(points[n - 1], points[n - 2], b),
  ];
}

bool _sameRect(MapRect r, MapRect o) => r.x == o.x && r.y == o.y && r.w == o.w && r.h == o.h;

/// Metros del recorrido que quedan debajo de [obstacles] (sin contar los
/// dos extremos).
double _hiddenLength(List<({double x, double y})> points, List<MapRect> obstacles, MapRect a, MapRect b) {
  var hidden = 0.0;
  for (var i = 0; i + 1 < points.length; i++) {
    final p = points[i], q = points[i + 1];
    for (final r in obstacles) {
      if (_sameRect(r, a) || _sameRect(r, b)) continue;
      if (p.y == q.y) {
        if (p.y <= r.y || p.y >= r.y + r.h) continue;
        final from = p.x < q.x ? p.x : q.x, to = p.x < q.x ? q.x : p.x;
        final overlap = (to < r.x + r.w ? to : r.x + r.w) - (from > r.x ? from : r.x);
        if (overlap > 0) hidden += overlap;
      } else {
        if (p.x <= r.x || p.x >= r.x + r.w) continue;
        final from = p.y < q.y ? p.y : q.y, to = p.y < q.y ? q.y : p.y;
        final overlap = (to < r.y + r.h ? to : r.y + r.h) - (from > r.y ? from : r.y);
        if (overlap > 0) hidden += overlap;
      }
    }
  }
  return hidden;
}

class ClubMapLayout {
  final int widthM;
  final int heightM;
  final List<ClubMapElement> elements;
  final List<ClubMapSpace> spaces;
  final List<ClubMapConnection> connections;
  final DateTime? updatedAt;

  /// Al guardar: medidas propias que cambiaron, por cancha (`null` = volver
  /// a la del deporte). Las canchas que no están no se tocan.
  final Map<int, CourtSize?> courtSizes;

  const ClubMapLayout({
    required this.widthM,
    required this.heightM,
    required this.elements,
    this.spaces = const [],
    this.connections = const [],
    this.updatedAt,
    this.courtSizes = const {},
  });

  factory ClubMapLayout.fromJson(Map<String, dynamic> json) => ClubMapLayout(
        widthM: json['width_m'] as int,
        heightM: json['height_m'] as int,
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '')?.toLocal(),
        elements: (json['elements'] as List).map((e) => ClubMapElement.fromJson(e as Map<String, dynamic>)).toList(),
        spaces: ((json['spaces'] as List?) ?? const []).map((e) => ClubMapSpace.fromJson(e as Map<String, dynamic>)).toList(),
        connections: [
          for (final c in (json['connections'] as List?) ?? const [])
            if (ClubMapConnection.fromJson(c) case final connection?) connection,
        ],
      );

  /// Lo que espera `PUT /admin/club-map`. Siempre manda los espacios y los
  /// caminos (es el editor el que los conoce todos).
  Map<String, dynamic> toJson() => {
        'width_m': widthM,
        'height_m': heightM,
        'elements': [
          for (final e in elements)
            {
              ...e.toJson(),
              if (courtSizes.containsKey(e.courtId)) 'court_size': courtSizes[e.courtId]?.toJson(),
            },
        ],
        'spaces': spaces.map((s) => s.toJson()).toList(),
        'connections': connections.map((c) => c.toJson()).toList(),
      };
}

class ClubMapView {
  /// `null`: el club todavía no tiene plano.
  final ClubMapLayout? map;
  final List<ClubMapPartition> partitions;

  /// Tipos de espacio que se pueden sumar al plano.
  final List<ClubMapSpaceType> spaceTypes;

  const ClubMapView({required this.map, required this.partitions, this.spaceTypes = const []});

  factory ClubMapView.fromJson(Map<String, dynamic> json) => ClubMapView(
        map: json['map'] == null ? null : ClubMapLayout.fromJson(json['map'] as Map<String, dynamic>),
        partitions: (json['partitions'] as List).map((p) => ClubMapPartition.fromJson(p as Map<String, dynamic>)).toList(),
        spaceTypes: ((json['space_types'] as List?) ?? const []).map((t) => ClubMapSpaceType.fromJson(t as Map<String, dynamic>)).toList(),
      );

  /// Medida con la que se dibuja una cancha: la propia o la del deporte.
  CourtSize courtSizeOf(int courtId) {
    final found = findCourt(courtId)!;
    return found.court.ownSize ?? found.partition.courtSize;
  }

  /// La misma vista con otra medida propia para una cancha (para el editor).
  ClubMapView withCourtSize(int courtId, CourtSize? size) => ClubMapView(
        map: map,
        spaceTypes: spaceTypes,
        partitions: [
          for (final p in partitions)
            p.courts.any((c) => c.id == courtId) ? p.withCourts([for (final c in p.courts) c.id == courtId ? c.withOwnSize(size) : c]) : p,
        ],
      );

  /// Nombre a mostrar de un espacio: el suyo o el del tipo.
  String spaceName(ClubMapSpace space) {
    final label = space.label?.trim();
    if (label != null && label.isNotEmpty) return label;
    for (final t in spaceTypes) {
      if (t.type == space.type) return t.name;
    }
    return 'Espacio';
  }

  String spaceTypeName(String type) {
    for (final t in spaceTypes) {
      if (t.type == type) return t.name;
    }
    return 'Espacio';
  }

  ({ClubMapPartition partition, ClubMapCourt court})? findCourt(int courtId) {
    for (final partition in partitions) {
      for (final court in partition.courts) {
        if (court.id == courtId) return (partition: partition, court: court);
      }
    }
    return null;
  }

  /// Deportes con al menos una cancha en el plano. Cada deporte se suma una
  /// sola vez.
  Set<int> partitionIdsInMap(List<ClubMapElement> elements) {
    final ids = <int>{};
    for (final element in elements) {
      final found = findCourt(element.courtId);
      if (found != null) ids.add(found.partition.id);
    }
    return ids;
  }
}

/// Tamaños de predio que se ofrecen, sacados de complejos reales.
class ClubMapSizePreset {
  final String id;
  final String name;
  final int widthM;
  final int heightM;
  final String fits;
  final String example;

  const ClubMapSizePreset({
    required this.id,
    required this.name,
    required this.widthM,
    required this.heightM,
    required this.fits,
    required this.example,
  });

  int get areaM2 => widthM * heightM;

  static const all = [
    ClubMapSizePreset(
      id: 'chico',
      name: 'Chico',
      widthM: 40,
      heightM: 30,
      fits: 'Hasta 4 canchas de pádel, o 1 de fútbol 5 y 1 de pádel',
      example: 'Ej.: club de 4 canchas de pádel techadas (1.100–1.400 m²)',
    ),
    ClubMapSizePreset(
      id: 'mediano',
      name: 'Mediano',
      widthM: 80,
      heightM: 50,
      fits: '2 de fútbol 5, varias de pádel y alguna de tenis',
      example: 'Ej.: complejo de 4.000 m² en Rosario con fútbol 5 y 2 de pádel',
    ),
    ClubMapSizePreset(
      id: 'grande',
      name: 'Grande',
      widthM: 120,
      heightM: 70,
      fits: '3 o 4 de fútbol 5, más pádel y tenis',
      example: 'Ej.: predio de 8.000 m² en Rosario con 3 de fútbol 5 y 2 de pádel',
    ),
  ];

  static const defaultPreset = 'mediano';

  static ClubMapSizePreset? match(int widthM, int heightM) {
    for (final preset in all) {
      if (preset.widthM == widthM && preset.heightM == heightM) return preset;
    }
    return null;
  }
}

/// Rectángulo en metros.
class MapRect {
  final double x;
  final double y;
  final double w;
  final double h;

  const MapRect(this.x, this.y, this.w, this.h);

  bool overlaps(MapRect other) =>
      x < other.x + other.w && other.x < x + w && y < other.y + other.h && other.y < y + h;

  bool isInside(int widthM, int heightM) => x >= 0 && y >= 0 && x + w <= widthM && y + h <= heightM;
}

/// Lo que ocupa una cancha en el plano: sin girar, el largo va en horizontal.
({double w, double h}) courtFootprint(CourtSize size, bool rotated) =>
    rotated ? (w: size.widthM, h: size.lengthM) : (w: size.lengthM, h: size.widthM);

/// Problemas de un plano en edición. El backend valida lo mismo al guardar.
/// Canchas por id; espacios por su posición en la lista.
class ClubMapIssues {
  final Set<int> overlapping;
  final Set<int> outside;
  final Set<int> overlappingSpaces;
  final Set<int> outsideSpaces;

  const ClubMapIssues({required this.overlapping, required this.outside, this.overlappingSpaces = const {}, this.outsideSpaces = const {}});

  bool get isEmpty => overlapping.isEmpty && outside.isEmpty && overlappingSpaces.isEmpty && outsideSpaces.isEmpty;

  bool get hasOutside => outside.isNotEmpty || outsideSpaces.isNotEmpty;

  bool get hasOverlap => overlapping.isNotEmpty || overlappingSpaces.isNotEmpty;

  bool hasIssue(int courtId) => overlapping.contains(courtId) || outside.contains(courtId);

  bool spaceHasIssue(int index) => overlappingSpaces.contains(index) || outsideSpaces.contains(index);
}

/// Rectángulo de un extremo de camino. `null` si ya no está en el plano.
MapRect? rectOfNode(ClubMapView view, List<ClubMapElement> elements, List<ClubMapSpace> spaces, ClubMapNodeRef ref) {
  if (ref.spaceIndex != null) {
    return ref.spaceIndex! < spaces.length ? spaces[ref.spaceIndex!].rect : null;
  }
  for (final e in elements) {
    if (e.courtId == ref.courtId) return view.findCourt(e.courtId) == null ? null : rectOf(view, e);
  }
  return null;
}

MapRect rectOf(ClubMapView view, ClubMapElement element) {
  final fp = courtFootprint(view.courtSizeOf(element.courtId), element.rotated);
  return MapRect(element.xM.toDouble(), element.yM.toDouble(), fp.w, fp.h);
}

ClubMapIssues findIssues(ClubMapView view, List<ClubMapElement> elements, int widthM, int heightM, {List<ClubMapSpace> spaces = const []}) {
  final overlapping = <int>{};
  final outside = <int>{};
  final overlappingSpaces = <int>{};
  final outsideSpaces = <int>{};

  // Canchas primero (índices 0..n-1) y después los espacios.
  final rects = [for (final e in elements) rectOf(view, e), for (final s in spaces) s.rect];
  void markOverlap(int i) => i < elements.length ? overlapping.add(elements[i].courtId) : overlappingSpaces.add(i - elements.length);

  for (var i = 0; i < rects.length; i++) {
    if (!rects[i].isInside(widthM, heightM)) {
      i < elements.length ? outside.add(elements[i].courtId) : outsideSpaces.add(i - elements.length);
    }
    for (var j = i + 1; j < rects.length; j++) {
      if (rects[i].overlaps(rects[j])) {
        markOverlap(i);
        markOverlap(j);
      }
    }
  }

  return ClubMapIssues(overlapping: overlapping, outside: outside, overlappingSpaces: overlappingSpaces, outsideSpaces: outsideSpaces);
}

/// Primer lugar libre (recorriendo de arriba a la izquierda) con 1 m de
/// margen alrededor, para algo de [w] x [h] metros. Si no entra, (0, 0).
({int x, int y}) firstFreeSpot(ClubMapView view, List<ClubMapElement> elements, double w, double h, int widthM, int heightM, {List<ClubMapSpace> spaces = const []}) {
  final taken = [for (final e in elements) rectOf(view, e), for (final s in spaces) s.rect];

  for (var y = 1; y + h <= heightM; y++) {
    for (var x = 1; x + w <= widthM; x++) {
      final probe = MapRect(x - 1.0, y - 1.0, w + 2, h + 2);
      if (!taken.any(probe.overlaps)) return (x: x, y: y);
    }
  }
  return (x: 0, y: 0);
}

/// Encaja una posición dentro del predio, en metros enteros.
({int x, int y}) clampToPlot(double x, double y, double w, double h, int widthM, int heightM) {
  int fit(double value, double size, int max) {
    final limit = (max - size).floor();
    return value.round().clamp(0, limit < 0 ? 0 : limit);
  }

  return (x: fit(x, w, widthM), y: fit(y, h, heightM));
}
