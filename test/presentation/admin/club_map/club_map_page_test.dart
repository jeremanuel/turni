import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:turni/core/utils/domain_error.dart';
import 'package:turni/core/utils/either.dart';
import 'package:turni/domain/entities/club_map/club_map.dart';
import 'package:turni/domain/repositories/club_map_repository.dart';
import 'package:turni/presentation/admin/club_map/club_map_page.dart';

class _MockRepository extends Mock implements ClubMapRepository {}

const _padel = ClubMapPartition(
  id: 300,
  clubTypeId: 10,
  sport: 'Pádel',
  courtSize: CourtSize(lengthM: 20, widthM: 10),
  courts: [
    ClubMapCourt(id: 31, name: 'Padel A', isCover: true, maxPlayers: 4, defaultSessionDuration: 90),
    ClubMapCourt(id: 32, name: 'Padel B', isCover: false, maxPlayers: 4, defaultSessionDuration: 90),
  ],
);

const _futbol = ClubMapPartition(
  id: 400,
  clubTypeId: 20,
  sport: 'Fútbol',
  courtSize: CourtSize(lengthM: 36, widthM: 20),
  courts: [ClubMapCourt(id: 41, name: 'Cancha 1', isCover: false, maxPlayers: 10, defaultSessionDuration: 60)],
);

void main() {
  late _MockRepository repository;

  setUpAll(() {
    registerFallbackValue(const ClubMapLayout(widthM: 10, heightM: 10, elements: []));
  });

  setUp(() {
    repository = _MockRepository();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: ClubMapPage(repository: repository)));
    await tester.pumpAndSettle();
  }

  testWidgets('sin plano: elegir deportes y tamaño, sumar canchas y guardar', (tester) async {
    when(() => repository.getClubMap()).thenAnswer(
      (_) async => const Either.right(ClubMapView(map: null, partitions: [_padel, _futbol])),
    );
    ClubMapLayout? saved;
    when(() => repository.saveClubMap(any())).thenAnswer((invocation) async {
      saved = invocation.positionalArguments.first as ClubMapLayout;
      return Either.right(ClubMapView(map: saved, partitions: const [_padel, _futbol]));
    });

    await pumpPage(tester);
    expect(find.text('El club todavía no tiene plano'), findsOneWidget);

    await tester.tap(find.text('Diseñar el plano'));
    await tester.pumpAndSettle();

    // Paso 1: sin deporte elegido no se puede seguir.
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continuar')).onPressed, isNull);
    await tester.tap(find.text('Pádel'));
    await tester.tap(find.text('Chico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Paso 2: solo pádel en la lista, y se puede sumar fútbol después.
    expect(find.text('Plano del club'), findsOneWidget);
    expect(find.text('Sumar Fútbol al plano'), findsOneWidget);
    expect(find.text('0 de 2 en el plano'), findsOneWidget);

    await tester.tap(find.text('Padel A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Padel B').first);
    await tester.pumpAndSettle();
    expect(find.text('2 de 2 en el plano'), findsOneWidget);

    await tester.tap(find.text('Guardar plano'));
    await tester.pumpAndSettle();

    expect(saved!.widthM, 40);
    expect(saved!.heightM, 30);
    expect(saved!.elements.map((e) => e.courtId), [31, 32]);
    // Se ubicaron sin encimarse.
    expect(findIssues(const ClubMapView(map: null, partitions: [_padel, _futbol]), saved!.elements, 40, 30).isEmpty, isTrue);

    expect(find.text('Plano del club guardado'), findsOneWidget);
    expect(find.text('Mapa del club'), findsOneWidget);
    expect(find.text('Fútbol todavía no está en el plano.'), findsOneWidget);
  });

  testWidgets('con plano: el deporte que ya está aparece tildado y bloqueado', (tester) async {
    when(() => repository.getClubMap()).thenAnswer(
      (_) async => const Either.right(ClubMapView(
        map: ClubMapLayout(widthM: 80, heightM: 50, elements: [ClubMapElement(courtId: 31, xM: 1, yM: 1)]),
        partitions: [_padel, _futbol],
      )),
    );

    await pumpPage(tester);
    await tester.tap(find.text('Sumar al plano'));
    await tester.pumpAndSettle();

    expect(find.text('Ya está en el plano'), findsOneWidget);
    final padelTile = tester.widget<CheckboxListTile>(find.ancestor(of: find.text('Pádel'), matching: find.byType(CheckboxListTile)));
    expect(padelTile.value, isTrue);
    expect(padelTile.onChanged, isNull);
    // Ya hay plano: no se pregunta el tamaño.
    expect(find.text('¿Qué tamaño tiene el predio?'), findsNothing);
    // Fútbol es el único que falta: viene tildado.
    final futbolTile = tester.widget<CheckboxListTile>(find.ancestor(of: find.text('Fútbol'), matching: find.byType(CheckboxListTile)));
    expect(futbolTile.value, isTrue);
  });

  testWidgets('tocar una cancha del mapa muestra sus datos', (tester) async {
    when(() => repository.getClubMap()).thenAnswer(
      (_) async => const Either.right(ClubMapView(
        map: ClubMapLayout(widthM: 80, heightM: 50, elements: [ClubMapElement(courtId: 31, xM: 1, yM: 1)]),
        partitions: [_padel],
      )),
    );

    await pumpPage(tester);
    expect(find.text('Tocá una cancha del plano para ver sus datos.'), findsOneWidget);

    await tester.tap(find.text('Padel A'));
    await tester.pumpAndSettle();

    expect(find.text('PÁDEL'), findsOneWidget);
    expect(find.text('Techada'), findsWidgets);
    expect(find.text('90 min'), findsOneWidget);
    expect(find.text('20 × 10 m'), findsOneWidget);
  });

  testWidgets('si el backend rechaza el plano, se muestra su mensaje y se queda en el editor', (tester) async {
    when(() => repository.getClubMap()).thenAnswer(
      (_) async => const Either.right(ClubMapView(
        map: ClubMapLayout(widthM: 80, heightM: 50, elements: [ClubMapElement(courtId: 31, xM: 1, yM: 1)]),
        partitions: [_padel],
      )),
    );
    when(() => repository.saveClubMap(any())).thenAnswer(
      (_) async => Either.left(DomainError(message: 'Padel A (Pádel) queda afuera del predio.', internalCode: 1, date: DateTime(2026))),
    );

    await pumpPage(tester);
    await tester.tap(find.text('Editar plano'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar plano'));
    await tester.pumpAndSettle();

    expect(find.text('Padel A (Pádel) queda afuera del predio.'), findsOneWidget);
    expect(find.text('Plano del club'), findsOneWidget);
  });

  testWidgets('error al cargar: permite reintentar', (tester) async {
    var calls = 0;
    when(() => repository.getClubMap()).thenAnswer((_) async {
      calls++;
      if (calls == 1) return Either.left(DomainError(message: 'Sin conexión', internalCode: 1, date: DateTime(2026)));
      return const Either.right(ClubMapView(map: null, partitions: [_padel]));
    });

    await pumpPage(tester);
    expect(find.text('No se pudo cargar el mapa del club.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('El club todavía no tiene plano'), findsOneWidget);
  });
}
