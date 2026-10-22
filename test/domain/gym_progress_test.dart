import 'package:flutter_test/flutter_test.dart';
import 'package:turni/domain/entities/gym/gym.dart';
import 'package:turni/domain/entities/gym/gym_progress.dart';

List<Map<String, dynamic>> s(int sets, int reps, double kg) => List.generate(sets, (_) => {'reps': reps, 'weight_kg': kg});

Map<String, dynamic> point(String date, List<Map<String, dynamic>> series, String source, {bool byMe = false}) =>
    {'date': '${date}T15:00:00.000Z', 'series': series, 'source': source, 'admin_name': source == 'PLAN' ? 'Sol Paz' : null, 'by_me': byMe};

void main() {
  final progress = RoutineProgress.fromJson({
    'routine_id': 'r1',
    'start_date': '2026-09-01',
    'exercises': [
      {
        'routine_exercise_id': 102,
        'name': 'Sentadilla con barra',
        'routine_group_id': 12,
        'group_name': 'Piernas',
        'plan': s(4, 8, 85),
        'points': [
          point('2026-09-01', s(4, 8, 80), 'PLAN', byMe: true),
          point('2026-09-29', s(4, 10, 80), 'CLIENT'),
          point('2026-10-06', s(4, 8, 85), 'PLAN'),
          point('2026-10-14', s(4, 9, 85), 'CLIENT'),
        ],
      },
      {
        'routine_exercise_id': 103,
        'name': 'Prensa',
        'routine_group_id': 12,
        'group_name': 'Piernas',
        'plan': s(4, 12, 160),
        'points': [point('2026-09-01', s(4, 12, 140), 'PLAN'), point('2026-10-01', s(4, 12, 160), 'PLAN')],
      },
    ],
  });

  test('quién hizo cada cambio', () {
    final squat = progress.exercise(102)!;
    expect(squat.points[0].who('Mai', first: true), 'Vos, al armar la rutina');
    expect(squat.points[1].who('Mai', first: false), 'Mai entrenando');
    expect(squat.points[2].who('Mai', first: false), 'Sol Paz, en el plan');
  });

  test('diferencias y lo que hizo de más que el plan', () {
    final squat = progress.exercise(102)!;
    expect(squat.totalDelta!.label, '+5 kg · +1 rep');
    expect(squat.deltaAt(2)!.up, isFalse);
    expect(squat.doneBeyondPlan!.series.first, const Serie(reps: 9, weightKg: 85));
    // El último cambio fue del plan: no hay nada para "Usar".
    expect(progress.exercise(103)!.doneBeyondPlan, isNull);
    expect(progress.lastChangeDate!.day, 14);
  });
}
