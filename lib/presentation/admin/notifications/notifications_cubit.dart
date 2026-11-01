import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/services/data_changes.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../domain/entities/admin_notification.dart';
import '../../../domain/repositories/notification_repository.dart';
import '../../../domain/repositories/session_repository.dart';
import '../../../domain/usercases/session_user_cases.dart';

/// Adónde lleva un aviso (el tap en el push o en la bandeja): el turno en la
/// agenda, el torneo o, si no trae ninguno, la agenda.
String adminNotificationLocation(Map<String, dynamic> data) {
  final sessionId = int.tryParse('${data['session_id'] ?? ''}');
  if (sessionId != null) {
    return AppRoutes.SESSION_MANAGER_RESERVE_ROUTE.path.replaceFirst(':idSession', '$sessionId');
  }
  final tournamentId = int.tryParse('${data['tournament_id'] ?? ''}');
  if (tournamentId != null) {
    return AppRoutes.TOURNAMENT_DETAIL_ROUTE.path.replaceFirst(':tournamentId', '$tournamentId');
  }
  return AppRoutes.SESSION_MANAGER_ROUTE.path;
}

/// Los filtros de la bandeja.
enum NotificationFilter { all, unread, action }

class NotificationsState {
  /// Avisos sin leer (el badge de la campanita).
  final int unread;
  final List<AdminNotification> items;
  final String? nextCursor;
  final NotificationFilter filter;

  /// Primera carga de la lista, con spinner.
  final bool loading;
  final bool loadingMore;

  /// La lista ya se pidió alguna vez: a partir de ahí se refresca sola.
  final bool loaded;
  final DomainError? error;

  /// Llegó un aviso y la bandeja no se abrió desde entonces: la campana queda
  /// resaltada.
  final bool attention;

  /// Sube con cada llegada: la campana se anima cuando cambia.
  final int rings;

  const NotificationsState({
    this.unread = 0,
    this.items = const [],
    this.nextCursor,
    this.filter = NotificationFilter.all,
    this.loading = false,
    this.loadingMore = false,
    this.loaded = false,
    this.error,
    this.attention = false,
    this.rings = 0,
  });

  bool get hasMore => nextCursor != null;

  int get actionCount => items.where((n) => n.needsAction).length;

  List<AdminNotification> get visible => switch (filter) {
    NotificationFilter.all => items,
    NotificationFilter.unread => items.where((n) => !n.isRead).toList(),
    NotificationFilter.action => items.where((n) => n.needsAction).toList(),
  };

  NotificationsState copyWith({
    int? unread,
    List<AdminNotification>? items,
    String? Function()? nextCursor,
    NotificationFilter? filter,
    bool? loading,
    bool? loadingMore,
    bool? loaded,
    DomainError? Function()? error,
    bool? attention,
    int? rings,
  }) => NotificationsState(
    unread: unread ?? this.unread,
    items: items ?? this.items,
    nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
    filter: filter ?? this.filter,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    loaded: loaded ?? this.loaded,
    error: error != null ? error() : this.error,
    attention: attention ?? this.attention,
    rings: rings ?? this.rings,
  );
}

/// La bandeja de avisos del admin. Vive toda la app (la campanita, el panel y
/// los avisos flotantes comparten el estado) y se refresca con cada push que
/// llega ([pushes], ver `PushNotificationService.messages`).
class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationRepository _repository;
  final SessionUserCases? _sessions;
  final DateTime Function() _now;
  StreamSubscription<Map<String, dynamic>>? _pushes;
  StreamSubscription<DataChange>? _changes;
  final _arrivals = StreamController<List<AdminNotification>>.broadcast();

  NotificationsCubit({NotificationRepository? repository, SessionUserCases? sessions, Stream<Map<String, dynamic>>? pushes, Stream<DataChange>? changes, DateTime Function()? now})
    : _repository = repository ?? sl<NotificationRepository>(),
      _sessions = sessions,
      _now = now ?? DateTime.now,
      super(const NotificationsState()) {
    _pushes = pushes?.listen((_) => onPush());
    // El canal en tiempo real: en la web no hay push, así que un aviso nuevo
    // llega por acá. Un evento solo de `notifications` = llegó o se leyó uno;
    // la recarga general (reconexión, vuelta a la pestaña) trae todos los
    // temas y solo actualiza, sin sonar la campana.
    _changes = changes?.listen((change) {
      if (change.topics.length == 1) {
        onLiveChange();
      } else if (state.loaded) {
        load(silent: true);
      } else {
        refreshUnread();
      }
    });
  }

  /// Los avisos nuevos que trajo cada push, ya con su contexto: los muestran
  /// los avisos flotantes.
  Stream<List<AdminNotification>> get arrivals => _arrivals.stream;

  SessionUserCases get _sessionCases => _sessions ?? SessionUserCases(sl<SessionRepository>());

  @override
  Future<void> close() {
    _pushes?.cancel();
    _changes?.cancel();
    _arrivals.close();
    return super.close();
  }

  /// Llegó un push con la app abierta: la campana suena enseguida y, cuando
  /// vuelve la lista, salen los avisos flotantes de lo nuevo.
  Future<void> onPush() async {
    emit(state.copyWith(attention: true, rings: state.rings + 1, unread: state.unread + 1));
    final known = state.items.map((n) => n.id).toSet();
    final wasLoaded = state.loaded;
    await load(silent: true);
    if (isClosed) return;
    final now = _now();
    final fresh = state.items.where((n) {
      if (n.isRead || known.contains(n.id)) return false;
      // Sin una lista previa para comparar, lo de recién.
      return wasLoaded || now.difference(n.createdAt) < const Duration(minutes: 2);
    }).toList();
    if (fresh.isNotEmpty) _arrivals.add(fresh);
  }

  /// El canal en tiempo real avisó que cambió la bandeja (llegó un aviso, o
  /// se leyó en otra pestaña). Recarga y, solo si hay avisos nuevos sin leer,
  /// suena la campana y salen los avisos flotantes.
  Future<void> onLiveChange() async {
    final known = state.items.map((n) => n.id).toSet();
    final wasLoaded = state.loaded;
    await load(silent: true);
    if (isClosed) return;
    final now = _now();
    final fresh = state.items.where((n) {
      if (n.isRead || known.contains(n.id)) return false;
      return wasLoaded || now.difference(n.createdAt) < const Duration(minutes: 2);
    }).toList();
    if (fresh.isEmpty) return;
    emit(state.copyWith(attention: true, rings: state.rings + 1));
    _arrivals.add(fresh);
  }

  Future<void> refreshUnread() async {
    final result = await _repository.getUnreadCount();
    if (isClosed) return;
    if (result case Right(:final value)) emit(state.copyWith(unread: value));
  }

  /// Se abrió la bandeja: la campana deja de estar resaltada.
  void panelOpened() {
    if (state.attention) emit(state.copyWith(attention: false));
  }

  void setFilter(NotificationFilter filter) => emit(state.copyWith(filter: filter));

  /// La primera página. `silent`: por un aviso nuevo, sin spinner.
  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(loading: true, error: () => null));
    final result = await _repository.getNotifications();
    if (isClosed) return;
    switch (result) {
      case Right(:final value):
        emit(state.copyWith(items: value.notifications, nextCursor: () => value.nextCursor, loading: false, loaded: true, error: () => null));
      case Left(:final failure):
        emit(silent ? state.copyWith(loading: false) : state.copyWith(loading: false, error: () => failure));
    }
    await refreshUnread();
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore || state.loading) return;
    emit(state.copyWith(loadingMore: true));
    final result = await _repository.getNotifications(cursor: cursor);
    if (isClosed) return;
    switch (result) {
      case Right(:final value):
        final known = state.items.map((n) => n.id).toSet();
        emit(
          state.copyWith(
            items: [...state.items, ...value.notifications.where((n) => !known.contains(n.id))],
            nextCursor: () => value.nextCursor,
            loadingMore: false,
          ),
        );
      case Left():
        emit(state.copyWith(loadingMore: false));
    }
  }

  /// Se marca en el momento; si el back falla, el próximo refresco lo corrige.
  Future<void> markRead(AdminNotification notification) async {
    if (notification.isRead) return;
    final now = _now();
    _replace(notification.id, (item) => item.markedRead(now));
    emit(state.copyWith(unread: state.unread > 0 ? state.unread - 1 : 0));
    await _repository.markRead(notification.id);
  }

  Future<void> markAllRead() async {
    final now = _now();
    emit(state.copyWith(items: [for (final item in state.items) item.markedRead(now)], unread: 0));
    await _repository.markAllRead();
  }

  /// Acepta o rechaza una solicitud de turno desde la bandeja o el aviso
  /// flotante. Devuelve el error para mostrar, o null si salió bien.
  Future<String?> respond(AdminNotification notification, {required bool accept}) async {
    final sessionId = notification.context?.session?.sessionId ?? int.tryParse(notification.data['session_id'] ?? '');
    if (sessionId == null) return 'No encontramos el turno de esta solicitud.';
    final result = accept ? await _sessionCases.acceptSessionRequest(sessionId) : await _sessionCases.rejectSessionRequest(sessionId);
    if (isClosed) return null;
    switch (result) {
      case Right():
        final resolved = accept ? SessionRequestState.accepted : SessionRequestState.rejected;
        final context = notification.context ?? const AdminNotificationContext();
        _replace(notification.id, (item) => item.copyWith(context: (item.context ?? context).resolvedByMe(resolved)));
        await markRead(notification);
        return null;
      case Left(:final failure):
        // Otro admin la respondió o venció: la lista trae el estado real.
        load(silent: true);
        return failure.message;
    }
  }

  void _replace(String id, AdminNotification Function(AdminNotification) change) {
    emit(state.copyWith(items: [for (final item in state.items) item.id == id ? change(item) : item]));
  }

  /// Al cerrar sesión: la bandeja es del admin.
  void clear() => emit(const NotificationsState());
}
