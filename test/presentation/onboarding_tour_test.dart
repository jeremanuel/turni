import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turni/core/presentation/components/onboarding/onboarding_tour.dart';

void main() {
  final first = GlobalKey();
  final second = GlobalKey();
  final missing = GlobalKey();

  Future<BuildContext> pumpScreen(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (ctx) {
          context = ctx;
          return Column(children: [
            SizedBox(key: first, width: 100, height: 40, child: const Text('Nombre')),
            SizedBox(key: second, width: 100, height: 40, child: const Text('Dirección')),
          ]);
        }),
      ),
    ));
    return context;
  }

  /// El recorrido espera timers y frames entre pasos: hay que avanzar el reloj.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  List<OnboardingStep> steps() => [
        OnboardingStep(target: first, title: 'Paso nombre', body: 'a'),
        // Sin montar (ej. una tab que en el celular no existe): se saltea.
        OnboardingStep(target: missing, title: 'Paso fantasma', body: 'b'),
        OnboardingStep(target: second, title: 'Paso dirección', body: 'c'),
      ];

  testWidgets('recorre los pasos, saltea los que no están montados y termina con Listo', (tester) async {
    final context = await pumpScreen(tester);
    var done = false;
    OnboardingTour.show(context, id: 'test', steps: steps()).then((_) => done = true);
    await settle(tester);

    expect(find.text('Paso nombre'), findsOneWidget);
    expect(find.text('Paso 1 de 3'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await settle(tester);
    expect(find.text('Paso fantasma'), findsNothing);
    expect(find.text('Paso dirección'), findsOneWidget);

    await tester.tap(find.text('Atrás'));
    await settle(tester);
    expect(find.text('Paso nombre'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await settle(tester);
    await tester.tap(find.text('Listo'));
    await settle(tester);

    expect(find.text('Paso dirección'), findsNothing);
    expect(done, isTrue);
  });

  testWidgets('Saltear cierra el recorrido', (tester) async {
    final context = await pumpScreen(tester);
    var done = false;
    OnboardingTour.show(context, id: 'test', steps: steps()).then((_) => done = true);
    await settle(tester);

    await tester.tap(find.text('Saltear'));
    await settle(tester);

    expect(find.text('Paso nombre'), findsNothing);
    expect(done, isTrue);
  });
}
