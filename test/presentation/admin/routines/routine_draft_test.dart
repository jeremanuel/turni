import 'package:flutter_test/flutter_test.dart';
import 'package:turni/domain/entities/gym/gym.dart';
import 'package:turni/presentation/admin/routines/routine_draft.dart';

RoutineExercise _exercise(int id, String name, {List<Serie>? series}) => RoutineExercise(
      id: id,
      exerciseId: id * 10,
      name: name,
      muscles: const ['Pecho'],
      series: series ?? const [Serie(reps: 8, weightKg: 60)],
    );

Routine _routine() => Routine(
      id: 'r1',
      startDate: DateTime(2026, 9, 1),
      createdAt: DateTime(2026, 9, 1),
      groups: [
        RoutineGroup(id: 10, name: 'Empuje', exercises: [_exercise(100, 'Press de banca'), _exercise(101, 'Press militar')]),
        RoutineGroup(id: 11, name: 'Piernas', exercises: [_exercise(102, 'Sentadilla')]),
      ],
    );

void main() {
  group('RoutineDraft', () {
    test('copiar una rutina no conserva ids (es una rutina nueva)', () {
      final draft = RoutineDraft.copyOf(_routine());
      final json = draft.toJson();
      final groups = json['groups'] as List;
      expect(draft.routineId, isNull);
      expect((groups.first as Map).containsKey('routine_group_id'), isFalse);
      expect(((groups.first as Map)['exercises'] as List).first, isNot(contains('routine_exercise_id')));
    });

    test('editar conserva los ids para no perder el historial', () {
      final draft = RoutineDraft.edit(_routine());
      final group = (draft.toJson()['groups'] as List).first as Map;
      expect(draft.routineId, 'r1');
      expect(group['routine_group_id'], 10);
      expect((group['exercises'] as List).first['routine_exercise_id'], 100);
    });

    test('lo copiado va al grupo destino', () {
      final draft = RoutineDraft.copyOf(_routine());
      final legs = draft.groups[1];
      draft.setTarget(legs.key);
      draft.addExercise(DraftExercise.fromRoutine(_exercise(103, 'Hip thrust')));
      expect(legs.exercises.map((e) => e.name), ['Sentadilla', 'Hip thrust']);
    });

    test('copiar un grupo con nombre repetido le pone otro nombre', () {
      final draft = RoutineDraft.copyOf(_routine());
      draft.copyGroup(_routine().groups.first);
      expect(draft.groups.map((g) => g.name), ['Empuje', 'Piernas', 'Empuje 2']);
      expect(draft.validate(), isNull);
    });

    test('usar de base se puede deshacer', () {
      final draft = RoutineDraft.empty(2);
      final before = draft.groups.map((g) => g.name).toList();
      draft.useAsBase(_routine(), 'la rutina de Mai');
      expect(draft.groups.map((g) => g.name), ['Empuje', 'Piernas']);
      draft.undo();
      expect(draft.groups.map((g) => g.name), before);
    });

    test('reordenar grupos y ejercicios (índices de onReorderItem)', () {
      final draft = RoutineDraft.copyOf(_routine());
      draft.moveGroup(0, 1);
      expect(draft.groups.map((g) => g.name), ['Piernas', 'Empuje']);
      final push = draft.groups[1];
      draft.moveExercise(push, 1, 0);
      expect(push.exercises.map((e) => e.name), ['Press militar', 'Press de banca']);
    });

    test('valida grupos vacíos, sin nombre y repetidos', () {
      final draft = RoutineDraft.empty(2);
      expect(draft.validate(), contains('no tiene ejercicios'));
      draft.groups.first.name = ' ';
      expect(draft.validate(), contains('nombre'));
      draft.groups.first.name = 'Grupo 2';
      draft.groups.first.exercises.add(DraftExercise.fromRoutine(_exercise(1, 'A')));
      draft.groups.last.exercises.add(DraftExercise.fromRoutine(_exercise(2, 'B')));
      expect(draft.validate(), contains('dos grupos'));
    });

    test('un ejercicio del catálogo arranca con lo último que hizo el cliente', () {
      const catalog = CatalogExercise(id: 5, name: 'Prensa 45°', muscles: [], lastForClient: [Serie(reps: 10, weightKg: 140)]);
      expect(DraftExercise.fromCatalog(catalog).series, const [Serie(reps: 10, weightKg: 140)]);
      const fresh = CatalogExercise(id: 6, name: 'Zancadas', muscles: []);
      expect(DraftExercise.fromCatalog(fresh).series, defaultSeries);
    });
  });

  group('series', () {
    test('resumen de series iguales y distintas', () {
      expect(seriesLabel(const [Serie(reps: 8, weightKg: 60), Serie(reps: 8, weightKg: 60)]), '2 × 8 · 60 kg');
      expect(seriesLabel(const [Serie(reps: 12, weightKg: 50), Serie(reps: 10, weightKg: 52.5)]), '2 × 12/10 · 50→52,5 kg');
      expect(seriesLabel(const [Serie(reps: 40, weightKg: 0)]), '1 × 40');
    });

    test('lee pesos con coma o punto', () {
      expect(parseKg('62,5'), 62.5);
      expect(parseKg('62.5'), 62.5);
      expect(parseKg('-1'), isNull);
      expect(parseKg('abc'), isNull);
    });
  });
}
