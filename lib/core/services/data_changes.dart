import 'dart:async';

import 'package:flutter/widgets.dart';

import 'realtime/realtime_service.dart';

/// Qué parte de los datos del club cambió en el servidor (mismos temas que
/// el backend, ver turni_mono_be/docs/feature/REALTIME.md). Las pantallas se
/// suscriben a temas: no les importa de dónde vino el aviso (el canal en
/// tiempo real o la vuelta a la pestaña).
enum DataTopic {
  sessions,
  availability,
  payments,
  fixedSessions,
  clients,
  tournaments,
  matches,
  clubConfig,
  admins,

  /// Rutinas, progresos y abonos del gimnasio.
  gym,

  /// Llegó (o se leyó) un aviso de la bandeja.
  notifications,
}

/// Un aviso de que algo cambió. [data] trae los ids que haya
/// (`session_id`, `tournament_id`, ...) para que cada pantalla decida si le
/// toca; vacío = puede ser cualquiera.
class DataChange {
  final Set<DataTopic> topics;
  final Map<String, dynamic> data;

  const DataChange(this.topics, {this.data = const {}});

  int? id(String key) => int.tryParse('${data[key] ?? ''}');

  /// `true` si el aviso no dice de qué [key] se trata o si es [value].
  bool isFor(String key, int? value) {
    final changed = id(key);
    return changed == null || value == null || changed == value;
  }
}

/// Bus de "datos que cambiaron". Lo alimentan el canal en tiempo real (ver
/// `RealtimeService`) y la vuelta a la pestaña; lo escuchan las pantallas
/// (ver [ReloadOnDataChange]) y los blocs.
class DataChanges {
  DataChanges._();

  static final _controller = StreamController<DataChange>.broadcast();

  static Stream<DataChange> get stream => _controller.stream;

  static void notify(DataChange change) {
    if (change.topics.isEmpty) return;
    _controller.add(change);
  }

  /// Avisos de alguno de [topics].
  static Stream<DataChange> on(Set<DataTopic> topics) =>
      stream.where((change) => change.topics.any(topics.contains));

  /// Tiempo mínimo afuera para recargar al volver: sin esto, cada vistazo a
  /// otra pestaña recargaría la pantalla.
  static const _minTimeAway = Duration(seconds: 5);

  static _LifecycleWatcher? _watcher;

  /// Al volver a la pestaña: reintenta el canal si quedó en rojo y, si pasó
  /// un rato, recarga lo visible (lo que pudo cambiar sin canal). Se llama
  /// una vez en `main`.
  static void watchAppLifecycle() {
    if (_watcher != null) return;
    _watcher = _LifecycleWatcher();
    WidgetsBinding.instance.addObserver(_watcher!);
  }
}

class _LifecycleWatcher with WidgetsBindingObserver {
  DateTime? _leftAt;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      _leftAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final leftAt = _leftAt;
      _leftAt = null;
      RealtimeService.instance.retry();
      if (leftAt != null && DateTime.now().difference(leftAt) >= DataChanges._minTimeAway) {
        DataChanges.notify(DataChange(DataTopic.values.toSet()));
      }
    }
  }
}

/// Recarga la pantalla cuando cambia alguno de sus [refreshTopics]. La
/// pantalla define [onDataChanged] (casi siempre su carga, en silencio) y,
/// si quiere filtrar por id, [shouldReload].
mixin ReloadOnDataChange<T extends StatefulWidget> on State<T> {
  StreamSubscription<DataChange>? _dataChanges;

  Set<DataTopic> get refreshTopics;

  bool shouldReload(DataChange change) => true;

  void onDataChanged(DataChange change);

  @override
  void initState() {
    super.initState();
    _dataChanges = DataChanges.on(refreshTopics).listen((change) {
      if (!mounted) return;
      if (shouldReload(change)) onDataChanged(change);
    });
  }

  @override
  void dispose() {
    _dataChanges?.cancel();
    super.dispose();
  }
}
