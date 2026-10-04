import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:turni/core/utils/domain_error.dart';
import 'package:turni/core/utils/either.dart';
import 'package:turni/domain/entities/payment/club_payment_account_status.dart';
import 'package:turni/domain/repositories/club_payment_account_repository.dart';
import 'package:turni/presentation/admin/settings_screen/widgets/mercado_pago_account_card.dart';

class _MockRepository extends Mock implements ClubPaymentAccountRepository {}

const _authUrl = 'https://auth.mercadopago.com/authorization?client_id=1&state=abc';

final _active = ClubPaymentAccountStatus(
  state: ClubPaymentAccountState.active,
  providerUserId: '44444',
  liveMode: false,
  expiresAt: DateTime(2027, 4, 1),
);

DomainError _error(String message) => DomainError(message: message, internalCode: 1100, date: DateTime(2026));

void main() {
  late _MockRepository repository;
  late List<Uri> launched;
  late bool launchResult;

  setUp(() {
    repository = _MockRepository();
    launched = [];
    launchResult = true;
  });

  Future<void> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MercadoPagoAccountCard(
            repository: repository,
            launcher: (url) async {
              launched.add(url);
              return launchResult;
            },
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('sin cuenta: muestra "Sin cuenta vinculada" y el botón para vincular', (tester) async {
    when(() => repository.getMercadoPagoStatus()).thenAnswer((_) async => const Either.right(ClubPaymentAccountStatus.notLinked()));

    await pumpCard(tester);

    expect(find.text('Sin cuenta vinculada'), findsOneWidget);
    expect(find.text('Vincular Mercado Pago'), findsOneWidget);
  });

  testWidgets('vincular: pide la URL, la abre y queda esperando la autorización', (tester) async {
    when(() => repository.getMercadoPagoStatus()).thenAnswer((_) async => const Either.right(ClubPaymentAccountStatus.notLinked()));
    when(() => repository.startMercadoPagoLink()).thenAnswer((_) async => const Either.right(_authUrl));

    await pumpCard(tester);
    await tester.tap(find.text('Vincular Mercado Pago'));
    await tester.pumpAndSettle();

    expect(launched, [Uri.parse(_authUrl)]);
    expect(find.text('Esperando la autorización'), findsOneWidget);

    // El admin autoriza en la otra pestaña y toca "actualizar".
    when(() => repository.getMercadoPagoStatus()).thenAnswer((_) async => Either.right(_active));
    await tester.tap(find.text('Ya autoricé, actualizar'));
    await tester.pumpAndSettle();

    expect(find.text('Cuenta vinculada'), findsOneWidget);
    expect(find.text('Esperando la autorización'), findsNothing);
  });

  testWidgets('al volver a la pestaña (resumed) refresca el estado solo', (tester) async {
    when(() => repository.getMercadoPagoStatus()).thenAnswer((_) async => const Either.right(ClubPaymentAccountStatus.notLinked()));
    when(() => repository.startMercadoPagoLink()).thenAnswer((_) async => const Either.right(_authUrl));

    await pumpCard(tester);
    await tester.tap(find.text('Vincular Mercado Pago'));
    await tester.pumpAndSettle();

    when(() => repository.getMercadoPagoStatus()).thenAnswer((_) async => Either.right(_active));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Cuenta vinculada'), findsOneWidget);
  });

  testWidgets('si el navegador bloquea la ventana, lo avisa y no queda esperando', (tester) async {
    launchResult = false;
    when(() => repository.getMercadoPagoStatus()).thenAnswer((_) async => const Either.right(ClubPaymentAccountStatus.notLinked()));
    when(() => repository.startMercadoPagoLink()).thenAnswer((_) async => const Either.right(_authUrl));

    await pumpCard(tester);
    await tester.tap(find.text('Vincular Mercado Pago'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo abrir Mercado Pago'), findsOneWidget);
    expect(find.text('Esperando la autorización'), findsNothing);
  });

  testWidgets('muestra el error del backend al iniciar el vínculo (ej. pagos no configurados)', (tester) async {
    when(() => repository.getMercadoPagoStatus()).thenAnswer((_) async => const Either.right(ClubPaymentAccountStatus.notLinked()));
    when(() => repository.startMercadoPagoLink())
        .thenAnswer((_) async => Either.left(_error('Pagos online no configurados en el servidor.')));

    await pumpCard(tester);
    await tester.tap(find.text('Vincular Mercado Pago'));
    await tester.pumpAndSettle();

    expect(find.text('Pagos online no configurados en el servidor.'), findsOneWidget);
    expect(launched, isEmpty);
  });

  testWidgets('vinculada: muestra usuario, modo prueba y vencimiento', (tester) async {
    when(() => repository.getMercadoPagoStatus()).thenAnswer((_) async => Either.right(_active));

    await pumpCard(tester);

    expect(find.text('Cuenta vinculada'), findsOneWidget);
    expect(find.textContaining('Usuario de Mercado Pago: 44444'), findsOneWidget);
    expect(find.textContaining('Modo prueba'), findsOneWidget);
    expect(find.textContaining('01/04/2027'), findsOneWidget);
  });

  testWidgets('desvincular pide confirmación y, si se confirma, desvincula', (tester) async {
    when(() => repository.getMercadoPagoStatus()).thenAnswer((_) async => Either.right(_active));
    when(() => repository.unlinkMercadoPago()).thenAnswer((_) async => const Either.right(null));

    await pumpCard(tester);

    // Cancelar no desvincula.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Desvincular'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    verifyNever(() => repository.unlinkMercadoPago());

    // Confirmar sí.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Desvincular'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Desvincular'));
    await tester.pumpAndSettle();

    verify(() => repository.unlinkMercadoPago()).called(1);
    expect(find.text('Sin cuenta vinculada'), findsOneWidget);
  });

  testWidgets('refresh fallido: pide volver a vincular', (tester) async {
    when(() => repository.getMercadoPagoStatus()).thenAnswer(
      (_) async => const Either.right(ClubPaymentAccountStatus(state: ClubPaymentAccountState.refreshFailed)),
    );

    await pumpCard(tester);

    expect(find.text('Hay que volver a vincular la cuenta'), findsOneWidget);
    expect(find.text('Volver a vincular'), findsOneWidget);
  });

  testWidgets('si falla la carga inicial, muestra el error y permite reintentar', (tester) async {
    when(() => repository.getMercadoPagoStatus()).thenAnswer((_) async => Either.left(_error('Sin conexión')));

    await pumpCard(tester);

    expect(find.text('Sin conexión'), findsOneWidget);

    when(() => repository.getMercadoPagoStatus()).thenAnswer((_) async => Either.right(_active));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Cuenta vinculada'), findsOneWidget);
  });

  group('ClubPaymentAccountStatus.fromJson', () {
    test('mapea los estados del backend', () {
      expect(ClubPaymentAccountStatus.fromJson({'status': 'ACTIVE'}).state, ClubPaymentAccountState.active);
      expect(ClubPaymentAccountStatus.fromJson({'status': 'REFRESH_FAILED'}).state, ClubPaymentAccountState.refreshFailed);
      expect(ClubPaymentAccountStatus.fromJson({'status': 'REVOKED'}).state, ClubPaymentAccountState.notLinked);
      expect(ClubPaymentAccountStatus.fromJson({'status': null}).state, ClubPaymentAccountState.notLinked);
    });

    test('parsea usuario, modo y vencimiento', () {
      final status = ClubPaymentAccountStatus.fromJson({
        'linked': true,
        'status': 'ACTIVE',
        'providerUserId': '44444',
        'liveMode': false,
        'expiresAt': '2027-04-01T12:00:00.000Z',
      });

      expect(status.providerUserId, '44444');
      expect(status.liveMode, false);
      expect(status.expiresAt?.toUtc(), DateTime.utc(2027, 4, 1, 12));
    });
  });

  group('DomainError.fromErrorResponse', () {
    test('conserva el mensaje del backend aunque no venga un code numérico', () {
      final error = DomainError.fromErrorResponse({'error': 'Pagos online no configurados en el servidor.'});
      expect(error.message, 'Pagos online no configurados en el servidor.');
      expect(error.internalCode, DomainError.unknwonError);

      final withTextCode = DomainError.fromErrorResponse({'error': 'Club sin cuenta', 'code': 'CLUB_ACCOUNT_NOT_LINKED'});
      expect(withTextCode.message, 'Club sin cuenta');
      expect(withTextCode.details, {'code': 'CLUB_ACCOUNT_NOT_LINKED'});
    });

    test('mantiene el code numérico cuando viene', () {
      final error = DomainError.fromErrorResponse({'error': 'User not admin', 'code': 2002});
      expect(error.internalCode, 2002);
    });
  });
}
