import 'package:flutter/material.dart';
import '../../../../../core/utils/permissions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/config/router/app_routes.dart';
import '../../../../../core/presentation/components/inputs/client_search_field.dart';
import '../../../../../domain/entities/client.dart';
import '../../../../../domain/entities/session.dart';
import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';
import 'panel_common.dart';
import '../../../../../core/presentation/components/onboarding/tour_anchor.dart';

/// Turno libre: precio y "Reservar para" (buscador de clientes: recientes,
/// búsqueda o crear uno nuevo).
class FreeSessionView extends StatefulWidget {
  const FreeSessionView({super.key, required this.session, required this.header, required this.onCreateClient});

  final Session session;
  final Widget header;
  /// "Crear cliente" del buscador, con lo escrito.
  final ValueChanged<String> onCreateClient;

  @override
  State<FreeSessionView> createState() => _FreeSessionViewState();
}

class _FreeSessionViewState extends State<FreeSessionView> {
  Client? _picked;
  bool _reserving = false;

  @override
  void didUpdateWidget(covariant FreeSessionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.sessionId != widget.session.sessionId) {
      _picked = null;
      _reserving = false;
    }
  }

  void _reserve() {
    setState(() => _reserving = true);
    context.read<SessionManagerBloc>().add(ReserveEvent(widget.session, _picked!));
    // Si la reserva falla el turno sigue libre: se vuelve a habilitar.
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _reserving = false);
    });
  }

  Future<void> _delete() async {
    final ok = await confirmPanelAction(
      context,
      title: 'Eliminar turno',
      message: 'El turno se borra de la agenda. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (!ok || !mounted) return;
    context.read<SessionManagerBloc>().add(DeleteSession(widget.session.sessionId));
    context.go(AppRoutes.SESSION_MANAGER_ROUTE.path);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PanelFrame(
      footer: Row(
        children: [
          if (Permissions.can(Permissions.AGENDA_ELIMINAR)) PanelTextButton(label: 'Eliminar turno', color: scheme.error, onPressed: _delete),
          const Spacer(),
          TourAnchor(
            id: 'session.free.reserve',
            child: PanelFilledButton(
              label: 'Reservar turno',
              icon: Icons.check,
              loading: _reserving,
              onPressed: _picked == null || !Permissions.can(Permissions.AGENDA_RESERVAR) ? null : _reserve,
            ),
          ),
        ],
      ),
      children: [
        widget.header,
        TourAnchor(
          id: 'session.free.price',
          child: PanelCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Precio del turno', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                Text(
                  panelPrice(widget.session.price),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: scheme.onSurface),
                ),
              ],
            ),
          ),
        ),
        TourAnchor(
          id: 'session.free.client',
          child: ClientSearchField(
            label: 'Reservar para',
            value: _picked,
            enabled: Permissions.can(Permissions.AGENDA_RESERVAR),
            onChanged: (client) => setState(() => _picked = client),
            onCreate: (query) async {
              widget.onCreateClient(query);
              return null;
            },
          ),
        ),
      ],
    );
  }
}
