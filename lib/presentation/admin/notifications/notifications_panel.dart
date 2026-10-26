import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/onboarding/tour_anchor.dart';
import '../../../domain/entities/admin_notification.dart';
import 'notifications_cubit.dart';

/// Cuándo llegó un aviso, corto: "Recién", "Hace 5 min", "Hoy 18:30",
/// "Ayer 09:15" o "12/10 · 18:30".
String notificationTimeLabel(DateTime at, DateTime now) {
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return 'Recién';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';

  final hhmm = DateFormat('HH:mm').format(at);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  if (day == today) return 'Hoy $hhmm';
  if (day == today.subtract(const Duration(days: 1))) return 'Ayer $hhmm';
  return '${DateFormat('dd/MM').format(at)} · $hhmm';
}

/// Ícono de la categoría de un aviso (`SESSION`, `PAYMENT`, `TOURNAMENT`, `GYM`).
IconData notificationIconFor(String category) => switch (category) {
      'SESSION' => Icons.event_outlined,
      'PAYMENT' => Icons.payments_outlined,
      'TOURNAMENT' => Icons.emoji_events_outlined,
      'GYM' => Icons.fitness_center,
      _ => Icons.notifications_outlined,
    };

/// Campanita con la cantidad de avisos sin leer. Abre [showNotificationsPanel].
/// Va en el menú lateral (escritorio) y en la barra superior (celular).
class NotificationsButton extends StatefulWidget {
  const NotificationsButton({super.key, this.cubit});

  final NotificationsCubit? cubit;

  @override
  State<NotificationsButton> createState() => _NotificationsButtonState();
}

class _NotificationsButtonState extends State<NotificationsButton> {
  late final NotificationsCubit _cubit = widget.cubit ?? sl<NotificationsCubit>();

  @override
  void initState() {
    super.initState();
    // Los avisos que llegaron mientras el panel estaba cerrado.
    _cubit.refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NotificationsCubit, NotificationsState, int>(
      bloc: _cubit,
      selector: (state) => state.unread,
      builder: (context, unread) => TourAnchor(
        id: 'nav.notifications',
        // La guía de avisos abre la bandeja (sin esperar a que se cierre).
        onActivate: (context) {
          showNotificationsPanel(context, cubit: _cubit);
        },
        child: IconButton(
          tooltip: 'Notificaciones',
          onPressed: () => showNotificationsPanel(context, cubit: _cubit),
          icon: Badge.count(
            count: unread,
            isLabelVisible: unread > 0,
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
      ),
    );
  }
}

/// Bandeja de avisos: diálogo en escritorio, pantalla completa en el celular.
Future<void> showNotificationsPanel(BuildContext context, {NotificationsCubit? cubit}) {
  final bloc = cubit ?? sl<NotificationsCubit>();
  final compact = MediaQuery.sizeOf(context).width < 600;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final panel = NotificationsPanel(cubit: bloc);
      if (compact) return Dialog.fullscreen(child: panel);
      return Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
          child: panel,
        ),
      );
    },
  );
}

/// El contenido de la bandeja: los avisos de a 20, cargando más al llegar al
/// final. Tocar uno lo marca leído y lleva al turno o al torneo.
class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key, required this.cubit, this.now});

  final NotificationsCubit cubit;
  final DateTime Function()? now;

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  NotificationsCubit get _cubit => widget.cubit;

  @override
  void initState() {
    super.initState();
    // Si ya estaba cargada, se ve lo que había mientras se actualiza.
    _cubit.load(silent: _cubit.state.loaded);
  }

  Future<void> _open(AdminNotification notification) async {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    await _cubit.markRead(notification);
    router.go(adminNotificationLocation({...notification.data, 'type': notification.type}));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return BlocBuilder<NotificationsCubit, NotificationsState>(
      bloc: _cubit,
      builder: (context, state) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
            child: Row(
              children: [
                Expanded(child: Text('Notificaciones', style: text.titleLarge)),
                // En el celular no entra el texto al lado del título.
                TourAnchor(
                  id: 'notifications.readAll',
                  child: MediaQuery.sizeOf(context).width < 480
                      ? IconButton(
                          tooltip: 'Marcar todo como leído',
                          icon: const Icon(Icons.done_all),
                          onPressed: state.unread > 0 ? _cubit.markAllRead : null,
                        )
                      : TextButton(
                          onPressed: state.unread > 0 ? _cubit.markAllRead : null,
                          child: const Text('Marcar todo como leído'),
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
          Flexible(child: TourAnchor(id: 'notifications.panel', child: _body(context, state))),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, NotificationsState state) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (state.loading && state.items.isEmpty) {
      return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));
    }
    if (state.error != null && state.items.isEmpty) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        title: 'No pudimos cargar los avisos',
        action: OutlinedButton(onPressed: _cubit.load, child: const Text('Reintentar')),
      );
    }
    if (state.items.isEmpty) {
      return const _Message(
        icon: Icons.notifications_none,
        title: 'No hay avisos',
        message: 'Acá vas a ver las solicitudes de turno, las señas y las novedades de los torneos.',
      );
    }

    final now = (widget.now ?? DateTime.now)();
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => Divider(height: 1, indent: 72, color: scheme.outlineVariant),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          // Llegó al final: pide la página siguiente.
          WidgetsBinding.instance.addPostFrameCallback((_) => _cubit.loadMore());
          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
        }
        final notification = state.items[index];
        final unread = !notification.isRead;
        return ListTile(
          onTap: () => _open(notification),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: unread ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            foregroundColor: unread ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            child: Icon(notificationIconFor(notification.category), size: 20),
          ),
          title: Text(
            notification.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall?.copyWith(
              fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
              color: unread ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.body.isNotEmpty)
                Text(notification.body, maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                notificationTimeLabel(notification.createdAt, now),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          trailing: unread ? Badge(smallSize: 10, backgroundColor: scheme.primary) : null,
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
