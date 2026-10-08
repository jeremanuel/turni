import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turni/domain/entities/club_map/court_usage.dart';
import 'package:turni/presentation/admin/club_map/widgets/court_tile.dart';

void main() {
  test('parsea GET /admin/club-map/usage', () {
    final view = CourtUsageView.fromJson({
      'from': '2026-09-06T03:00:00.000Z',
      'to': '2026-10-06T03:00:00.000Z',
      'courts': [
        {'partition_physical_id': 31, 'offered_minutes': 600, 'reserved_minutes': 450, 'usage': 0.75},
        {'partition_physical_id': 32, 'offered_minutes': 0, 'reserved_minutes': 0, 'usage': null},
      ],
    });

    expect(view.byCourt[31]!.percentLabel, '75 %');
    expect(view.byCourt[32]!.usage, isNull);
    expect(view.byCourt[32]!.percentLabel, isNull);
  });

  test('formatHours', () {
    expect(formatHours(600), '10 h');
    expect(formatHours(90), '1,5 h');
    expect(formatHours(0), '0 h');
  });

  test('UsageScale: un tramo cada 20 %, sin turnos en gris', () {
    expect(UsageScale.colorOf(0), UsageScale.steps[0]);
    expect(UsageScale.colorOf(0.19), UsageScale.steps[0]);
    expect(UsageScale.colorOf(0.2), UsageScale.steps[1]);
    expect(UsageScale.colorOf(0.75), UsageScale.steps[3]);
    expect(UsageScale.colorOf(1), UsageScale.steps[4]);
    expect(UsageScale.colorOf(null), UsageScale.none);
    expect(UsageScale.steps.toSet(), hasLength(UsageScale.labels.length));
    expect(UsageScale.none, isNot(isIn(UsageScale.steps)));
    expect(UsageScale.steps.first, const Color(0xFF86B6EF));
  });
}
