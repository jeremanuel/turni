import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/app_routes.dart';
import '../../../../core/utils/admin_vocabulary.dart';
import '../../../../core/utils/permissions.dart';
import '../../browser/browser.dart';
import '../../browser/browser_options.dart';
import '../../bulk_sessions/bulk_sessions_page.dart';
import '../bloc/session_manager_bloc.dart';
import '../bloc/session_manager_event.dart';
import '../bloc/session_manager_state.dart';
import 'side_panel/day_summary_panel.dart';
import '../../../../core/presentation/components/onboarding/tour_anchor.dart';

/// Celular: lo que en escritorio está en la barra de arriba y en el panel
/// lateral de la agenda (diseño "Admin mobile"): ir a hoy, buscar un cliente
/// o turno y el resumen del día con las solicitudes por aprobar.
class MobileAgendaToolbar extends StatelessWidget {
  const MobileAgendaToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      buildWhen: (p, c) =>
          p.currentDate != c.currentDate || p.sessions != c.sessions || p.selectedClubPartition != c.selectedClubPartition,
      builder: (context, state) {
        final courtIds = (state.selectedClubPartition?.physicalPartitions ?? const []).map((c) => c.partitionPhysicalId).toSet();
        final pending = state.sessions.where((s) => courtIds.contains(s.partitionPhysicalId) && s.isPending).length;
        final now = DateTime.now();
        final isToday = state.currentDate.year == now.year && state.currentDate.month == now.month && state.currentDate.day == now.day;

        return Row(
          children: [
            TextButton.icon(
              onPressed: isToday ? null : () => context.read<SessionManagerBloc>().add(SessionChangeDateEvent(DateTime.now())),
              icon: const Icon(Icons.today_outlined, size: 20),
              label: const Text('Hoy'),
              // Ícono alineado con el borde de la agenda.
              style: TextButton.styleFrom(padding: const EdgeInsets.fromLTRB(0, 10, 14, 10)),
            ),
            const Spacer(),
            TourAnchor(
              id: 'agenda.search',
              child: IconButton(
                tooltip: 'Buscar cliente o turno',
                icon: const Icon(Icons.search),
                onPressed: () => _openSearch(context, state),
              ),
            ),
            TourAnchor(
              id: 'agenda.summary',
              child: IconButton(
              padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
              tooltip: pending == 0 ? 'Resumen del día' : 'Resumen del día · $pending por aprobar',
              icon: Badge(
                isLabelVisible: pending > 0,
                label: Text('$pending'),
                backgroundColor: scheme.error,
                child: const Icon(Icons.insights_outlined),
              ),
              onPressed: () => _openSummary(context),
            ),
            ),
          ],
        );
      },
    );
  }

  void _openSearch(BuildContext context, SessionManagerState state) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.fromLTRB(12, 56, 12, 24),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GenericBrowser(browserOptions: BrowserOptions(clubPartitions: state.clubPartitions)),
        ),
      ),
    );
  }

  /// El mismo panel del costado de escritorio (calendario del mes, resumen
  /// del día y solicitudes por aprobar), en una hoja desde abajo.
  void _openSummary(BuildContext context) {
    final bloc = context.read<SessionManagerBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (context, controller) => PrimaryScrollController(
            controller: controller,
            child: const DaySummaryPanel(),
          ),
        ),
      ),
    );
  }
}

/// Celular: botón flotante de la agenda para cargar turnos (lo que en
/// escritorio es "Gestión masiva ▾"). Un turno suelto se crea tocando un
/// horario libre de la agenda.
class MobileAgendaAddButton extends StatelessWidget {
  const MobileAgendaAddButton({super.key});

  @override
  Widget build(BuildContext context) {
    final canAdd = Permissions.can(Permissions.AGENDA_CREAR);
    final canEdit = Permissions.can(Permissions.AGENDA_GESTION_MASIVA);
    final canFixed = Permissions.can(Permissions.TURNOS_FIJOS_VER);
    if (!canAdd && !canEdit && !canFixed) return const SizedBox.shrink();

    return TourAnchor(id: 'agenda.bulk', child: FloatingActionButton.extended(
      heroTag: 'mobile-agenda-add',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        builder: (sheetContext) {
          void go(BulkSessionsTab tab) {
            Navigator.of(sheetContext).pop();
            context.go('${AppRoutes.BULK_SESSIONS_ROUTE.path}?tab=${tab.query}');
          }

          final space = adminVocabulary().space;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canAdd)
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Agregar turnos'),
                    subtitle: Text('Plantilla repetida en vari${space.g('a', 'o')}s ${space.lowerPlural} y días'),
                    onTap: () => go(BulkSessionsTab.add),
                  ),
                if (canEdit)
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Editar o eliminar turnos'),
                    subtitle: const Text('Precio, duración u horario por reglas'),
                    onTap: () => go(BulkSessionsTab.edit),
                  ),
                if (canFixed)
                  ListTile(
                    leading: const Icon(Icons.event_repeat),
                    title: const Text('Turnos fijos'),
                    subtitle: const Text('Clientes con el mismo horario todas las semanas'),
                    onTap: () => go(BulkSessionsTab.fixed),
                  ),
                if (canAdd)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      'Para un turno suelto, tocá un horario libre en la agenda.',
                      style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(color: Theme.of(sheetContext).colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      icon: const Icon(Icons.add),
      label: const Text('Agregar'),
    ));
  }
}
