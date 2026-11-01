import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/components/links/entity_links.dart';
import '../../../domain/entities/notification_history.dart';
import 'notifications_panel.dart';

/// Qué tan bien salió un aviso, para elegir el color.
enum DeliveryTone { ok, warning, error, neutral }

/// Cómo salió un aviso, en una línea: "Entregado", "No salió · reintenta
/// 18:30", "Sin dispositivos con la app"... [detail] es el motivo técnico
/// (el último error), para un tooltip.
class DeliverySummary {
  final String label;
  final DeliveryTone tone;
  final String? detail;

  const DeliverySummary(this.label, this.tone, {this.detail});
}

String _plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';

/// Cuándo se reintenta (a futuro): "a las 18:30", "mañana a las 09:15" o "el 12/10 a las 18:30".
String retryTimeLabel(DateTime at, DateTime now) {
  final hhmm = DateFormat('HH:mm').format(at);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  if (!day.isAfter(today)) return 'a las $hhmm';
  if (day == today.add(const Duration(days: 1))) return 'mañana a las $hhmm';
  return 'el ${DateFormat('dd/MM').format(at)} a las $hhmm';
}

DeliverySummary _summaryOf(NotificationDelivery d, DateTime now) {
  final channel = d.isEmail ? 'mail' : 'push';
  return switch (d.status) {
    DeliveryStatus.sent => DeliverySummary(
        d.isEmail ? 'Mail enviado' : (d.targets > 1 ? 'Entregado en ${_plural(d.succeeded, 'dispositivo', 'dispositivos')}' : 'Entregado'),
        DeliveryTone.ok,
      ),
    DeliveryStatus.partial => DeliverySummary(
        'Entregado en ${d.succeeded} de ${_plural(d.targets, 'dispositivo', 'dispositivos')}',
        DeliveryTone.ok,
        detail: d.lastError,
      ),
    DeliveryStatus.failed => DeliverySummary(
        switch (d.nextAttemptAt) {
          null => 'No salió el $channel',
          // La hora ya pasó: lo toma el próximo sweep, que corre cada hora.
          final next when !next.isAfter(now) => 'No salió el $channel · reintento pendiente',
          final next => 'No salió el $channel · reintenta ${retryTimeLabel(next, now)}',
        },
        DeliveryTone.error,
        detail: d.lastError,
      ),
    DeliveryStatus.skipped => DeliverySummary(
        d.isEmail ? 'Mail no enviado' : 'Sin dispositivos con la app',
        DeliveryTone.warning,
        detail: d.lastError,
      ),
    DeliveryStatus.pending => const DeliverySummary('Enviando…', DeliveryTone.neutral),
    DeliveryStatus.unknown => DeliverySummary('Estado desconocido', DeliveryTone.neutral, detail: d.lastError),
  };
}

/// Una línea por canal. Sin entregas (se borran a los 30 días), lo dice.
List<DeliverySummary> deliverySummaries(NotificationHistoryEntry entry, DateTime now) {
  if (entry.deliveries.isEmpty) {
    return const [DeliverySummary('Sin datos de entrega', DeliveryTone.neutral, detail: 'Se guardan 30 días.')];
  }
  return [for (final d in entry.deliveries) _summaryOf(d, now)];
}

/// Un aviso del historial: qué se mandó, cuándo, a quién (si [showRecipient])
/// y cómo salió. Con [showSession], un link al turno del aviso.
class NotificationHistoryTile extends StatelessWidget {
  const NotificationHistoryTile({
    super.key,
    required this.entry,
    this.showRecipient = false,
    this.showSession = false,
    this.now,
  });

  final NotificationHistoryEntry entry;
  final bool showRecipient;
  final bool showSession;

  /// Para tests; por defecto, ahora.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final at = now ?? DateTime.now();
    final muted = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    Color toneColor(DeliveryTone tone) => switch (tone) {
          DeliveryTone.ok => scheme.primary,
          // tertiary es casi del mismo tono que error en dark: no se distinguirían.
          DeliveryTone.warning => scheme.secondary,
          DeliveryTone.error => scheme.error,
          DeliveryTone.neutral => scheme.outline,
        };

    final recipient = entry.recipientName ?? (entry.isForAdmin ? 'Administrador' : 'Cliente');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(notificationIconFor(entry.category), size: 18, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: scheme.onSurface),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(notificationTimeLabel(entry.createdAt, at), style: muted),
                  ],
                ),
                if (entry.body.isNotEmpty)
                  Text(entry.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: muted),
                if (showRecipient)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Text('Para ', style: muted),
                        Flexible(
                          child: ClientLink(
                            clientId: entry.isForAdmin ? null : entry.recipientClientId,
                            name: recipient,
                            style: muted.copyWith(color: scheme.onSurface),
                          ),
                        ),
                        if (entry.isForAdmin) Text(' · app de administración', style: muted),
                      ],
                    ),
                  ),
                if (showSession && entry.sessionId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: HoverLink(
                      onTap: () => openSession(context, entry.sessionId!),
                      builder: (context, hovered) => Text('Ver turno', style: linkStyle(muted.copyWith(color: scheme.primary), hovered)),
                    ),
                  ),
                const SizedBox(height: 4),
                for (final summary in deliverySummaries(entry, at))
                  Tooltip(
                    message: summary.detail ?? '',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: toneColor(summary.tone), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Flexible(child: Text(summary.label, style: muted.copyWith(color: toneColor(summary.tone)))),
                      ],
                    ),
                  ),
                if (entry.readAt != null)
                  Text('Visto en la app ${notificationTimeLabel(entry.readAt!, at).toLowerCase()}', style: muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de avisos con separadores, o el texto de vacío.
class NotificationHistoryList extends StatelessWidget {
  const NotificationHistoryList({
    super.key,
    required this.entries,
    required this.emptyText,
    this.showRecipient = false,
    this.showSession = false,
  });

  final List<NotificationHistoryEntry> entries;
  final String emptyText;
  final bool showRecipient;
  final bool showSession;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (entries.isEmpty) {
      return Text(emptyText, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, entry) in entries.indexed) ...[
          if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
          NotificationHistoryTile(entry: entry, showRecipient: showRecipient, showSession: showSession),
        ],
      ],
    );
  }
}
