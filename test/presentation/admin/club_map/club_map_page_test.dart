import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/logged_admin.dart';
import 'package:mocktail/mocktail.dart';

import 'package:turni/core/utils/domain_error.dart';
import 'package:turni/core/utils/either.dart';
import 'package:turni/domain/entities/client.dart';
import 'package:turni/domain/entities/club_map/club_map.dart';
import 'package:turni/domain/entities/club_map/court_usage.dart';
import 'package:turni/domain/entities/person.dart';
import 'package:turni/domain/entities/session.dart';
import 'package:turni/domain/repositories/club_map_repository.dart';
import 'package:turni/domain/repositories/session_repository.dart';
import 'package:turni/presentation/admin/club_map/club_map_page.dart';

class _MockRepository extends Mock implements ClubMapRepository {}

class _MockSessionRepository extends Mock implements SessionRepository {}

final _now = DateTime(2026, 10, 5, 19, 30);

Session _session(int id, int courtId, DateTime start, {Client? client}) => Session(
      sessionId: id,
      createdAt: DateTime(2026, 10, 5),
      startTime: start,
      duration: 60,
      price: 1000,
      partitionPhysicalId: courtId,
      clientId: client == null ? null : int.parse(client.clientId!),
      client: client,
    );

Client _client(String id, String name, String lastName) =>
    Client(clientId: id, person: Person(name: name, lastName: lastName, email: null));

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
  late _MockSessionRepository sessionRepository;

  setUpAll(() {
    registerLoggedAdmin();
    registerFallbackValue(const ClubMapLayout(widthM: 10, heightM: 10, elements: []));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = _MockRepository();
    sessionRepository = _MockSessionRepository();
    when(() => sessionRepository.getSessions(any())).thenAnswer((_) async => []);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: ClubMapPage(repository: repository, sessionRepository: sessionRepository, now: () => _now)));
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

  testWidgets('ocupación en vivo: cada cancha libre u ocupada, con el turno en curso y el próximo', (tester) async {
    when(() => repository.getClubMap()).thenAnswer(
      (_) async => const Either.right(ClubMapView(
        map: ClubMapLayout(
          widthM: 80,
          heightM: 50,
          elements: [ClubMapElement(courtId: 31, xM: 1, yM: 1), ClubMapElement(courtId: 32, xM: 1, yM: 20)],
        ),
        partitions: [_padel],
      )),
    );
    when(() => sessionRepository.getSessions(any())).thenAnswer((_) async => [
          _session(1, 31, DateTime(2026, 10, 5, 19), client: _client('7', 'Juan', 'Pérez')),
          _session(2, 31, DateTime(2026, 10, 5, 21), client: _client('8', 'Ana', 'Gómez')),
          _session(3, 32, DateTime(2026, 10, 5, 19)),
        ]);

    await pumpPage(tester);

    verify(() => sessionRepository.getSessions(_now)).called(1);
    expect(find.text('Actualizado 19:30'), findsOneWidget);
    // En el plano (más la referencia de abajo).
    expect(find.text('Ocupada'), findsNWidgets(2));
    expect(find.text('Libre'), findsNWidgets(2));

    await tester.tap(find.text('Padel A'));
    await tester.pumpAndSettle();
    expect(find.text('Juan Pérez · hasta las 20:00'), findsOneWidget);
    expect(find.text('21:00 · Ana Gómez'), findsOneWidget);
    expect(find.text('Abrir el turno en curso'), findsOneWidget);

    await tester.tap(find.text('Padel B'));
    await tester.pumpAndSettle();
    expect(find.text('Turno libre hasta las 20:00'), findsOneWidget);
    expect(find.text('No hay más turnos reservados hoy'), findsOneWidget);
    expect(find.text('Reservar ahora'), findsOneWidget);
  });

  testWidgets('la ocupación se refresca sola', (tester) async {
    when(() => repository.getClubMap()).thenAnswer(
      (_) async => const Either.right(ClubMapView(
        map: ClubMapLayout(widthM: 80, heightM: 50, elements: [ClubMapElement(courtId: 31, xM: 1, yM: 1)]),
        partitions: [_padel],
      )),
    );

    await pumpPage(tester);
    verify(() => sessionRepository.getSessions(any())).called(1);

    await tester.pump(const Duration(minutes: 1));
    verify(() => sessionRepository.getSessions(any())).called(1);
  });

  testWidgets('uso por cancha: pinta el mapa con el % de cada cancha y cambia de período', (tester) async {
    when(() => repository.getClubMap()).thenAnswer(
      (_) async => const Either.right(ClubMapView(
        map: ClubMapLayout(widthM: 80, heightM: 50, elements: [ClubMapElement(courtId: 31, xM: 1, yM: 1), ClubMapElement(courtId: 32, xM: 1, yM: 20)]),
        partitions: [_padel],
      )),
    );
    CourtUsageView usage(double used) => CourtUsageView(
          from: DateTime(2026, 9, 6),
          to: DateTime(2026, 10, 6),
          byCourt: {
            31: CourtUsage(courtId: 31, offeredMinutes: 600, reservedMinutes: (600 * used).round(), usage: used),
            32: const CourtUsage(courtId: 32, offeredMinutes: 0, reservedMinutes: 0),
          },
        );
    when(() => repository.getCourtUsage(days: 30)).thenAnswer((_) async => Either.right(usage(0.75)));
    when(() => repository.getCourtUsage(days: 7)).thenAnswer((_) async => Either.right(usage(0.5)));

    await pumpPage(tester);
    // Arranca en ocupación de ahora: no pide el uso hasta que se elige.
    verifyNever(() => repository.getCourtUsage(days: any(named: 'days')));

    await tester.tap(find.text('Uso por cancha'));
    await tester.pumpAndSettle();
    verify(() => repository.getCourtUsage(days: 30)).called(1);

    expect(find.text('75 %'), findsOneWidget);
    expect(find.text('Sin turnos'), findsNWidgets(2)); // en la cancha y en la referencia
    expect(find.text('Del 06/09 al 05/10'), findsOneWidget);
    // En esta vista no se muestra libre / ocupada.
    expect(find.text('Libre'), findsNothing);

    await tester.tap(find.text('Padel A'));
    await tester.pumpAndSettle();
    expect(find.text('Uso en los últimos 30 días'), findsOneWidget);
    expect(find.text('7,5 h reservadas de 10 h cargadas'), findsOneWidget);

    await tester.tap(find.text('Últimos 7 días'));
    await tester.pumpAndSettle();
    verify(() => repository.getCourtUsage(days: 7)).called(1);
    expect(find.text('50 %'), findsWidgets);
    expect(find.text('Uso en los últimos 7 días'), findsOneWidget);
  });

  testWidgets('editor: cambiar la medida de una cancha y sumar un espacio se guardan', (tester) async {
    const spaceTypes = [
      ClubMapSpaceType(type: 'ENTRANCE', name: 'Entrada', defaultWidthM: 6, defaultHeightM: 3),
      ClubMapSpaceType(type: 'BAR', name: 'Bar', defaultWidthM: 10, defaultHeightM: 8),
    ];
    when(() => repository.getClubMap()).thenAnswer(
      (_) async => const Either.right(ClubMapView(
        map: ClubMapLayout(widthM: 80, heightM: 50, elements: [ClubMapElement(courtId: 41, xM: 1, yM: 1)]),
        partitions: [_futbol],
        spaceTypes: spaceTypes,
      )),
    );
    ClubMapLayout? saved;
    when(() => repository.saveClubMap(any())).thenAnswer((invocation) async {
      saved = invocation.positionalArguments.first as ClubMapLayout;
      return Either.right(ClubMapView(map: saved, partitions: const [_futbol], spaceTypes: spaceTypes));
    });

    await pumpPage(tester);
    await tester.tap(find.text('Editar plano'));
    await tester.pumpAndSettle();

    // Medida propia de la cancha.
    await tester.tap(find.text('Cancha 1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medidas: 36 × 20 m'));
    await tester.pumpAndSettle();
    expect(find.text('Medidas de Cancha 1'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Largo'), '30');
    await tester.enterText(find.widgetWithText(TextFormField, 'Ancho'), '18,5');
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    expect(find.text('Medidas: 30 × 18,5 m (propia)'), findsOneWidget);

    // Un espacio: entra en el primer lugar libre, con el tamaño sugerido.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Bar'));
    await tester.pumpAndSettle();
    expect(find.text('Bar · 10 × 8 m'), findsOneWidget);
    await tester.tap(find.text('Nombre y tamaño'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre (opcional)'), 'Buffet');
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    expect(find.text('Buffet · 10 × 8 m'), findsOneWidget);

    await tester.tap(find.text('Guardar plano'));
    await tester.pumpAndSettle();

    expect(saved!.courtSizes, {41: const CourtSize(lengthM: 30, widthM: 18.5)});
    expect(saved!.spaces.single.type, 'BAR');
    expect(saved!.spaces.single.label, 'Buffet');
    expect((saved!.spaces.single.widthM, saved!.spaces.single.heightM), (10, 8));
    // No se encima con la cancha (30 x 18,5 en 1,1).
    expect(findIssues(const ClubMapView(map: null, partitions: [_futbol]).withCourtSize(41, const CourtSize(lengthM: 30, widthM: 18.5)), saved!.elements, 80, 50, spaces: saved!.spaces).isEmpty, isTrue);
  });

  testWidgets('editor: volver a la medida del deporte manda null', (tester) async {
    const futbolPropia = ClubMapPartition(
      id: 400,
      clubTypeId: 20,
      sport: 'Fútbol',
      courtSize: CourtSize(lengthM: 36, widthM: 20),
      courts: [ClubMapCourt(id: 41, name: 'Cancha 1', isCover: false, maxPlayers: 10, defaultSessionDuration: 60, ownSize: CourtSize(lengthM: 30, widthM: 18))],
    );
    when(() => repository.getClubMap()).thenAnswer(
      (_) async => const Either.right(ClubMapView(
        map: ClubMapLayout(widthM: 80, heightM: 50, elements: [ClubMapElement(courtId: 41, xM: 1, yM: 1)]),
        partitions: [futbolPropia],
      )),
    );
    ClubMapLayout? saved;
    when(() => repository.saveClubMap(any())).thenAnswer((invocation) async {
      saved = invocation.positionalArguments.first as ClubMapLayout;
      return Either.right(ClubMapView(map: saved, partitions: const [_futbol]));
    });

    await pumpPage(tester);
    // En el mapa, el detalle dice que la medida es propia.
    await tester.tap(find.text('Cancha 1'));
    await tester.pumpAndSettle();
    expect(find.text('Medidas (propias)'), findsOneWidget);
    expect(find.text('30 × 18 m'), findsOneWidget);

    await tester.tap(find.text('Editar plano'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancha 1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medidas: 30 × 18 m (propia)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar la del deporte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar plano'));
    await tester.pumpAndSettle();

    expect(saved!.courtSizes, {41: null});
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
