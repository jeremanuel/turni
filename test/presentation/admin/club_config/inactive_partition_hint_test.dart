import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turni/presentation/admin/club_config/club_config_focus.dart';
import 'package:turni/presentation/admin/club_config/widgets/inactive_partition_hint.dart';

void main() {
  Widget host({required bool inactive}) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: InactivePartitionHint(
              inactive: inactive,
              message: InactivePartitionHint.physicalPartitionMessage,
              focus: const ClubConfigFocus.physicalPartition(
                clubPartitionId: 1,
                partitionPhysicalId: 10,
              ),
              child: const FilterChip(label: Text('Cancha 1'), onSelected: null),
            ),
          ),
        ),
      );

  testWidgets('una opción inactiva muestra el aviso con el enlace a la configuración', (tester) async {
    await tester.pumpWidget(host(inactive: true));

    expect(find.text(InactivePartitionHint.physicalPartitionMessage), findsNothing);

    await tester.tap(find.text('Cancha 1'));
    await tester.pump();

    expect(find.text(InactivePartitionHint.physicalPartitionMessage), findsOneWidget);
    expect(find.text('Abrir configuración'), findsOneWidget);

    // Tocar afuera lo cierra.
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.text(InactivePartitionHint.physicalPartitionMessage), findsNothing);
  });

  testWidgets('una opción activa no agrega ningún aviso', (tester) async {
    await tester.pumpWidget(host(inactive: false));

    await tester.tap(find.text('Cancha 1'));
    await tester.pump();

    expect(find.text(InactivePartitionHint.physicalPartitionMessage), findsNothing);
  });
}
