import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turni/core/presentation/components/realtime_indicator.dart';
import 'package:turni/core/services/data_changes.dart';
import 'package:turni/core/services/realtime/realtime_service.dart';

class _Reloading extends StatefulWidget {
  final List<DataChange> received;
  final int? tournamentId;

  const _Reloading({required this.received, this.tournamentId});

  @override
  State<_Reloading> createState() => _ReloadingState();
}

class _ReloadingState extends State<_Reloading> with ReloadOnDataChange {
  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.tournaments};

  @override
  bool shouldReload(DataChange change) => change.isFor('tournament_id', widget.tournamentId);

  @override
  void onDataChanged(DataChange change) => widget.received.add(change);

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  final service = RealtimeService.instance;

  tearDown(() => service.status.value = RealtimeStatus.idle);

  group('topicsForRealtime', () {
    test('los temas del backend son los del admin, uno a uno', () {
      expect(topicsForRealtime(['sessions', 'availability']), {DataTopic.sessions, DataTopic.availability});
      expect(topicsForRealtime(['fixed_sessions', 'club_config']), {DataTopic.fixedSessions, DataTopic.clubConfig});
      expect(topicsForRealtime(['payments', 'clients', 'tournaments', 'matches', 'admins']),
          {DataTopic.payments, DataTopic.clients, DataTopic.tournaments, DataTopic.matches, DataTopic.admins});
    });

    test('ignora temas desconocidos', () {
      expect(topicsForRealtime(['algo_nuevo']), isEmpty);
    });
  });

  group('ReloadOnDataChange', () {
    testWidgets('recarga solo con sus temas y su id', (tester) async {
      final received = <DataChange>[];
      await tester.pumpWidget(MaterialApp(home: _Reloading(received: received, tournamentId: 5)));

      DataChanges.notify(const DataChange({DataTopic.sessions}));
      DataChanges.notify(const DataChange({DataTopic.tournaments}, data: {'tournament_id': 9}));
      DataChanges.notify(const DataChange({DataTopic.tournaments}, data: {'tournament_id': 5}));
      DataChanges.notify(const DataChange({DataTopic.tournaments}));
      await tester.pump();

      expect(received, hasLength(2));
    });
  });

  group('RealtimeIndicator', () {
    Color dotColor(WidgetTester tester) {
      final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
      return (container.decoration! as BoxDecoration).color!;
    }

    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));

    testWidgets('verde conectado, rojo desconectado', (tester) async {
      service.status.value = RealtimeStatus.connected;
      await pump(tester, const RealtimeIndicator());
      expect(dotColor(tester), const Color(0xFF34A853));

      service.status.value = RealtimeStatus.disconnected;
      await tester.pump(const Duration(milliseconds: 300));
      expect(dotColor(tester), ThemeData().colorScheme.error);
    });

    testWidgets('una reconexión rápida no lo pone amarillo; una larga, sí', (tester) async {
      service.status.value = RealtimeStatus.connected;
      await pump(tester, const RealtimeIndicator());

      service.status.value = RealtimeStatus.reconnecting;
      await tester.pump(const Duration(milliseconds: 500));
      expect(dotColor(tester), const Color(0xFF34A853));

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 300));
      expect(dotColor(tester), const Color(0xFFF9AB00));
    });

    testWidgets('al tocarlo explica el estado y en rojo ofrece reintentar', (tester) async {
      service.status.value = RealtimeStatus.disconnected;
      await pump(tester, const RealtimeIndicator());

      await tester.tap(find.byType(RealtimeIndicator));
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión en vivo'), findsWidgets);
      expect(find.textContaining('El panel funciona igual'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('conectado no ofrece reintentar', (tester) async {
      service.status.value = RealtimeStatus.connected;
      await pump(tester, const RealtimeStatusTile());
      expect(find.text('Actualizado en tiempo real'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    });
  });

  test('sin sesión, reintentar no hace nada y no tira', () {
    service.disconnect();
    expect(service.retry, returnsNormally);
    expect(service.status.value, RealtimeStatus.idle);
    unawaited(Future<void>.value());
  });
}
