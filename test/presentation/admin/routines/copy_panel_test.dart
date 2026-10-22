import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turni/domain/entities/gym/gym.dart';
import 'package:turni/presentation/admin/routines/routine_draft.dart';
import 'package:turni/presentation/admin/routines/widgets/copy_panel.dart';

Routine _routine(String id, String group, {String? clientName, DateTime? end}) => Routine(
      id: id,
      startDate: DateTime(2026, 9, 1),
      endDate: end,
      createdAt: DateTime(2026, 9, 1),
      clientName: clientName,
      groups: [
        RoutineGroup(id: 1, name: group, exercises: const [
          RoutineExercise(id: 1, exerciseId: 1, name: 'Press de banca', muscles: ['Pecho'], series: [Serie(reps: 8, weightKg: 60)]),
        ]),
      ],
    );

void main() {
  Future<RoutineDraft> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final draft = RoutineDraft.empty(1);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CopyPanel(
          draft: draft,
          clientName: 'Mai Vera',
          clientRoutines: [_routine('r1', 'Empuje')],
          recentRoutines: [_routine('r2', 'Full body', clientName: 'Flor Sanz')],
        ),
      ),
    ));
    return draft;
  }

  testWidgets('cambia entre las rutinas del cliente y las últimas del admin', (tester) async {
    await pump(tester);
    expect(find.text('Empuje'), findsOneWidget);
    await tester.tap(find.text('Tus últimas rutinas'));
    await tester.pumpAndSettle();
    expect(find.text('Flor Sanz'), findsOneWidget);
    expect(find.text('Empuje'), findsNothing);
  });

  testWidgets('copiar un ejercicio lo agrega al grupo destino y marca el botón', (tester) async {
    final draft = await pump(tester);
    await tester.tap(find.byTooltip('Agregar Press de banca a Full body'));
    await tester.pump();
    expect(draft.groups.first.exercises.map((e) => e.name), ['Press de banca']);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('copiar un grupo lo suma como grupo nuevo', (tester) async {
    final draft = await pump(tester);
    await tester.tap(find.text('Copiar grupo'));
    await tester.pump();
    expect(draft.groups.map((g) => g.name), ['Full body', 'Empuje']);
    expect(find.text('Copiado'), findsOneWidget);
  });
}
