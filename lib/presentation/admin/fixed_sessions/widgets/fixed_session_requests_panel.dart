import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/links/entity_links.dart';
import '../../../../core/services/data_changes.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../domain/entities/fixed_session.dart';
import '../../../../domain/repositories/fixed_session_repository.dart';
import 'fixed_session_actions.dart';
import 'fixed_session_texts.dart';

/// Abre el panel lateral con los pedidos de turno fijo pendientes.
Future<void> openFixedSessionRequests(BuildContext context) {
  return showFixedSessionSidePanel<void>(context, FixedSessionRequestsSheet(host: context));
}

/// Los pedidos pendientes, primero los más viejos: de cada uno se ve qué
/// semanas están libres y se acepta o se rechaza.
class FixedSessionRequestsSheet extends StatefulWidget {
  const FixedSessionRequestsSheet({super.key, required this.host});

  /// La pantalla de abajo: desde ahí se abre la ficha del cliente al cerrar.
  final BuildContext host;

  @override
  State<FixedSessionRequestsSheet> createState() => _FixedSessionRequestsSheetState();
}

class _FixedSessionRequestsSheetState extends State<FixedSessionRequestsSheet> with ReloadOnDataChange {
  final _repository = sl<FixedSessionRepository>();

  bool _loading = true;
  String? _loadError;
  List<FixedSessionRequest> _items = [];

  /// Pedidos con una respuesta en curso.
  final _busy = <int>{};

  /// El error de la última respuesta de cada pedido.
  final _errors = <int, String>{};

  bool get _canResolve => Permissions.can(Permissions.TURNOS_FIJOS_CREAR);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.fixedSessions};

  @override
  void onDataChanged(DataChange change) => _load();

  Future<void> _load() async {
    final result = await _repository.pendingRequests();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Right(:final value):
          _items = value;
          _loadError = null;
        case Left(:final failure):
          _loadError = failure.message;
      }
    });
  }

  /// Después de responder: si no queda ninguno, el panel ya cumplió.
  Future<void> _afterResolved() async {
    await _load();
    if (mounted && _items.isEmpty && _loadError == null) Navigator.of(context).pop();
  }

  void _start(int id) => setState(() {
        _busy.add(id);
        _errors.remove(id);
      });

  void _fail(int id, String message) {
    setState(() {
      _busy.remove(id);
      _errors[id] = message;
    });
    // Puede que ya lo haya respondido otro admin.
    _load();
  }

  Future<void> _accept(FixedSessionRequest request) async {
    _start(request.id);
    final result = await _repository.acceptRequest(request.id);
    if (!mounted) return;
    switch (result) {
      case Right(:final value):
        setState(() => _busy.remove(request.id));
        await showFixedSessionCreated(context, value);
        await _afterResolved();
      case Left(:final failure):
        _fail(request.id, failure.message);
    }
  }

  Future<void> _reject(FixedSessionRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Rechazar el pedido?'),
        content: Text('Le vamos a avisar a ${request.client.fullName} que no se pudo aceptar. El horario sigue como está.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Rechazar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _start(request.id);
    final result = await _repository.rejectRequest(request.id);
    if (!mounted) return;
    switch (result) {
      case Right():
        setState(() => _busy.remove(request.id));
        await _afterResolved();
      case Left(:final failure):
        _fail(request.id, failure.message);
    }
  }

  void _openClient(int clientId) {
    final host = widget.host;
    Navigator.of(context).pop();
    if (host.mounted) openClient(host, clientId);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final width = math.min(480.0, MediaQuery.sizeOf(context).width);

    final Widget body;
    if (_loading) {
      body = const LinearProgressIndicator();
    } else if (_loadError != null && _items.isEmpty) {
      body = Text(_loadError!, style: TextStyle(color: scheme.error));
    } else if (_items.isEmpty) {
      body = Text('No hay pedidos pendientes.', style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant));
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, request) in _items.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            _RequestCard(
              key: ValueKey(request.id),
              request: request,
              canResolve: _canResolve,
              busy: _busy.contains(request.id),
              error: _errors[request.id],
              onAccept: () => _accept(request),
              onReject: () => _reject(request),
              onOpenClient: () => _openClient(request.client.clientId),
            ),
          ],
        ],
      );
    }

    return Material(
      color: scheme.surfaceContainer,
      elevation: 8,
      child: SizedBox(
        width: width,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.event_repeat, color: scheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pedidos de turno fijo', style: textTheme.titleLarge),
                          Text(
                            'Clientes que vienen seguido al mismo horario y quieren dejarlo fijo.',
                            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({
    super.key,
    required this.request,
    required this.canResolve,
    required this.busy,
    required this.error,
    required this.onAccept,
    required this.onReject,
    required this.onOpenClient,
  });

  final FixedSessionRequest request;
  final bool canResolve;
  final bool busy;
  final String? error;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onOpenClient;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  final _repository = sl<FixedSessionRepository>();

  List<FixedSessionOccurrence>? _preview;
  String? _previewError;

  @override
  void initState() {
    super.initState();
    if (widget.canResolve) _loadPreview();
  }

  Future<void> _loadPreview() async {
    final result = await _repository.preview(widget.request.draft);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Right(:final value):
          _preview = value;
        case Left(:final failure):
          _previewError = failure.message;
      }
    });
  }

  Widget _previewRow(ColorScheme scheme) {
    final preview = _preview;
    if (_previewError != null) return Text(_previewError!, style: TextStyle(fontSize: 13, color: scheme.error));
    if (preview == null) return const LinearProgressIndicator();

    final hasConflicts = preview.any((o) => o.status.isConflict);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          hasConflicts ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          size: 16,
          color: hasConflicts ? scheme.error : scheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            FixedSessionTexts.previewSummary(preview, widget.request.dayName.toLowerCase()),
            style: TextStyle(fontSize: 13, height: 1.35, color: scheme.onSurface),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final request = widget.request;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClientLink(
                  clientId: request.client.clientId,
                  name: request.client.fullName,
                  style: textTheme.titleSmall,
                  onTap: widget.onOpenClient,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Pedido el ${DateFormat('dd/MM').format(request.createdAt.toLocal())}',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(request.scheduleLabel, style: textTheme.bodyMedium),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
            child: Text(
              [request.sport, request.courtName].whereType<String>().join(' · '),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: scheme.onSecondaryContainer),
            ),
          ),
          const SizedBox(height: 8),
          Text(FixedSessionTexts.playsLabel(request.plays), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          if (widget.canResolve) ...[
            const SizedBox(height: 12),
            _previewRow(scheme),
          ],
          if (widget.error != null) ...[
            const SizedBox(height: 8),
            Text(widget.error!, style: TextStyle(fontSize: 13, color: scheme.error)),
          ],
          if (widget.canResolve) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: widget.busy ? null : widget.onReject, child: const Text('Rechazar')),
                const SizedBox(width: 8),
                FilledButton(onPressed: widget.busy ? null : widget.onAccept, child: const Text('Aceptar')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
