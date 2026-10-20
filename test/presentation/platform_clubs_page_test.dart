import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/core/utils/domain_error.dart';
import 'package:turni/core/utils/either.dart';
import 'package:turni/core/utils/repository_response.dart';
import 'package:turni/domain/repositories/platform_repository.dart';
import 'package:turni/presentation/platform/platform_clubs_page.dart';

import '../helpers/logged_admin.dart';

class _FakePlatformRepository implements PlatformRepository {
  _FakePlatformRepository(this.response);

  final RepositoryResponse<CreatedClub> response;
  final calls = <Map<String, String>>[];

  @override
  Future<RepositoryResponse<CreatedClub>> createClub({
    required String clubName,
    required String name,
    String lastName = '',
    required String email,
  }) async {
    calls.add({'club': clubName, 'name': name, 'last_name': lastName, 'email': email});
    return response;
  }
}

void main() {
  Future<_FakePlatformRepository> pumpPage(WidgetTester tester, RepositoryResponse<CreatedClub> response) async {
    registerLoggedAdmin();
    final repository = _FakePlatformRepository(response);
    if (sl.isRegistered<PlatformRepository>()) sl.unregister<PlatformRepository>();
    sl.registerSingleton<PlatformRepository>(repository);

    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: PlatformClubsPage()));
    return repository;
  }

  Future<void> fill(WidgetTester tester, {String email = 'ana@gmail.com'}) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre del establecimiento'), ' Club Norte ');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre del dueño'), 'Ana');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email de Google del dueño'), email);
  }

  testWidgets('valida los obligatorios y el email antes de llamar al back', (tester) async {
    final repository = await pumpPage(tester, Either.right(const CreatedClub(clubId: 5, email: 'ana@gmail.com')));

    await tester.tap(find.text('Dar de alta'));
    await tester.pump();
    expect(find.text('Obligatorio'), findsNWidgets(3));

    await fill(tester, email: 'ana@');
    await tester.tap(find.text('Dar de alta'));
    await tester.pump();
    expect(find.text('Email no válido'), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('da de alta el club y muestra a quién avisarle', (tester) async {
    final repository = await pumpPage(tester, Either.right(const CreatedClub(clubId: 5, email: 'ana@gmail.com')));

    await fill(tester);
    await tester.tap(find.text('Dar de alta'));
    await tester.pumpAndSettle();

    expect(repository.calls.single, {'club': 'Club Norte', 'name': 'Ana', 'last_name': '', 'email': 'ana@gmail.com'});
    expect(find.text('Club Norte quedó dado de alta'), findsOneWidget);
    expect(find.textContaining('ana@gmail.com'), findsOneWidget);

    await tester.tap(find.text('Dar de alta otro'));
    await tester.pumpAndSettle();
    expect(find.text('Alta de establecimiento'), findsOneWidget);
  });

  testWidgets('muestra el error del back', (tester) async {
    await pumpPage(
      tester,
      Either.left(DomainError(message: 'Ya hay un administrador con el email ana@gmail.com.', internalCode: 3001, date: DateTime(2026))),
    );

    await fill(tester);
    await tester.tap(find.text('Dar de alta'));
    await tester.pumpAndSettle();

    expect(find.text('Ya hay un administrador con el email ana@gmail.com.'), findsOneWidget);
    expect(find.text('Alta de establecimiento'), findsOneWidget);
  });
}
