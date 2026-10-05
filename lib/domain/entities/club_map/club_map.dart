/// Plano del club (`GET`/`PUT /admin/club-map`): un predio rectangular, en
/// metros, donde el admin ubica sus canchas. Todo viaja en metros; la
/// pantalla elige la escala.
library;

/// Medida de referencia de una cancha del deporte (largo x ancho, en metros).
class CourtSize {
  final double lengthM;
  final double widthM;

  const CourtSize({required this.lengthM, required this.widthM});

  factory CourtSize.fromJson(Map<String, dynamic> json) => CourtSize(
        lengthM: (json['length_m'] as num).toDouble(),
        widthM: (json['width_m'] as num).toDouble(),
      );

  String get label => '${_m(lengthM)} × ${_m(widthM)} m';
}

String _m(double value) {
  final text = value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  return text.replaceAll('.', ',');
}

class ClubMapCourt {
  final int id;
  final String name;
  final int? physicalIdentifier;
  final bool isCover;
  final int? maxPlayers;
  final int? defaultSessionDuration;

  const ClubMapCourt({
    required this.id,
    required this.name,
    this.physicalIdentifier,
    required this.isCover,
    this.maxPlayers,
    this.defaultSessionDuration,
  });

  factory ClubMapCourt.fromJson(Map<String, dynamic> json) => ClubMapCourt(
        id: json['partition_physical_id'] as int,
        name: json['name'] as String,
        physicalIdentifier: json['physical_identifier'] as int?,
        isCover: json['is_cover'] as bool? ?? false,
        maxPlayers: (json['max_players'] as num?)?.toInt(),
        defaultSessionDuration: (json['default_session_duration'] as num?)?.toInt(),
      );
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
  final DateTime? updatedAt;

  const ClubMapLayout({required this.widthM, required this.heightM, required this.elements, this.updatedAt});

  factory ClubMapLayout.fromJson(Map<String, dynamic> json) => ClubMapLayout(
        widthM: json['width_m'] as int,
        heightM: json['height_m'] as int,
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '')?.toLocal(),
        elements: (json['elements'] as List).map((e) => ClubMapElement.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'width_m': widthM,
        'height_m': heightM,
        'elements': elements.map((e) => e.toJson()).toList(),
      };
}

class ClubMapView {
  /// `null`: el club todavía no tiene plano.
  final ClubMapLayout? map;
  final List<ClubMapPartition> partitions;

  const ClubMapView({required this.map, required this.partitions});

  factory ClubMapView.fromJson(Map<String, dynamic> json) => ClubMapView(
        map: json['map'] == null ? null : ClubMapLayout.fromJson(json['map'] as Map<String, dynamic>),
        partitions: (json['partitions'] as List).map((p) => ClubMapPartition.fromJson(p as Map<String, dynamic>)).toList(),
      );

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
class ClubMapIssues {
  final Set<int> overlapping;
  final Set<int> outside;

  const ClubMapIssues({required this.overlapping, required this.outside});

  bool get isEmpty => overlapping.isEmpty && outside.isEmpty;

  bool hasIssue(int courtId) => overlapping.contains(courtId) || outside.contains(courtId);
}

MapRect rectOf(ClubMapView view, ClubMapElement element) {
  final size = view.findCourt(element.courtId)!.partition.courtSize;
  final fp = courtFootprint(size, element.rotated);
  return MapRect(element.xM.toDouble(), element.yM.toDouble(), fp.w, fp.h);
}

ClubMapIssues findIssues(ClubMapView view, List<ClubMapElement> elements, int widthM, int heightM) {
  final overlapping = <int>{};
  final outside = <int>{};
  final rects = [for (final e in elements) rectOf(view, e)];

  for (var i = 0; i < elements.length; i++) {
    if (!rects[i].isInside(widthM, heightM)) outside.add(elements[i].courtId);
    for (var j = i + 1; j < elements.length; j++) {
      if (rects[i].overlaps(rects[j])) {
        overlapping
          ..add(elements[i].courtId)
          ..add(elements[j].courtId);
      }
    }
  }

  return ClubMapIssues(overlapping: overlapping, outside: outside);
}

/// Primer lugar libre (recorriendo de arriba a la izquierda) con 1 m de
/// margen alrededor. Si no entra, (0, 0).
({int x, int y}) firstFreeSpot(ClubMapView view, List<ClubMapElement> elements, CourtSize size, int widthM, int heightM) {
  final fp = courtFootprint(size, false);
  final taken = [for (final e in elements) rectOf(view, e)];

  for (var y = 1; y + fp.h <= heightM; y++) {
    for (var x = 1; x + fp.w <= widthM; x++) {
      final probe = MapRect(x - 1.0, y - 1.0, fp.w + 2, fp.h + 2);
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
