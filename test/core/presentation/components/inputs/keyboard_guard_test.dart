import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turni/core/presentation/components/inputs/keyboard_guard.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(24), child: child)));

bool _focused(WidgetTester tester, Finder field) =>
    tester.widget<EditableText>(find.descendant(of: field, matching: find.byType(EditableText))).focusNode.hasFocus;

void main() {
  setUp(KeyboardGuard.install);

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('celular: un autofocus suelto no abre el teclado', (tester) async {
    phone(tester);
    await tester.pumpWidget(_app(const TextField(autofocus: true)));
    await tester.pump();
    expect(_focused(tester, find.byType(TextField)), isFalse);
  });

  testWidgets('celular: un flujo de búsqueda sí abre el teclado', (tester) async {
    phone(tester);
    await tester.pumpWidget(_app(const AllowAutoKeyboard(child: TextField(autofocus: true))));
    await tester.pump();
    expect(_focused(tester, find.byType(TextField)), isTrue);
  });

  testWidgets('celular: tocar el campo lo enfoca; el foco por código no', (tester) async {
    phone(tester);
    final other = FocusNode();
    addTearDown(other.dispose);
    await tester.pumpWidget(_app(Column(children: [
      const TextField(key: ValueKey('a')),
      const SizedBox(height: 200),
      TextField(key: const ValueKey('b'), focusNode: other),
      const SizedBox(height: 40),
      ElevatedButton(onPressed: other.requestFocus, child: const Text('Enfocar')),
    ])));

    await tester.tap(find.byKey(const ValueKey('a')));
    await tester.pump();
    expect(_focused(tester, find.byKey(const ValueKey('a'))), isTrue);

    await tester.tap(find.text('Enfocar'));
    await tester.pump();
    expect(other.hasFocus, isFalse, reason: 'el toque fue en el botón, no en el campo');
  });

  testWidgets('escritorio: el autofocus funciona como siempre', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const TextField(autofocus: true)));
    await tester.pump();
    expect(_focused(tester, find.byType(TextField)), isTrue);
  });
}
