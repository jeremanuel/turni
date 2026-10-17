import 'package:flutter_test/flutter_test.dart';
import 'package:turni/domain/entities/club_partition.dart';
import 'package:turni/domain/entities/club_type.dart';
import 'package:turni/domain/entities/partition_vocabulary.dart';
import 'package:turni/domain/entities/physical_partition.dart';

ClubType _personal() => ClubType(
      clubTypeId: 80,
      name: 'Peluquería',
      category: 'PERSONAL',
      spaceSingular: 'Profesional',
      spacePlural: 'Profesionales',
      spaceGender: 'm',
      participantSingular: 'Cliente',
      participantPlural: 'Clientes',
      usesMap: false,
      usesCover: false,
      usesCapacity: false,
    );

ClubPartition _partition({ClubType? type, String? name, PartitionVocabulary? vocabulary}) => ClubPartition(
      club_partition_id: 1,
      club_id: 1,
      club_type_id: type?.clubTypeId ?? 10,
      clubType: type,
      physicalPartitionName: name,
      vocabulary: vocabulary,
    );

void main() {
  group('PartitionVocabulary.of', () {
    test('sin modalidad o sin datos del tipo: cancha', () {
      expect(PartitionVocabulary.of(null).space.singular, 'Cancha');
      expect(PartitionVocabulary.of(_partition()).participant.plural, 'Jugadores');
    });

    test('usa el vocabulario del tipo', () {
      final v = PartitionVocabulary.of(_partition(type: _personal()));
      expect(v.space.nuevo, 'Nuevo profesional');
      expect(v.space.todos, 'Todos los profesionales');
      expect(v.participant.count(1), '1 cliente');
      expect(v.features.map, isFalse);
    });

    test('el nombre de la modalidad pisa al del tipo', () {
      final v = PartitionVocabulary.of(_partition(type: _personal(), name: 'sillón'));
      expect(v.space.singular, 'Sillón');
      expect(v.space.plural, 'Sillones');
      expect(v.space.definite, 'el sillón');
    });

    test('nombres compuestos: plural y género del sustantivo principal', () {
      final v = PartitionVocabulary.of(_partition(name: 'Cancha de pádel'));
      expect(v.space.plural, 'Canchas de pádel');
      expect(v.space.nuevo, 'Nueva cancha de pádel');
    });

    test('prefiere el vocabulario que manda el backend', () {
      final v = PartitionVocabulary.of(_partition(name: 'Cancha', vocabulary: PartitionVocabulary.generic));
      expect(v.space.singular, 'Espacio');
    });

    test('lee el JSON del backend', () {
      final v = PartitionVocabulary.fromJson({
        'category': 'CLASS',
        'space': {'singular': 'Sala', 'plural': 'Salas', 'gender': 'f'},
        'participant': {'singular': 'Alumno', 'plural': 'Alumnos'},
        'features': {'map': true, 'cover': false, 'capacity': true},
      });
      expect(v.space.indefinite, 'una sala');
      expect(v.features.cover, isFalse);
    });
  });

  group('PartitionVocabulary.common', () {
    test('si todas se llaman igual usa ese nombre', () {
      final v = PartitionVocabulary.common([_partition(), _partition()]);
      expect(v.space.todos, 'Todas las canchas');
    });

    test('si se mezclan nombres usa el neutro y prende las funciones de cualquiera', () {
      final v = PartitionVocabulary.common([_partition(), _partition(type: _personal())]);
      expect(v.space.todos, 'Todos los espacios');
      expect(v.participant.plural, 'Personas');
      expect(v.features.cover, isTrue);
    });
  });

  test('spaceLabel numera con el nombre de su modalidad', () {
    final court = PhysicalPartition(
      partitionPhysicalId: 7,
      clubPartitionId: 1,
      minPlayers: 1,
      maxPlayers: 1,
      physicalIdentifier: 2,
      isCover: null,
      description: null,
    );
    expect(court.spaceLabel(fallback: _partition(type: _personal())), 'Profesional 2');
    expect(court.spaceLabel(), 'Cancha 2');
    expect(court.copyWith(description: 'Lucía').spaceLabel(), 'Lucía');
  });

  group('displayName', () {
    test('el nombre propio del servicio, si no el de su tipo', () {
      final type = _personal();
      expect(_partition(type: type).copyWith(name: 'Barbería centro').displayName, 'Barbería centro');
      expect(_partition(type: type).copyWith(name: '  ').displayName, 'Peluquería');
      expect(_partition().displayName, 'Servicio');
    });

    test('no depende del nombre de los espacios', () {
      expect(_partition(type: _personal(), name: 'Sillón').displayName, 'Peluquería');
    });
  });
}
