import 'package:flutter/material.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/either.dart';
import '../../../domain/entities/notification_history.dart';
import '../../../domain/repositories/notification_history_repository.dart';
import 'notification_history_list.dart';

/// "Avisos" en el panel del turno: los avisos que salieron por este turno,
/// a los clientes y a los admins, con cómo se entregó cada uno. Arranca
/// cerrada y carga al abrirla, así no se pide nada por cada turno que se toca.
class SessionNotificationsSection extends StatefulWidget {
  const SessionNotificationsSection({super.key, required this.sessionId, this.repository});

  final int sessionId;

  /// Para tests; por defecto, el del service locator.
  final NotificationHistoryRepository? repository;

  @override
  State<SessionNotificationsSection> createState() => _SessionNotificationsSectionState();
}

class _SessionNotificationsSectionState extends State<SessionNotificationsSection> {
  late final NotificationHistoryRepository _repository = widget.repository ?? sl<NotificationHistoryRepository>();

  bool _open = false;
  bool _loading = false;
  List<NotificationHistoryEntry>? _entries;
  String? _error;

  @override
  void didUpdateWidget(covariant SessionNotificationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _entries = null;
      _error = null;
      if (_open) _load();
    }
  }

  Future<void> _load() async {
    final sessionId = widget.sessionId;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getSessionNotifications(sessionId);
    if (!mounted || sessionId != widget.sessionId) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Right(:final value):
          _entries = value;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open && _entries == null && !_loading) _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget body;
    if (_loading) {
      body = const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator());
    } else if (_error != null) {
      body = Row(
        children: [
          Expanded(child: Text(_error!, style: TextStyle(fontSize: 13, color: scheme.error))),
          TextButton(onPressed: _load, child: const Text('Reintentar')),
        ],
      );
    } else {
      body = NotificationHistoryList(
        entries: _entries ?? const [],
        emptyText: 'No salió ningún aviso por este turno.',
        showRecipient: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('Avisos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface)),
                ),
                if (_open && _entries != null && !_loading)
                  IconButton(
                    tooltip: 'Actualizar',
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                  ),
                Icon(_open ? Icons.expand_less : Icons.expand_more, size: 20, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        if (!_open)
          Text('Qué se le avisó a quién y si llegó.', style: TextStyle(fontSize: 12, color: scheme.outline))
        else
          body,
      ],
    );
  }
}
