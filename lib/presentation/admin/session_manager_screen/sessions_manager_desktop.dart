import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/physical_partition_naming.dart';
import '../../../core/utils/types/time_interval.dart';
import '../../core/agenda/agenda.dart';
import 'bloc/session_manager_bloc.dart';
import 'bloc/session_manager_state.dart';
import 'widgets/session_manager_card.dart';
import 'widgets/session_manager_top_bar.dart';

/// Gestor de turnos en escritorio: barra superior a todo el ancho, agenda a
/// la izquierda y el panel lateral derecho (resumen del día o el turno
/// seleccionado, según la ruta) de 380px.
class SessionManagerDesktop extends StatelessWidget {
  final Widget sideChild;
  final int? sessionId;

  const SessionManagerDesktop({
    super.key,
    required this.sideChild,
    this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SessionManagerTopBar(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: _DesktopAgenda(),
                ),
              ),
              Container(
                width: 380,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: scheme.outlineVariant)),
                ),
                child: sideChild,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopAgenda extends StatelessWidget {
  const _DesktopAgenda();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: BlocBuilder<SessionManagerBloc, SessionManagerState>(
        buildWhen: (previous, current) =>
            previous.sessions != current.sessions ||
            previous.selectedClubPartition != current.selectedClubPartition ||
            previous.isLoadingSessions != current.isLoadingSessions ||
            previous.selectedSession != current.selectedSession,
        builder: (context, state) {
          if (state.isLoadingSessions) {
            return const Center(child: CircularProgressIndicator());
          }

          return Agenda(
            columnWidth: 200,
            heightPerMinute: 1.35,
            showNowIndicator: true,
            fromDate: state.currentDate.applied(const TimeOfDay(hour: 8, minute: 0)),
            lastDate: state.currentDate.applied(const TimeOfDay(hour: 22, minute: 0)),
            buildCard: (session, physicalPartition, height) => SessionManagerCard(
              height: height,
              hasFocus: state.selectedSession == session,
              session: session,
              physicalPartition: physicalPartition,
            ),
            partitionLabelBuilder: (physicalPartition) => PhysicalPartitionNaming.labelFromPhysicalPartition(
              physicalPartition,
              fallbackClubPartition: state.selectedClubPartition,
            ),
            partitionSubtitleBuilder: (p) {
              final cover = p.isCover == '1' || p.isCover == 'true' ? 'Cubierta' : 'Descubierta';
              final players = p.maxPlayers ?? p.minPlayers;
              return players > 0 ? '$cover · $players jug.' : cover;
            },
            sessions: state.sessions,
            // Las canchas inactivas no se muestran como columna, salvo que ese
            // día tengan turnos (dar de baja no borra los turnos ya creados).
            physicalPartitions: (state.selectedClubPartition?.physicalPartitions ?? [])
                .where((p) => p.active || state.sessions.any((s) => s.partitionPhysicalId == p.partitionPhysicalId))
                .toList(),
          );
        },
      ),
    );
  }
}
