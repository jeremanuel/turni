import 'package:flutter_test/flutter_test.dart';

import 'package:turni/domain/entities/bulk_sessions.dart';

void main() {
  test('un turno "unchanged" se lee como no modificado y cuenta aparte de los protegidos', () {
    final preview = BulkPreview.fromJson({
      'matched': 3,
      'affected': 1,
      'excluded': {'booked': 1, 'pending': 0, 'paid': 0, 'overlap': 0, 'unchanged': 1},
      'total_rows': 3,
      'rows': [
        {
          'session_id': 1,
          'partition_physical_id': 10,
          'start_time': '2026-10-05T21:00:00.000Z',
          'duration': 60,
          'price': 1200,
          'result': 'unchanged',
        },
      ],
    });

    expect(preview.rows.single.result, BulkRowResult.unchanged);
    expect(preview.rows.single.result.isExcluded, isTrue);
    expect(preview.rows.single.newPrice, isNull);
    expect(preview.excluded.protectedTotal, 1);
    expect(preview.excluded.total, 2);
  });
}
