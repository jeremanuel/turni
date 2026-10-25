import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/config/app_theme.dart';
import 'package:turni/core/utils/either.dart';
import 'package:turni/core/utils/repository_response.dart';
import 'package:turni/domain/entities/admin_notification.dart';
import 'package:turni/domain/repositories/notification_repository.dart';
import 'package:turni/presentation/admin/notifications/notifications_cubit.dart';
import 'package:turni/presentation/admin/notifications/notifications_panel.dart';

final _now = DateTime(2026, 10, 24, 18, 30);

AdminNotification _notice(int id, {bool read = false, Map<String, String> data = const {'session_id': '5'}, String title = 'Nueva solicitud de turno'}) =>
    AdminNotification.fromJson({
      'notification_id': '$id',
      'type': 'SESSION_REQUESTED',
      'category': 'SESSION',
      'title': title,
      'body': 'Ana pidió el sábado a las 20:00.',
      'data': data,
      'club_id': 3,
      'read_at': read ? '2026-10-24T12:00:00.000Z' : null,
      'created_at': '2026-10-24T20:00:00.000Z',
    });

/// Bandeja en memoria: páginas de [pageSize], los más nuevos primero.
class _FakeRepository implements NotificationRepository {
  final List<AdminNotification> all;
  final int pageSize;
  int unread;
  final List<String> marked = [];

  _FakeRepository(this.all, {this.pageSize = 2}) : unread = all.where((n) => !n.isRead).length;

  @override
  Future<RepositoryResponse<AdminNotificationPage>> getNotifications({String? cursor}) async {
    final start = cursor == null ? 0 : all.indexWhere((n) => n.id == cursor) + 1;
    final page = all.skip(start).take(pageSize).toList();
    final more = start + pageSize < all.length;
    return Either.right(AdminNotificationPage(notifications: page, nextCursor: more ? page.last.id : null));
  }

  @override
  Future<RepositoryResponse<int>> getUnreadCount() async => Either.right(unread);

  @override
  Future<RepositoryResponse<bool>> markRead(String notificationId) async {
    marked.add(notificationId);
    final index = all.indexWhere((n) => n.id == notificationId);
    if (index >= 0 && !all[index].isRead) {
      all[index] = all[index].markedRead(_now);
      unread--;
    }
    return const Either.right(true);
  }

  @override
  Future<RepositoryResponse<int>> markAllRead() async {
    final updated = unread;
    for (var i = 0; i < all.length; i++) {
      all[i] = all[i].markedRead(_now);
    }
    unread = 0;
    return Either.right(updated);
  }
}

void main() {
  test('el aviso lleva al turno, al torneo o a la agenda', () {
    expect(adminNotificationLocation({'session_id': '48'}), '/session_manager/reserve/48');
    expect(adminNotificationLocation({'tournament_id': '7', 'match_id': '3'}), '/tournaments/7');
    expect(adminNotificationLocation({'type': 'OTRA_COSA'}), '/session_manager');
  });

  test('notificationTimeLabel', () {
    expect(notificationTimeLabel(_now.subtract(const Duration(minutes: 5)), _now), 'Hace 5 min');
    expect(notificationTimeLabel(DateTime(2026, 10, 23, 22), _now), 'Ayer 22:00');
    expect(notificationTimeLabel(DateTime(2026, 10, 12, 18, 30), _now), '12/10 · 18:30');
  });

  group('NotificationsCubit', () {
    late _FakeRepository repo;
    late StreamController<Map<String, dynamic>> pushes;
    late NotificationsCubit cubit;

    setUp(() {
      repo = _FakeRepository([_notice(5), _notice(4), _notice(3, read: true)]);
      pushes = StreamController<Map<String, dynamic>>.broadcast();
      cubit = NotificationsCubit(repository: repo, pushes: pushes.stream, now: () => _now);
    });

    tearDown(() async {
      await cubit.close();
      await pushes.close();
    });

    test('carga de a páginas sin repetir', () async {
      await cubit.load();
      expect(cubit.state.items.map((n) => n.id), ['5', '4']);
      expect(cubit.state.unread, 2);

      await cubit.loadMore();
      expect(cubit.state.items.map((n) => n.id), ['5', '4', '3']);
      expect(cubit.state.hasMore, isFalse);
    });

    test('marcar uno y marcar todo', () async {
      await cubit.load();
      await cubit.markRead(cubit.state.items.first);
      expect(repo.marked, ['5']);
      expect(cubit.state.unread, 1);

      await cubit.markAllRead();
      expect(cubit.state.unread, 0);
      expect(cubit.state.items.every((n) => n.isRead), isTrue);
    });

    test('un push nuevo refresca el contador y la lista abierta', () async {
      await cubit.load();
      repo.all.insert(0, _notice(6));
      repo.unread = 3;

      pushes.add({'type': 'SESSION_REQUESTED', 'session_id': '6'});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.unread, 3);
      expect(cubit.state.items.first.id, '6');
    });
  });

  group('panel', () {
    Future<(NotificationsCubit, GoRouter)> pumpPanel(WidgetTester tester, List<AdminNotification> items, {double width = 1200}) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cubit = NotificationsCubit(repository: _FakeRepository(items, pageSize: 20), now: () => _now);
      addTearDown(cubit.close);
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(child: NotificationsButton(cubit: cubit)),
          ),
        ),
        GoRoute(path: '/session_manager', builder: (_, _) => const Text('agenda')),
        GoRoute(path: '/session_manager/reserve/:idSession', builder: (_, state) => Text('turno ${state.pathParameters['idSession']}')),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router));
      await tester.pumpAndSettle();
      return (cubit, router);
    }

    testWidgets('la campanita muestra los sin leer y abre la bandeja vacía', (tester) async {
      await pumpPanel(tester, []);
      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();
      expect(find.text('No hay avisos'), findsOneWidget);
    });

    testWidgets('tocar un aviso lo marca leído y abre el turno', (tester) async {
      final (cubit, _) = await pumpPanel(tester, [_notice(2, data: {'session_id': '48'}), _notice(1, read: true)]);
      expect(find.text('1'), findsOneWidget); // badge

      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nueva solicitud de turno').first);
      await tester.pumpAndSettle();

      expect(cubit.state.unread, 0);
      expect(find.text('turno 48'), findsOneWidget);
    });

    testWidgets('a 360 px abre a pantalla completa y no desborda', (tester) async {
      await pumpPanel(tester, [
        _notice(1, title: 'TOURNAMENT_RESULT_DISPUTED en la final de la Copa Primavera Mixta de Pádel Categoría Libre'),
      ], width: 360);
      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Marcar todo como leído'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
