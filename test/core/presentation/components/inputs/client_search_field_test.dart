import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/presentation/components/inputs/client_search_field.dart';
import 'package:turni/core/utils/domain_error.dart';
import 'package:turni/core/utils/either.dart';
import 'package:turni/domain/entities/client.dart';
import 'package:turni/domain/entities/person.dart';
import 'package:turni/domain/entities/request/page_response.dart';
import 'package:turni/domain/repositories/admin_repository.dart';

Client _client(int id, String name, String lastName, {String? phone}) =>
    Client(clientId: '$id', person: Person(name: name, lastName: lastName, email: null, phone: phone));

final _clients = [
  _client(1, 'Lucía', 'Fernández', phone: '11 5523-8841'),
  _client(2, 'Lucas', 'Pereyra'),
  _client(3, 'Martín', 'Gómez'),
  _client(4, 'Julieta', 'Romero'),
  _client(5, 'Juan Pablo', 'Ortiz'),
];

class _FakeAdminRepo implements AdminRepository {
  final queries = <String>[];

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();

  @override
  Future<Either<DomainError, PageResponse<Client>>> getClients(String search, [int? page, String? sortKey, bool? isAscending]) async {
    queries.add(search);
    final q = search.toLowerCase().replaceAll('í', 'i');
    final found = _clients.where((c) => c.person!.fullName.toLowerCase().replaceAll('í', 'i').contains(q)).toList();
    return Either.right(PageResponse(found.length, found));
  }
}

Widget _app(Widget child) => MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xff672bea), brightness: Brightness.dark),
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(24), child: Align(alignment: Alignment.topLeft, child: SizedBox(width: 520, child: child)))),
    );

void main() {
  late _FakeAdminRepo repo;

  setUp(() async {
    await sl.reset();
    repo = _FakeAdminRepo();
    sl.registerSingleton<AdminRepository>(repo);
  });

  testWidgets('uno: recientes, busca con debounce, resalta y elige', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Client? picked;
    await tester.pumpWidget(_app(StatefulBuilder(
      builder: (context, setState) => ClientSearchField(
        label: 'Cliente',
        value: picked,
        onChanged: (c) => setState(() => picked = c),
      ),
    )));

    final height = tester.getSize(find.byType(ClientSearchField)).height;
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('RECIENTES'), findsOneWidget);
    expect(find.text('Crear cliente nuevo'), findsOneWidget);
    expect(repo.queries, ['']);

    await tester.enterText(find.byType(TextField), 'luc');
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.queries, [''], reason: 'espera 300 ms después de la última tecla');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(repo.queries, ['', 'luc']);
    expect(find.text('RESULTADOS · 2'), findsOneWidget);
    expect(find.text('Crear cliente “luc”'), findsOneWidget);

    await tester.tap(find.textContaining('Pereyra', findRichText: true));
    await tester.pumpAndSettle();
    expect(picked?.clientId, '2');
    expect(find.text('RESULTADOS · 2'), findsNothing, reason: 'elegir cierra la lista');
    expect(find.textContaining('Lucas Pereyra', findRichText: true), findsOneWidget);
    expect(tester.getSize(find.byType(ClientSearchField)).height, height, reason: 'no cambia de alto al elegir');

    await tester.tap(find.byTooltip('Quitar cliente'));
    await tester.pumpAndSettle();
    expect(picked, isNull);
  });

  testWidgets('uno: Enter elige el activo; sin resultados ofrece crear', (tester) async {
    Client? picked;
    String? created;
    await tester.pumpWidget(_app(StatefulBuilder(
      builder: (context, setState) => ClientSearchField(
        value: picked,
        onChanged: (c) => setState(() => picked = c),
        onCreate: (q) async {
          created = q;
          return _client(9, 'Agustina', 'Bel');
        },
      ),
    )));

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'luc');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked?.clientId, '2', reason: 'flecha abajo pasa al segundo resultado');

    await tester.tap(find.byTooltip('Quitar cliente'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Agustina Bel');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('No hay clientes con “Agustina Bel”'), findsOneWidget);

    await tester.tap(find.text('Crear cliente “Agustina Bel”'));
    await tester.pumpAndSettle();
    expect(created, 'Agustina Bel');
    expect(picked?.clientId, '9');
  });

  testWidgets('varios: elegir no cierra, marca "Ya está" y backspace saca el último', (tester) async {
    var values = <Client>[];
    await tester.pumpWidget(_app(StatefulBuilder(
      builder: (context, setState) => ClientSearchField.multiple(
        label: 'Integrantes',
        values: values,
        max: 4,
        rowInfo: (c) => c.clientId == '3' ? const ClientRowInfo('Tiene otro fijo a esa hora', disabled: true) : null,
        onValuesChanged: (v) => setState(() => values = v),
      ),
    )));

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Julieta', findRichText: true));
    await tester.pumpAndSettle();
    expect(values.map((c) => c.clientId), ['4']);
    expect(find.text('1 de 4'), findsOneWidget);
    expect(find.text('RECIENTES'), findsOneWidget, reason: 'la lista sigue abierta');
    expect(find.text('Ya está'), findsOneWidget);

    // Deshabilitado: no se puede elegir.
    await tester.tap(find.textContaining('Gómez', findRichText: true).last);
    await tester.pumpAndSettle();
    expect(values.map((c) => c.clientId), ['4']);

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    expect(values, isEmpty);
  });

  testWidgets('al pie de la pantalla la lista se abre arriba, entera', (tester) async {
    tester.view.physicalSize = const Size(800, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(width: 520, child: ClientSearchField(value: null, onChanged: (_) {})),
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byType(TextField));
    final list = tester.getRect(find.ancestor(of: find.text('RECIENTES'), matching: find.byType(Material)).first);
    expect(list.bottom, lessThanOrEqualTo(field.top));
    expect(list.top, greaterThanOrEqualTo(0));
  });

  test('splitClientQuery reparte lo escrito', () {
    expect(splitClientQuery('Agus'), (name: 'Agus', lastName: '', phone: '', email: ''));
    expect(splitClientQuery(' Juan  Pablo Ortiz '), (name: 'Juan', lastName: 'Pablo Ortiz', phone: '', email: ''));
    expect(splitClientQuery('11 4410-2290'), (name: '', lastName: '', phone: '1144102290', email: ''));
    expect(splitClientQuery('a@b.com'), (name: '', lastName: '', phone: '', email: 'a@b.com'));
  });
}
