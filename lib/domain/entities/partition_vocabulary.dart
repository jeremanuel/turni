import 'club_partition.dart';
import 'physical_partition.dart';

/// Vocabulario de una modalidad (club_partition): cómo se llaman sus espacios
/// ("Cancha", "Sala", "Profesional") y su cupo ("Jugadores", "Alumnos"), y qué
/// funciones usa (plano, cubierta, cupo).
///
/// Ningún texto de la UI hardcodea "cancha" o "jugadores": se toma de acá con
/// [PartitionVocabulary.of] (un texto de una modalidad) o
/// [PartitionVocabulary.common] (un texto que mezcla varias modalidades).
class PartitionVocabulary {
  const PartitionVocabulary({
    required this.category,
    required this.space,
    required this.participant,
    required this.features,
  });

  /// COURT | CLASS | PERSONAL | OTHER
  final String category;
  final SpaceTerm space;
  final VocabularyTerm participant;
  final PartitionFeatures features;

  /// "Cubierta" / "Descubierto", concordando con el espacio. null si el tipo
  /// no usa cubierta (una sala, un profesional).
  String? coverLabel(bool isCover) {
    if (!features.cover) return null;
    return isCover ? space.g('Cubierta', 'Cubierto') : space.g('Descubierta', 'Descubierto');
  }

  /// "4 jugadores" / "1 alumno". null si el tipo no usa cupo o no hay número.
  String? capacityLabel(int? count) {
    if (!features.capacity || count == null || count <= 0) return null;
    return participant.count(count);
  }

  /// Lo que se usaba antes de tener vocabulario: una cancha con jugadores.
  static const court = PartitionVocabulary(
    category: 'COURT',
    space: SpaceTerm(singular: 'Cancha', plural: 'Canchas', gender: Gender.f),
    participant: VocabularyTerm(singular: 'Jugador', plural: 'Jugadores'),
    features: PartitionFeatures(map: true, cover: true, capacity: true),
  );

  /// Término neutro para textos que mezclan modalidades con nombres distintos.
  static const generic = PartitionVocabulary(
    category: 'OTHER',
    space: SpaceTerm(singular: 'Espacio', plural: 'Espacios', gender: Gender.m),
    participant: VocabularyTerm(singular: 'Persona', plural: 'Personas'),
    features: PartitionFeatures(map: true, cover: true, capacity: true),
  );

  /// Vocabulario de una modalidad: el que manda el backend o, si el endpoint
  /// no lo trae (p. ej. la modalidad anidada en un turno), resuelto con su
  /// tipo y sus overrides. Sin modalidad, el de una cancha.
  static PartitionVocabulary of(ClubPartition? partition) {
    if (partition == null) return court;
    return partition.vocabulary ?? resolve(partition);
  }

  /// Para un texto que abarca varias modalidades ("Todas las canchas"): si
  /// todas se llaman igual usa ese nombre, si no el neutro ("Espacio"). Las
  /// funciones quedan prendidas si alguna modalidad las usa.
  static PartitionVocabulary common(Iterable<ClubPartition> partitions) => merge(partitions.map(of));

  /// Igual que [common], para vocabularios ya resueltos.
  static PartitionVocabulary merge(Iterable<PartitionVocabulary> all) {
    final vocabularies = all.toList();
    if (vocabularies.isEmpty) return court;

    final first = vocabularies.first;
    final features = PartitionFeatures(
      map: vocabularies.any((v) => v.features.map),
      cover: vocabularies.any((v) => v.features.cover),
      capacity: vocabularies.any((v) => v.features.capacity),
    );
    final sameSpace = vocabularies.every((v) => v.space.singular == first.space.singular);
    final sameParticipant =
        vocabularies.every((v) => v.participant.singular == first.participant.singular);

    return PartitionVocabulary(
      category: vocabularies.every((v) => v.category == first.category) ? first.category : generic.category,
      space: sameSpace ? first.space : generic.space,
      participant: sameParticipant ? first.participant : generic.participant,
      features: features,
    );
  }

  /// Misma regla que el backend (`PartitionVocabulary.ts`): el override de la
  /// modalidad gana; si no hay, el del tipo; si el tipo no lo trae, cancha.
  static PartitionVocabulary resolve(ClubPartition partition) {
    final type = partition.clubType;
    final spaceName = _clean(partition.physicalPartitionName);
    final spacePlural = _clean(partition.physicalPartitionPlural);
    final participantName = _clean(partition.participantSingular);
    final participantPlural = _clean(partition.participantPlural);

    final space = spaceName == null
        ? SpaceTerm(
            singular: type?.spaceSingular ?? court.space.singular,
            plural: spacePlural ?? type?.spacePlural ?? court.space.plural,
            gender: type?.spaceGender == null
                ? court.space.gender
                : (type!.spaceGender == 'm' ? Gender.m : Gender.f),
          )
        : SpaceTerm(
            singular: spaceName,
            plural: spacePlural ?? pluralize(spaceName),
            gender: guessGender(spaceName),
          );

    final participant = participantName == null
        ? VocabularyTerm(
            singular: type?.participantSingular ?? court.participant.singular,
            plural: participantPlural ?? type?.participantPlural ?? court.participant.plural,
          )
        : VocabularyTerm(
            singular: participantName,
            plural: participantPlural ?? pluralize(participantName),
          );

    return PartitionVocabulary(
      category: type?.category ?? court.category,
      space: space,
      participant: participant,
      features: PartitionFeatures(
        map: type?.usesMap ?? true,
        cover: type?.usesCover ?? true,
        capacity: type?.usesCapacity ?? true,
      ),
    );
  }

  factory PartitionVocabulary.fromJson(Map<String, dynamic> json) {
    final space = json['space'] as Map<String, dynamic>;
    final participant = json['participant'] as Map<String, dynamic>;
    final features = json['features'] as Map<String, dynamic>;
    return PartitionVocabulary(
      category: json['category'] as String,
      space: SpaceTerm(
        singular: space['singular'] as String,
        plural: space['plural'] as String,
        gender: space['gender'] == 'm' ? Gender.m : Gender.f,
      ),
      participant: VocabularyTerm(
        singular: participant['singular'] as String,
        plural: participant['plural'] as String,
      ),
      features: PartitionFeatures(
        map: features['map'] as bool,
        cover: features['cover'] as bool,
        capacity: features['capacity'] as bool,
      ),
    );
  }

  static PartitionVocabulary? fromJsonNullable(Object? json) =>
      json is Map<String, dynamic> ? PartitionVocabulary.fromJson(json) : null;

  /// Plural del sustantivo principal: "Box" -> "Boxes", "Cancha de pádel" ->
  /// "Canchas de pádel", "Sillón" -> "Sillones".
  static String pluralize(String singular) {
    final (head, rest) = _splitHead(singular);
    return _pluralizeWord(head) + rest;
  }

  /// Género del sustantivo principal, para "Nueva sala" / "Nuevo box".
  static Gender guessGender(String singular) {
    final (head, _) = _splitHead(singular);
    return RegExp(r'a$', caseSensitive: false).hasMatch(head) ? Gender.f : Gender.m;
  }

  static (String, String) _splitHead(String name) {
    final trimmed = name.trim();
    final space = trimmed.indexOf(' ');
    return space == -1 ? (trimmed, '') : (trimmed.substring(0, space), trimmed.substring(space));
  }

  static String _pluralizeWord(String word) {
    if (word.isEmpty) return word;
    if (RegExp(r's$', caseSensitive: false).hasMatch(word)) return word;
    if (RegExp(r'z$', caseSensitive: false).hasMatch(word)) {
      return '${word.substring(0, word.length - 1)}ces';
    }
    if (RegExp(r'[aeiouáéó]$', caseSensitive: false).hasMatch(word)) return '${word}s';
    // Agudas en -n/-s pierden la tilde: "Sillón" -> "Sillones".
    const accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u'};
    final unaccented = word.replaceAllMapped(
      RegExp(r'([áéíóú])([ns])$', caseSensitive: false),
      (m) => '${accents[m[1]!.toLowerCase()] ?? m[1]}${m[2]}',
    );
    return '${unaccented}es';
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }
}

enum Gender { f, m }

/// Un término con singular y plural ("Jugador" / "Jugadores").
class VocabularyTerm {
  const VocabularyTerm({required this.singular, required this.plural});

  final String singular;
  final String plural;

  /// Para el medio de una frase: "jugador", "cancha de pádel".
  String get lower => _lowerFirst(singular);
  String get lowerPlural => _lowerFirst(plural);

  /// "1 jugador" / "4 jugadores".
  String count(int n) => n == 1 ? '1 $lower' : '$n $lowerPlural';
}

/// El espacio que se reserva. Además del número lleva género, para concordar.
class SpaceTerm extends VocabularyTerm {
  const SpaceTerm({required super.singular, required super.plural, required this.gender});

  final Gender gender;

  bool get isFeminine => gender == Gender.f;

  /// "Nueva cancha" / "Nuevo profesional".
  String get nuevo => '${isFeminine ? 'Nueva' : 'Nuevo'} $lower';

  /// "Todas las canchas" / "Todos los profesionales".
  String get todos => '${isFeminine ? 'Todas las' : 'Todos los'} $lowerPlural';

  /// "la cancha" / "el profesional".
  String get definite => '${isFeminine ? 'la' : 'el'} $lower';

  /// "de la cancha" / "del profesional".
  String get ofDefinite => isFeminine ? 'de la $lower' : 'del $lower';

  /// "las canchas" / "los profesionales".
  String get definitePlural => '${isFeminine ? 'las' : 'los'} $lowerPlural';

  /// "una cancha" / "un profesional".
  String get indefinite => '${isFeminine ? 'una' : 'un'} $lower';

  /// Elige la forma que concuerda con el espacio: `g('inactiva', 'inactivo')`.
  String g(String feminine, String masculine) => isFeminine ? feminine : masculine;

  /// "esta cancha" / "este profesional". Al principio de una frase:
  /// `capitalizeFirst(space.este)`.
  String get este => '${g('esta', 'este')} $lower';

  /// "Cancha 2". Sin número, solo "Cancha".
  String label(int? identifier) => identifier == null ? singular : '$singular $identifier';
}

class PartitionFeatures {
  const PartitionFeatures({required this.map, required this.cover, required this.capacity});

  /// Se dibuja en el plano del club.
  final bool map;

  /// Sus espacios pueden ser cubiertos / descubiertos.
  final bool cover;

  /// Tiene cupo de personas por turno (mín./máx.).
  final bool capacity;
}

extension PhysicalPartitionVocabulary on PhysicalPartition {
  /// Nombre del espacio: su descripción si tiene ("Lucía", "Cancha central"),
  /// si no el de su modalidad con el número ("Cancha 2", "Sala 1"). Igual que
  /// `spaceName` del backend. [fallback] se usa cuando el espacio no trae su
  /// modalidad anidada.
  String spaceLabel({ClubPartition? fallback}) {
    final own = description?.trim();
    if (own != null && own.isNotEmpty) return own;
    return PartitionVocabulary.of(clubPartition ?? fallback).space.label(physicalIdentifier ?? partitionPhysicalId);
  }
}

/// "esta cancha" -> "Esta cancha".
String capitalizeFirst(String input) =>
    input.isEmpty ? input : '${input[0].toUpperCase()}${input.substring(1)}';

String _lowerFirst(String input) =>
    input.isEmpty ? input : '${input[0].toLowerCase()}${input.substring(1)}';
