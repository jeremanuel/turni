import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/loading/app_skeleton.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/notification_history.dart';
import '../../../../domain/repositories/notification_history_repository.dart';
import '../../notifications/notification_history_list.dart';

/// Avisos de la ficha: lo que se le mandó al cliente desde este club (turnos,
/// pagos, torneos) y si le llegó. Sirve para "no me llegó la confirmación".
class ClientNotificationsCard extends StatefulWidget {
  const ClientNotificationsCard({super.key, required this.clientId, this.repository});

  final int clientId;

  /// Para tests; por defecto, el del service locator.
  final NotificationHistoryRepository? repository;

  @override
  State<ClientNotificationsCard> createState() => _ClientNotificationsCardState();
}

class _ClientNotificationsCardState extends State<ClientNotificationsCard> {
  late final NotificationHistoryRepository _repository = widget.repository ?? sl<NotificationHistoryRepository>();

  final _entries = <NotificationHistoryEntry>[];
  bool _hasAppAccount = true;
  String? _nextCursor;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getClientNotifications(widget.clientId, cursor: more ? _nextCursor : null);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Right(:final value):
          if (!more) _entries.clear();
          _entries.addAll(value.notifications);
          _hasAppAccount = value.hasAppAccount;
          _nextCursor = value.nextCursor;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 13, color: scheme.onSurfaceVariant);

    final children = <Widget>[
      if (!_hasAppAccount)
        Text('No tiene cuenta en la app: los avisos no le llegan.', style: muted)
      else if (_entries.isNotEmpty || !_loading)
        NotificationHistoryList(
          entries: _entries,
          emptyText: 'Todavía no se le mandó ningún aviso.',
          showSession: true,
        ),
      if (_error != null)
        LoadError(message: _error!, onRetry: () => _load(more: _entries.isNotEmpty)),
      if (_loading && _entries.isEmpty)
        const SkeletonRows()
      else if (_loading)
        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator())
      else if (_nextCursor != null && _error == null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: () => _load(more: true), child: const Text('Ver más')),
        ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Avisos', style: Theme.of(context).textTheme.titleMedium)),
                IconButton(
                  tooltip: 'Actualizar',
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _loading ? null : () => _load(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}
