import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../domain/entities/admin_notification.dart';
import '../../../domain/repositories/notification_repository.dart';

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

class NotificationsState {
  /// Avisos sin leer (el badge de la campanita).
  final int unread;
  final List<AdminNotification> items;
  final String? nextCursor;

  /// Primera carga de la lista, con spinner.
  final bool loading;
  final bool loadingMore;

  /// La lista ya se pidió alguna vez: a partir de ahí se refresca sola.
  final bool loaded;
  final DomainError? error;

  const NotificationsState({
    this.unread = 0,
    this.items = const [],
    this.nextCursor,
    this.loading = false,
    this.loadingMore = false,
    this.loaded = false,
    this.error,
  });

  bool get hasMore => nextCursor != null;

  NotificationsState copyWith({
    int? unread,
    List<AdminNotification>? items,
    String? Function()? nextCursor,
    bool? loading,
    bool? loadingMore,
    bool? loaded,
    DomainError? Function()? error,
  }) =>
      NotificationsState(
        unread: unread ?? this.unread,
        items: items ?? this.items,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        loaded: loaded ?? this.loaded,
        error: error != null ? error() : this.error,
      );
}

/// La bandeja de avisos del admin. Vive toda la app (la campanita del menú y
/// el panel comparten el estado) y se refresca con cada push que llega
/// ([pushes], ver `PushNotificationService.messages`).
class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationRepository _repository;
  final DateTime Function() _now;
  StreamSubscription<Map<String, dynamic>>? _pushes;

  NotificationsCubit({
    NotificationRepository? repository,
    Stream<Map<String, dynamic>>? pushes,
    DateTime Function()? now,
  })  : _repository = repository ?? sl<NotificationRepository>(),
        _now = now ?? DateTime.now,
        super(const NotificationsState()) {
    _pushes = pushes?.listen((_) {
      refreshUnread();
      if (state.loaded) load(silent: true);
    });
  }

  @override
  Future<void> close() {
    _pushes?.cancel();
    return super.close();
  }

  Future<void> refreshUnread() async {
    final result = await _repository.getUnreadCount();
    if (isClosed) return;
    if (result case Right(:final value)) emit(state.copyWith(unread: value));
  }

  /// La primera página. `silent`: por un aviso nuevo, sin spinner.
  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(loading: true, error: () => null));
    final result = await _repository.getNotifications();
    if (isClosed) return;
    switch (result) {
      case Right(:final value):
        emit(state.copyWith(
          items: value.notifications,
          nextCursor: () => value.nextCursor,
          loading: false,
          loaded: true,
          error: () => null,
        ));
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
        emit(state.copyWith(
          items: [...state.items, ...value.notifications.where((n) => !known.contains(n.id))],
          nextCursor: () => value.nextCursor,
          loadingMore: false,
        ));
      case Left():
        emit(state.copyWith(loadingMore: false));
    }
  }

  /// Se marca en el momento; si el back falla, el próximo refresco lo corrige.
  Future<void> markRead(AdminNotification notification) async {
    if (notification.isRead) return;
    final now = _now();
    emit(state.copyWith(
      items: [for (final item in state.items) item.id == notification.id ? item.markedRead(now) : item],
      unread: state.unread > 0 ? state.unread - 1 : 0,
    ));
    await _repository.markRead(notification.id);
  }

  Future<void> markAllRead() async {
    final now = _now();
    emit(state.copyWith(items: [for (final item in state.items) item.markedRead(now)], unread: 0));
    await _repository.markAllRead();
  }

  /// Al cerrar sesión: la bandeja es del admin.
  void clear() => emit(const NotificationsState());
}
