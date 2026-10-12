import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/links/entity_links.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/fixed_session.dart';
import '../../../../domain/repositories/fixed_session_repository.dart';
import '../../fixed_sessions/widgets/fixed_session_actions.dart';

/// Turnos fijos del cliente en su ficha: los que tiene como titular o como
/// integrante, con sus próximos días (los cancelados tachados) y acciones.
class ClientFixedSessions extends StatefulWidget {
  const ClientFixedSessions({super.key, required this.client, this.onChanged});

  final Client client;

  /// Algo cambió (alta, cancelación): la ficha recarga su resumen.
  final VoidCallback? onChanged;

  @override
  State<ClientFixedSessions> createState() => _ClientFixedSessionsState();
}

class _ClientFixedSessionsState extends State<ClientFixedSessions> {
  final _repository = sl<FixedSessionRepository>();

  bool _loading = true;
  String? _error;
  List<FixedSession> _items = [];

  int get _clientId => widget.client.intClientId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.list(clientId: _clientId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Right(:final value):
          _items = value;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  void _changed() {
    _load();
    widget.onChanged?.call();
  }

  Future<void> _onAction(String action, FixedSession item) async {
    final changed = switch (action) {
      'participants' => await editFixedSessionParticipants(context, item) != null,
      'cancel' => await cancelFixedSession(context, item.ref, place: [item.sport, item.courtName].whereType<String>().join(' · ')),
      _ => false,
    };
    if (changed) _changed();
  }

  @override
  Widget build(BuildContext context) {
    if (!Permissions.can(Permissions.TURNOS_FIJOS_VER)) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final canCreate = Permissions.can(Permissions.TURNOS_FIJOS_CREAR);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_repeat, color: scheme.tertiary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Turnos fijos', style: textTheme.titleMedium)),
                if (canCreate)
                  TextButton.icon(
                    onPressed: () async {
                      if (await openNewFixedSession(context, client: widget.client) != null) _changed();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo turno fijo'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator()
            else if (_error != null)
              Text(_error!, style: TextStyle(color: scheme.error))
            else if (_items.isEmpty)
              Text('No tiene turnos fijos.', style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 640 ? 2 : 1;
                  final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [for (final item in _items) SizedBox(width: width, child: _card(item))],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(FixedSession item) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOwner = item.client.clientId == _clientId;
    final canCreate = Permissions.can(Permissions.TURNOS_FIJOS_CREAR);
    final canCancel = Permissions.can(Permissions.TURNOS_FIJOS_CANCELAR);

    final sessionByDay = {
      for (final u in item.upcoming) DateFormat('yyyy-MM-dd').format(u.startTime.toLocal()): u.sessionId,
    };
    final days = {...sessionByDay.keys, ...item.cancelledDates, ...item.missingDates}.toList()..sort();
    final chips = days.take(5).map((day) {
      final cancelled = item.cancelledDates.contains(day);
      final missing = item.missingDates.contains(day);
      final sessionId = cancelled || missing ? null : sessionByDay[day];
      return (DateFormat('dd/MM').format(DateTime.parse(day)), cancelled, missing, sessionId);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('${item.dayName} ${item.startTime}', style: textTheme.titleLarge?.copyWith(fontSize: 18))),
              Text('${item.duration} min', style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
            child: Text(
              [item.sport, item.courtName].whereType<String>().join(' · '),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: scheme.onSecondaryContainer),
            ),
          ),
          const SizedBox(height: 8),
          isOwner
              ? ClientLinksText.people(
                  [for (final p in item.participants) (p.clientId, p.fullName)],
                  prefix: item.participants.isEmpty ? 'Titular' : 'Titular · con ',
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                )
              : ClientLinksText(
                  [const LinkSegment.text('Integrante del turno de '), LinkSegment.client(item.client.clientId, item.client.fullName)],
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (label, cancelled, missing, sessionId) in chips)
                  Tooltip(
                    message: cancelled ? 'Cancelado' : (missing ? 'Horario ocupado: sin turno' : 'Ver turno en la agenda'),
                    child: HoverLink(
                      onTap: sessionId == null ? null : () => openSession(context, sessionId),
                      builder: (context, hovered) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cancelled ? scheme.tertiary : (missing ? scheme.error : scheme.outlineVariant),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: cancelled ? scheme.onTertiaryContainer : (missing ? scheme.error : scheme.onSurface),
                          decoration: cancelled
                              ? TextDecoration.lineThrough
                              : (hovered ? TextDecoration.underline : null),
                        ),
                      ),
                    ),
                    ),
                  ),
              ],
            ),
          ],
          if (isOwner && (canCreate || canCancel)) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (canCancel)
                  OutlinedButton(onPressed: () => _onAction('cancel', item), child: const Text('Cancelar…')),
                if (canCreate) ...[
                  const SizedBox(width: 8),
                  TextButton(onPressed: () => _onAction('participants', item), child: const Text('Integrantes')),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
