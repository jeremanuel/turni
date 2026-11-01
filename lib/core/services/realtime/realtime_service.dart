import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../config/environment.dart';
import '../data_changes.dart';

/// Estado de la conexión en vivo (el punto junto al avatar, ver
/// `RealtimeIndicator`).
enum RealtimeStatus {
  /// Sin sesión, o todavía no se intentó.
  idle,

  /// Primer intento de conexión (amarillo).
  connecting,

  /// Recibe los cambios en vivo (verde).
  connected,

  /// Se cortó y está reintentando solo (amarillo).
  reconnecting,

  /// Dejó de intentar: sin internet, servidor caído o sesión inválida
  /// (rojo). Vuelve a intentar con [RealtimeService.retry] o al volver a la
  /// app.
  disconnected,
}

/// Canal en tiempo real con el backend (socket.io, ver
/// turni_mono_be/docs/feature/REALTIME.md). El backend suma al admin a la
/// sala de su club al conectarse.
///
/// Solo avisa qué cambió: lo convierte en un [DataChange] del bus
/// [DataChanges] y cada pantalla vuelve a pedir sus datos a la API.
///
/// Si no funciona, el admin funciona igual: nada de esto bloquea ni tira
/// errores hacia las pantallas; solo no se actualizan solas (siguen
/// recargando al volver a la pestaña y con el botón de recargar).
class RealtimeService {
  RealtimeService._();

  static final RealtimeService instance = RealtimeService._();

  /// Intentos de reconexión antes de pasar a rojo.
  static const maxAttempts = 5;

  final ValueNotifier<RealtimeStatus> status = ValueNotifier(RealtimeStatus.idle);

  io.Socket? _socket;
  String? _token;
  bool _wasConnected = false;
  int _failedAttempts = 0;

  bool get isConnected => status.value == RealtimeStatus.connected;

  /// Abre la conexión con el JWT de la sesión. Si ya estaba conectado con el
  /// mismo token, no hace nada.
  void connect(String token) {
    if (_token == token && _socket != null) return;
    // Otra sesión: la próxima conexión es nueva, no una reconexión (no hay
    // nada "perdido" que recargar).
    if (_token != token) _wasConnected = false;
    _token = token;
    _open();
  }

  /// Al cerrar sesión.
  void disconnect() {
    _token = null;
    _wasConnected = false;
    _closeSocket();
    status.value = RealtimeStatus.idle;
  }

  /// "Reintentar" del indicador, o la vuelta a la app estando en rojo.
  void retry() {
    if (_token == null) return;
    if (status.value == RealtimeStatus.connected) return;
    _open();
  }

  void _open() {
    _closeSocket();
    final token = _token;
    if (token == null) return;
    _failedAttempts = 0;
    status.value = _wasConnected ? RealtimeStatus.reconnecting : RealtimeStatus.connecting;

    try {
      final url = kIsWeb ? Environment.apiUrl : Environment.apiNativeUrl;
      final socket = io.io(
        url,
        io.OptionBuilder()
            .setPath('/socket.io')
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .enableReconnection()
            .setReconnectionAttempts(maxAttempts)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(10000)
            .setTimeout(10000)
            .disableAutoConnect()
            .build(),
      );

      socket.onConnect((_) => _onConnected());
      socket.onDisconnect((_) => _onDisconnected());
      socket.onConnectError((error) => _onFailedAttempt(error));
      socket.onReconnectAttempt((_) {
        if (status.value != RealtimeStatus.disconnected) status.value = RealtimeStatus.reconnecting;
      });
      socket.onReconnectFailed((_) => status.value = RealtimeStatus.disconnected);
      socket.on('data:changed', _onDataChanged);

      _socket = socket;
      socket.connect();
    } catch (error) {
      debugPrint('[realtime] no se pudo abrir la conexión: $error');
      status.value = RealtimeStatus.disconnected;
    }
  }

  void _onConnected() {
    final reconnected = _wasConnected;
    _wasConnected = true;
    _failedAttempts = 0;
    status.value = RealtimeStatus.connected;
    // Mientras estuvo desconectado se pudo perder algún cambio: la pantalla
    // abierta recarga lo que muestra.
    if (reconnected) DataChanges.notify(DataChange(DataTopic.values.toSet()));
  }

  void _onDisconnected() {
    if (_token == null) return;
    if (status.value == RealtimeStatus.connected) status.value = RealtimeStatus.reconnecting;
  }

  void _onFailedAttempt(dynamic error) {
    _failedAttempts++;
    // Token inválido: reintentar no sirve hasta que cambie la sesión.
    final unauthorized = '$error'.contains('unauthorized');
    if (unauthorized || _failedAttempts > maxAttempts) {
      _closeSocket();
      status.value = RealtimeStatus.disconnected;
    } else if (status.value != RealtimeStatus.connecting) {
      status.value = RealtimeStatus.reconnecting;
    }
  }

  void _onDataChanged(dynamic payload) {
    try {
      final map = payload is Map ? Map<String, dynamic>.from(payload) : const <String, dynamic>{};
      final topics = topicsForRealtime((map['topics'] as List? ?? const []).map((t) => '$t'));
      final ids = map['ids'] is Map ? Map<String, dynamic>.from(map['ids'] as Map) : const <String, dynamic>{};
      DataChanges.notify(DataChange(topics, data: ids));
    } catch (error) {
      debugPrint('[realtime] aviso inválido: $error');
    }
  }

  void _closeSocket() {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    try {
      socket.clearListeners();
      socket.dispose();
    } catch (_) {}
  }
}

/// Temas del backend → temas del admin (los mismos, ver [DataTopic]).
Set<DataTopic> topicsForRealtime(Iterable<String> topics) {
  final result = <DataTopic>{};
  for (final topic in topics) {
    final match = switch (topic) {
      'sessions' => DataTopic.sessions,
      'availability' => DataTopic.availability,
      'payments' => DataTopic.payments,
      'fixed_sessions' => DataTopic.fixedSessions,
      'clients' => DataTopic.clients,
      'tournaments' => DataTopic.tournaments,
      'matches' => DataTopic.matches,
      'club_config' => DataTopic.clubConfig,
      'admins' => DataTopic.admins,
      'gym' => DataTopic.gym,
      'notifications' => DataTopic.notifications,
      _ => null,
    };
    if (match != null) result.add(match);
  }
  return result;
}
