import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/physical_partition_naming.dart';
import '../../../core/utils/types/time_interval.dart';
import '../../../domain/entities/partition_vocabulary.dart';
import '../../core/agenda/agenda.dart';
import 'bloc/session_manager_bloc.dart';
import 'bloc/session_manager_state.dart';
import 'widgets/session_manager_card.dart';
import 'widgets/session_manager_top_bar.dart';
import '../../../core/presentation/components/onboarding/tour_anchor.dart';

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TourAnchor(id: 'agenda.legend', child: _AgendaLegend()),
                      SizedBox(height: 12),
                      Expanded(child: TourAnchor(id: 'agenda.grid', child: _DesktopAgenda())),
                    ],
                  ),
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

/// Qué significa cada tipo de tarjeta de la agenda.
class _AgendaLegend extends StatelessWidget {
  const _AgendaLegend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(String label, BoxDecoration swatch) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 14, decoration: swatch),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
        );
    final radius = BorderRadius.circular(4);
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        item('Reservado', BoxDecoration(color: scheme.primaryContainer, borderRadius: radius)),
        item('Turno fijo', BoxDecoration(color: scheme.primaryContainer, borderRadius: radius, border: Border.all(color: scheme.tertiary, width: 2))),
        item('Libre', BoxDecoration(borderRadius: radius, border: Border.all(color: scheme.outline))),
        item('Fijo cancelado este día', BoxDecoration(color: scheme.tertiaryContainer.withValues(alpha: 0.25), borderRadius: radius, border: Border.all(color: scheme.tertiary))),
        item('Por aprobar', BoxDecoration(color: scheme.tertiaryContainer, borderRadius: radius)),
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
            focusSession: state.selectedSession,
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
              final vocabulary = PartitionVocabulary.of(p.clubPartition ?? state.selectedClubPartition);
              return [
                vocabulary.coverLabel(p.isCover == '1' || p.isCover == 'true'),
                vocabulary.capacityLabel(p.maxPlayers ?? p.minPlayers),
              ].nonNulls.join(' · ');
            },
            sessions: state.sessions,
            // Los espacios inactivos no se muestran como columna, salvo que ese
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
