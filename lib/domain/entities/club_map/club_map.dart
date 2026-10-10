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

class ClubMapLayout {
  final int widthM;
  final int heightM;
  final List<ClubMapElement> elements;
  final List<ClubMapSpace> spaces;
  final DateTime? updatedAt;

  /// Al guardar: medidas propias que cambiaron, por cancha (`null` = volver
  /// a la del deporte). Las canchas que no están no se tocan.
  final Map<int, CourtSize?> courtSizes;

  const ClubMapLayout({
    required this.widthM,
    required this.heightM,
    required this.elements,
    this.spaces = const [],
    this.updatedAt,
    this.courtSizes = const {},
  });

  factory ClubMapLayout.fromJson(Map<String, dynamic> json) => ClubMapLayout(
        widthM: json['width_m'] as int,
        heightM: json['height_m'] as int,
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '')?.toLocal(),
        elements: (json['elements'] as List).map((e) => ClubMapElement.fromJson(e as Map<String, dynamic>)).toList(),
        spaces: ((json['spaces'] as List?) ?? const []).map((e) => ClubMapSpace.fromJson(e as Map<String, dynamic>)).toList(),
      );

  /// Lo que espera `PUT /admin/club-map`. Siempre manda los espacios (es el
  /// editor el que los conoce todos).
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
