import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    dotenv.loadFromString(envString: 'ADMIN_WEB_URL=https://panel.example.com');
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

  testWidgets('da de alta el club y arma el mail de invitación', (tester) async {
    final repository = await pumpPage(tester, Either.right(const CreatedClub(clubId: 5, email: 'ana@gmail.com')));

    await fill(tester);
    await tester.tap(find.text('Dar de alta'));
    await tester.pumpAndSettle();

    expect(repository.calls.single, {'club': 'Club Norte', 'name': 'Ana', 'last_name': '', 'email': 'ana@gmail.com'});
    expect(find.text('Club Norte quedó dado de alta'), findsOneWidget);
    expect(find.textContaining('ana@gmail.com'), findsOneWidget);

    expect(find.text('Enviar invitación'), findsOneWidget);

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.tap(find.text('Copiar el mail'));
    await tester.pump();
    expect(copied, startsWith('Para: ana@gmail.com\nAsunto: Tu acceso a Turni para Club Norte'));
    expect(copied, contains('Hola Ana:'));
    expect(copied, contains('entrá a https://panel.example.com/ y tocá'));
    expect(find.text('Mail copiado'), findsOneWidget);

    await tester.tap(find.text('Dar de alta otro'));
    await tester.pumpAndSettle();
    expect(find.text('Alta de establecimiento'), findsOneWidget);
  });

  testWidgets('si el back ya mandó la invitación, lo dice y ofrece reenviarla', (tester) async {
    await pumpPage(tester, Either.right(const CreatedClub(clubId: 5, email: 'ana@gmail.com', inviteSent: true)));

    await fill(tester);
    await tester.tap(find.text('Dar de alta'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Le mandamos la invitación a ana@gmail.com'), findsOneWidget);
    expect(find.text('Reenviar por mail'), findsOneWidget);
    expect(find.text('Enviar invitación'), findsNothing);
  });

  test('CreatedClub lee invite.sent de la respuesta', () {
    expect(CreatedClub.fromJson({'club_id': 5, 'email': 'a@b.com', 'invite': {'sent': true}}).inviteSent, isTrue);
    expect(CreatedClub.fromJson({'club_id': 5, 'email': 'a@b.com', 'invite': {'sent': false}}).inviteSent, isFalse);
    expect(CreatedClub.fromJson({'club_id': 5, 'email': 'a@b.com'}).inviteSent, isFalse);
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
