import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/config/app_theme.dart';
import 'package:turni/core/services/data_changes.dart';
import 'package:turni/core/utils/domain_error.dart';
import 'package:turni/core/utils/either.dart';
import 'package:turni/core/utils/repository_response.dart';
import 'package:turni/domain/entities/admin_notification.dart';
import 'package:turni/domain/entities/session_status.dart';
import 'package:turni/domain/repositories/notification_repository.dart';
import 'package:turni/domain/repositories/session_repository.dart';
import 'package:turni/domain/usercases/session_user_cases.dart';
import 'package:turni/presentation/admin/notifications/notification_texts.dart';
import 'package:turni/presentation/admin/notifications/notification_toasts.dart';
import 'package:turni/presentation/admin/notifications/notifications_cubit.dart';
import 'package:turni/presentation/admin/notifications/notifications_panel.dart';

final _now = DateTime(2026, 10, 24, 18, 30);

AdminNotification _notice(
  int id, {
  bool read = false,
  Map<String, String> data = const {'session_id': '5'},
  String title = 'Nueva solicitud de turno',
  String type = 'SESSION_REQUESTED',
  String category = 'SESSION',
  Map<String, dynamic>? context,
  String createdAt = '2026-10-24T20:00:00.000Z',
}) =>
    AdminNotification.fromJson({
      'notification_id': '$id',
      'type': type,
      'category': category,
      'title': title,
      'body': 'Ana pidió el sábado a las 20:00.',
      'data': data,
      'club_id': 3,
      'read_at': read ? '2026-10-24T12:00:00.000Z' : null,
      'created_at': createdAt,
      'context': context,
    });

/// Contexto de una solicitud de Martina para la Cancha 2, hoy 19:00 (hora local).
Map<String, dynamic> _requestContext({String state = 'PENDING', String? by, bool byMe = false}) => {
      'client': {'client_id': 11, 'name': 'Martina López'},
      'session': {
        'session_id': 48,
        'space': 'Cancha 2',
        'space_gender': 'f',
        'start_time': DateTime(2026, 10, 24, 19).toUtc().toIso8601String(),
        'duration': 90,
      },
      'amount': null,
      'request': {'state': state, 'resolved_by': by, 'resolved_by_me': byMe},
      'tournament': null,
    };

Map<String, dynamic> _depositContext() => {..._requestContext(), 'request': null, 'amount': 8000};

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

/// Acepta o rechaza (o falla con [fail]) y anota qué turno.
class _FakeSessions implements SessionRepository {
  final List<String> calls = [];
  DomainError? fail;

  @override
  Future<Either<DomainError, SessionStatus>> acceptSessionRequest(int sessionId) async {
    calls.add('accept $sessionId');
    return fail != null ? Either.left(fail!) : const Either.right(SessionStatus.confirmed);
  }

  @override
  Future<Either<DomainError, SessionStatus>> rejectSessionRequest(int sessionId) async {
    calls.add('reject $sessionId');
    return fail != null ? Either.left(fail!) : const Either.right(SessionStatus.rejected);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

  group('textos', () {
    test('una solicitud: quién, qué espacio, cuándo y cómo terminó', () {
      final pending = _notice(1, context: _requestContext());
      expect(notificationTitle(pending), 'Solicitud de turno');
      expect(notificationSentence(pending, _now), (who: 'Martina López', rest: ' pidió la Cancha 2 para hoy a las 19:00.'));
      expect(notificationContextLabel(pending, _now), 'Cancha 2 · Hoy 19:00 · 90 min');
      expect(notificationStatus(pending), isNull);
      expect(pending.needsAction, isTrue);

      expect(notificationStatus(_notice(2, context: _requestContext(state: 'ACCEPTED', by: 'Sol Paz'))), (text: 'Aceptada por Sol Paz', ok: true));
      expect(notificationStatus(_notice(3, context: _requestContext(state: 'REJECTED', byMe: true))), (text: 'Rechazada por vos', ok: false));
      expect(notificationStatus(_notice(4, context: _requestContext(state: 'EXPIRED'))), (text: 'Venció sin respuesta', ok: false));
    });

    test('una seña trae el monto y la disputa los equipos', () {
      final deposit = _notice(1, type: 'SESSION_DEPOSIT_PAID', title: 'Seña pagada', context: _depositContext());
      expect(notificationTitle(deposit), 'Seña acreditada');
      expect(notificationSentence(deposit, _now).rest, ' pagó la seña por Mercado Pago.');
      expect(notificationContextLabel(deposit, _now), 'Cancha 2 · Hoy 19:00');
      expect(notificationAmountLabel(deposit), r'$ 8.000');

      final dispute = _notice(2, type: 'TOURNAMENT_RESULT_DISPUTED', category: 'TOURNAMENT', data: {'tournament_id': '2'}, context: {
        'tournament': {'tournament_id': 2, 'name': 'Torneo Apertura', 'match_id': 30, 'match_label': 'Cuartos de final', 'team_a': 'Los Pibes', 'team_b': 'La Pala'},
      });
      expect(notificationSentence(dispute, _now), (who: '', rest: 'Los Pibes y La Pala cargaron resultados distintos.'));
      expect(notificationContextLabel(dispute, _now), 'Torneo Apertura · Cuartos de final');
      expect(dispute.needsAction, isTrue);
    });

    test('días de la etiqueta y grupos', () {
      final saturday = _notice(1, context: {
        ..._requestContext(),
        'session': {'session_id': 1, 'space': 'Box 1', 'space_gender': 'm', 'start_time': DateTime(2026, 10, 31, 10).toUtc().toIso8601String(), 'duration': 60},
      });
      expect(notificationSentence(saturday, _now).rest, ' pidió el Box 1 para el 31/10 a las 10:00.');
      final thursday = _notice(2, context: {
        ..._requestContext(),
        'session': {'session_id': 1, 'space': 'Box 1', 'space_gender': 'm', 'start_time': DateTime(2026, 10, 29, 10).toUtc().toIso8601String(), 'duration': 60},
      });
      expect(notificationSentence(thursday, _now).rest, ' pidió el Box 1 para el jueves a las 10:00.');
      expect(notificationContextLabel(thursday, _now), 'Box 1 · Jue 10:00 · 60 min');
      expect(notificationGroup(_now, _now), 'Hoy');
      expect(notificationGroup(DateTime(2026, 10, 23, 9), _now), 'Ayer');
      expect(notificationGroup(DateTime(2026, 10, 20), _now), 'Antes');
    });

    test('sin contexto usa el título y el cuerpo del aviso', () {
      final old = _notice(1, type: 'GYM_ALGO', category: 'GYM', title: 'Algo del gym');
      expect(notificationTitle(old), 'Algo del gym');
      expect(notificationSentence(old, _now), (who: '', rest: 'Ana pidió el sábado a las 20:00.'));
      expect(notificationContextLabel(old, _now), isNull);
    });
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

    test('un push nuevo refresca el contador y la lista', () async {
      await cubit.load();
      repo.all.insert(0, _notice(6));
      repo.unread = 3;

      pushes.add({'type': 'SESSION_REQUESTED', 'session_id': '6'});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.unread, 3);
      expect(cubit.state.items.first.id, '6');
    });

    test('un push hace sonar la campana y manda lo nuevo a los avisos flotantes', () async {
      await cubit.load();
      final arrivals = <List<String>>[];
      final sub = cubit.arrivals.listen((fresh) => arrivals.add(fresh.map((n) => n.id).toList()));
      repo.all.insert(0, _notice(6));

      await cubit.onPush();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.rings, 1);
      expect(cubit.state.attention, isTrue);
      expect(arrivals, [
        ['6'],
      ]);
      cubit.panelOpened();
      expect(cubit.state.attention, isFalse);
      await sub.cancel();
    });

    test('por el socket: suena solo si llegó un aviso nuevo, no al leer en otra pestaña', () async {
      final changes = StreamController<DataChange>.broadcast();
      addTearDown(changes.close);
      final local = NotificationsCubit(repository: repo, changes: changes.stream, now: () => _now);
      addTearDown(local.close);
      await local.load();
      final arrivals = <String>[];
      final sub = local.arrivals.listen((fresh) => arrivals.addAll(fresh.map((n) => n.id)));

      // Se leyó uno en otra pestaña: nada nuevo, no suena.
      changes.add(const DataChange({DataTopic.notifications}));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(local.state.rings, 0);

      // Llegó uno nuevo.
      repo.all.insert(0, _notice(6));
      changes.add(const DataChange({DataTopic.notifications}));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(local.state.rings, 1);
      expect(arrivals, ['6']);

      // La recarga general (reconexión) no suena.
      repo.all.insert(0, _notice(7));
      changes.add(DataChange(DataTopic.values.toSet()));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(local.state.rings, 1);
      await sub.cancel();
    });

    test('filtros: sin leer y para resolver', () async {
      final local = NotificationsCubit(
        repository: _FakeRepository([
          _notice(3, context: _requestContext()),
          _notice(2, context: _requestContext(state: 'ACCEPTED', by: 'Sol')),
          _notice(1, read: true, context: _requestContext(state: 'EXPIRED')),
        ], pageSize: 20),
        now: () => _now,
      );
      addTearDown(local.close);
      await local.load();

      expect(local.state.actionCount, 1);
      local.setFilter(NotificationFilter.unread);
      expect(local.state.visible.map((n) => n.id), ['3', '2']);
      local.setFilter(NotificationFilter.action);
      expect(local.state.visible.map((n) => n.id), ['3']);
    });

    test('aceptar desde la bandeja: llama al turno y queda "por vos"', () async {
      final sessions = _FakeSessions();
      final local = NotificationsCubit(
        repository: _FakeRepository([_notice(3, context: _requestContext())], pageSize: 20),
        sessions: SessionUserCases(sessions),
        now: () => _now,
      );
      addTearDown(local.close);
      await local.load();

      final error = await local.respond(local.state.items.first, accept: true);

      expect(error, isNull);
      expect(sessions.calls, ['accept 48']);
      expect(notificationStatus(local.state.items.first), (text: 'Aceptada por vos', ok: true));
      expect(local.state.items.first.isRead, isTrue);
      expect(local.state.actionCount, 0);
    });

    test('si el back no deja rechazar, devuelve su mensaje', () async {
      final sessions = _FakeSessions()..fail = DomainError(message: 'La solicitud ya no está pendiente de confirmación.', internalCode: 1, date: _now);
      final local = NotificationsCubit(
        repository: _FakeRepository([_notice(3, context: _requestContext())], pageSize: 20),
        sessions: SessionUserCases(sessions),
        now: () => _now,
      );
      addTearDown(local.close);
      await local.load();

      expect(await local.respond(local.state.items.first, accept: false), 'La solicitud ya no está pendiente de confirmación.');
    });
  });

  group('panel', () {
    Future<(NotificationsCubit, GoRouter)> pumpPanel(
      WidgetTester tester,
      List<AdminNotification> items, {
      double width = 1200,
      SessionUserCases? sessions,
    }) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cubit = NotificationsCubit(repository: _FakeRepository(items, pageSize: 20), sessions: sessions, now: () => _now);
      addTearDown(cubit.close);
      final compact = width < 600;
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          // Escritorio: la campana abajo a la izquierda (menú lateral); celular: en la barra.
          builder: (context, _) => Scaffold(
            appBar: compact ? AppBar(actions: [NotificationsButton(cubit: cubit)]) : null,
            body: compact
                ? const SizedBox.expand()
                : Align(
                    alignment: const Alignment(-1, 0.8),
                    child: Padding(padding: const EdgeInsets.only(left: 20), child: NotificationsButton(cubit: cubit)),
                  ),
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

    testWidgets('la campanita abre la bandeja vacía', (tester) async {
      await pumpPanel(tester, []);
      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();
      expect(find.text('Todavía no hay avisos'), findsOneWidget);
    });

    testWidgets('tocar adentro de la bandeja no la cierra; afuera sí', (tester) async {
      await pumpPanel(tester, [_notice(2, context: _requestContext())]);
      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notificaciones'));
      await tester.pumpAndSettle();
      expect(find.text('Para resolver'), findsOneWidget);

      await tester.tapAt(const Offset(1100, 100));
      await tester.pumpAndSettle();
      expect(find.text('Para resolver'), findsNothing);
    });

    testWidgets('tocar un aviso lo marca leído y abre el turno', (tester) async {
      final (cubit, _) = await pumpPanel(tester, [_notice(2, data: {'session_id': '48'}), _notice(1, read: true)]);
      expect(find.text('1'), findsOneWidget); // badge

      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solicitud de turno').first);
      await tester.pumpAndSettle();

      expect(cubit.state.unread, 0);
      expect(find.text('turno 48'), findsOneWidget);
    });

    testWidgets('a 360 px baja de la barra y no desborda', (tester) async {
      await pumpPanel(tester, [
        _notice(1, title: 'TOURNAMENT_RESULT_DISPUTED en la final de la Copa Primavera Mixta de Pádel Categoría Libre'),
        _notice(2, context: _requestContext()),
      ], width: 360);
      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Marcar todo como leído'), findsOneWidget);
      expect(find.byTooltip('Cerrar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('aceptar una solicitud desde la bandeja', (tester) async {
      final sessions = _FakeSessions();
      await pumpPanel(tester, [_notice(2, context: _requestContext())], sessions: SessionUserCases(sessions));
      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Cancha 2 · '), findsOneWidget);
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(sessions.calls, ['accept 48']);
      expect(find.text('Aceptada por vos'), findsOneWidget);
      expect(find.text('Aceptar'), findsNothing);
    });

    testWidgets('filtro "Para resolver" sin pendientes: estás al día', (tester) async {
      await pumpPanel(tester, [_notice(2, read: true, context: _requestContext(state: 'ACCEPTED', by: 'Sol Paz'))]);
      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();
      expect(find.text('Aceptada por Sol Paz'), findsOneWidget);

      await tester.tap(find.text('Para resolver'));
      await tester.pumpAndSettle();
      expect(find.text('Estás al día'), findsOneWidget);
    });

    testWidgets('un aviso nuevo sale flotando de la campana y se cierra solo', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _FakeRepository([], pageSize: 20);
      final live = NotificationsCubit(repository: repo, now: () => _now);
      addTearDown(live.close);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: Align(alignment: const Alignment(-1, 0.8), child: NotificationsButton(cubit: live))),
      ));
      await tester.pumpAndSettle();
      await tester.runAsync(live.load);

      repo.all.add(_notice(9, type: 'SESSION_DEPOSIT_PAID', title: 'Seña pagada', createdAt: _now.toUtc().toIso8601String(), context: _depositContext()));
      await tester.runAsync(live.onPush);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Seña acreditada'), findsOneWidget);
      expect(find.text('Ahora'), findsOneWidget);
      expect(find.text(r'$ 8.000'), findsOneWidget);

      await tester.pump(toastDuration);
      await tester.pumpAndSettle();
      expect(find.text('Seña acreditada'), findsNothing);
    });
  });
}
