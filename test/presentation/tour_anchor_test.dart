import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turni/core/presentation/components/onboarding/onboarding_tour.dart';
import 'package:turni/core/presentation/components/onboarding/tour_anchor.dart';

void main() {
  /// Dos tabs: "Datos" con el nombre y "Precios" con la tarifa (que solo se
  /// monta al elegir esa tab).
  Future<BuildContext> pumpScreen(WidgetTester tester, {FutureOr<void> Function(BuildContext)? onOpenRow}) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(tabs: [
              TourAnchor(id: 'test.tab.info', onActivate: TourAnchor.selectTab(0), child: const Tab(text: 'Datos')),
              TourAnchor(id: 'test.tab.prices', onActivate: TourAnchor.selectTab(1), child: const Tab(text: 'Precios')),
            ]),
          ),
          body: Builder(builder: (ctx) {
            context = ctx;
            return TabBarView(children: [
              Column(children: [
                const TourAnchor(id: 'test.name', child: SizedBox(width: 100, height: 40, child: Text('Nombre'))),
                TourAnchor(id: 'test.row', onActivate: onOpenRow, child: const SizedBox(width: 100, height: 40, child: Text('Fila'))),
              ]),
              const Column(children: [
                TourAnchor(id: 'test.tariff', child: SizedBox(width: 100, height: 40, child: Text('Tarifa'))),
              ]),
            ]);
          }),
        ),
      ),
    ));
    return context;
  }

  /// El recorrido espera timers y frames entre pasos: hay que avanzar el reloj.
  Future<void> settle(WidgetTester tester, {int frames = 10}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('resalta un anchor por nombre y abre la tab del paso siguiente', (tester) async {
    final context = await pumpScreen(tester);
    OnboardingResult? result;
    final steps = [
      const OnboardingStep(anchor: 'test.name', title: 'Paso nombre', body: 'a'),
      OnboardingStep(anchor: 'test.tariff', before: () => TourAnchors.activate('test.tab.prices'), title: 'Paso tarifa', body: 'b'),
    ];
    OnboardingTour.show(context, id: 'test', steps: steps).then((r) => result = r);
    await settle(tester);
    expect(find.text('Paso nombre'), findsOneWidget);
    expect(TourAnchors.isMounted('test.tariff'), isFalse);

    await tester.tap(find.text('Siguiente'));
    await settle(tester);
    expect(find.text('Paso tarifa'), findsOneWidget);
    expect(DefaultTabController.of(TourAnchors.contextOf('test.tab.prices')!).index, 1);

    await tester.tap(find.text('Listo'));
    await settle(tester);
    expect(result?.completed, isTrue);
    expect(result?.missing(steps), isEmpty);
  });

  testWidgets('informa los pasos obligatorios que no aparecieron, no los opcionales', (tester) async {
    final context = await pumpScreen(tester);
    OnboardingResult? result;
    final steps = [
      const OnboardingStep(anchor: 'test.name', title: 'Paso nombre', body: 'a'),
      const OnboardingStep(anchor: 'test.nothing', optional: true, title: 'Opcional', body: 'b'),
      const OnboardingStep(anchor: 'test.ghost', title: 'Fantasma', body: 'c'),
      const OnboardingStep(anchor: 'test.row', title: 'Paso fila', body: 'd'),
    ];
    OnboardingTour.show(context, id: 'test', steps: steps).then((r) => result = r);
    await settle(tester);

    await tester.tap(find.text('Siguiente'));
    // Espera a cada target que falta antes de saltearlo.
    await settle(tester, frames: 30);
    expect(find.text('Paso fila'), findsOneWidget);

    await tester.tap(find.text('Listo'));
    await settle(tester);
    expect(result?.skipped, [1, 2]);
    expect(result?.missing(steps), [2]);
  });

  testWidgets('activar un anchor que abre una ruta no espera a que se cierre', (tester) async {
    final never = Completer<void>();
    await pumpScreen(tester, onOpenRow: (_) => never.future);
    var activated = false;
    TourAnchors.activate('test.row').then((ok) => activated = ok);
    await settle(tester);
    expect(activated, isTrue);
  });

  test('sin anchor montado, activate devuelve false', () async {
    expect(await TourAnchors.activate('test.none', timeout: Duration.zero), isFalse);
  });
}
