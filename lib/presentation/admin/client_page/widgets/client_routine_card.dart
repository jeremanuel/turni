import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/app_routes.dart';
import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/gym/gym.dart';
import '../../../../domain/entities/gym/gym_progress.dart';
import '../../../../domain/repositories/gym_repository.dart';
import '../../routines/widgets/progress_history.dart';

/// Card de rutina de la ficha: la rutina actual (grupos y cuándo hizo cada
/// uno), lo que dijo el cliente (notas para el profe, lo que no le gusta,
/// pesos que cambió) y la entrada al editor. Solo se muestra si el club
/// tiene gimnasio o el cliente tiene rutinas.
class ClientRoutineCard extends StatefulWidget {
  const ClientRoutineCard({super.key, required this.client});

  final Client client;

  @override
  State<ClientRoutineCard> createState() => _ClientRoutineCardState();
}

class _ClientRoutineCardState extends State<ClientRoutineCard> {
  final _repository = sl<GymRepository>();
  ClientGymSummary? _summary;
  RoutineProgress? _progress;
  String? _error;

  int get _clientId => widget.client.intClientId;
  String get _firstName => (widget.client.person?.name ?? 'El cliente').split(' ').first;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repository.summary(_clientId);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Right(:final value):
          _summary = value;
          _error = null;
        case Left(:final failure):
          _error = failure.message;
      }
    });
    // Las notas quedan vistas al abrir la ficha: el "nuevas" se muestra una vez.
    if ((_summary?.unseenCount ?? 0) > 0) _repository.markFeedbackSeen(_clientId);

    final routineId = _summary?.active?.routineId;
    if (routineId == null) return;
    final progress = await _repository.progress(routineId);
    if (!mounted) return;
    setState(() => _progress = progress.when(left: (_) => null, right: (value) => value));
  }

  Future<void> _openEditor({String? routineId}) async {
    final saved = await context.pushNamed<bool>(
      AppRoutes.NEW_ROUTINE_ROUTE.name,
      pathParameters: {'clientId': '$_clientId'},
      extra: {'client': widget.client, 'routineId': routineId},
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    if (_error != null) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(title: const Text('Rutina'), subtitle: Text(_error!), trailing: TextButton(onPressed: _load, child: const Text('Reintentar'))),
      );
    }
    if (summary == null || !summary.hasGym) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = summary.active;
    final canEdit = Permissions.can(Permissions.CLIENTES_EDITAR);
    // Los cambios de peso se ven en el progreso de la rutina.
    final feedbackCount = summary.notes.length + summary.dislikes.length;
    final progress = _progress;

    String meta() {
      if (active == null) return 'Todavía no tiene una rutina activa.';
      final parts = ['Desde el ${shortDate(active.startDate)}', 'Entrenó ${active.timesTrained == 1 ? '1 vez' : '${active.timesTrained} veces'}'];
      if (active.lastCheckDate != null) {
        parts.add('La última, ${agoLabel(active.lastCheckDate!).toLowerCase()}${active.lastCheckGroup == null ? '' : ' (${active.lastCheckGroup})'}');
      }
      return parts.join(' · ');
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(active == null ? 'Rutina' : 'Rutina actual', style: textTheme.titleMedium),
                      Text(meta(), style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (canEdit)
                  Wrap(spacing: 8, children: [
                    if (active != null) OutlinedButton(onPressed: () => _openEditor(routineId: active.routineId), child: const Text('Editar')),
                    FilledButton.icon(onPressed: _openEditor, icon: const Icon(Icons.add), label: const Text('Nueva rutina')),
                  ]),
              ],
            ),
            if (active != null && active.groups.isNotEmpty) ...[
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth >= 600 ? 3 : (constraints.maxWidth >= 380 ? 2 : 1);
                final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final group in active.groups)
                      Container(
                        width: width,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(group.name, style: textTheme.titleSmall),
                            Text(
                              '${group.exercisesCount} ejercicios · ${group.lastDoneAt == null ? 'sin hacer' : agoLabel(group.lastDoneAt!).toLowerCase()}',
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }),
            ],
            if (progress != null && progress.exercises.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              RoutineProgressTable(progress: progress, clientFirstName: _firstName),
            ],
            if (feedbackCount > 0) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Lo que dijo $_firstName', style: textTheme.titleSmall)),
                  if (summary.unseenCount > 0)
                    Chip(
                      label: Text(summary.unseenCount == 1 ? '1 nueva' : '${summary.unseenCount} nuevas'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: colorScheme.primaryContainer,
                      labelStyle: textTheme.labelSmall?.copyWith(color: colorScheme.onPrimaryContainer),
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              for (final note in summary.notes)
                _FeedbackLine(icon: Icons.chat_bubble_outline, title: note.exercise, text: '"${note.text}" · ${agoLabel(note.updatedAt).toLowerCase()}'),
              for (final exercise in summary.dislikes) _FeedbackLine(icon: Icons.thumb_down_outlined, title: exercise, text: 'no le gusta'),
            ],
            if (summary.previousCount > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _showPrevious(context),
                  child: Text('Ver rutinas anteriores (${summary.previousCount})'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showPrevious(BuildContext context) async {
    final result = await _repository.routines(_clientId);
    if (!context.mounted) return;
    final routines = result.when(left: (_) => const <Routine>[], right: (value) => value).where((r) => !r.isActive).toList();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rutinas anteriores'),
        content: SizedBox(
          width: 560,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final routine in routines)
                ExpansionTile(
                  title: Text(routineMonthsLabel(routine)),
                  subtitle: Text('${routine.groups.map((g) => g.name).join(' · ')} · ${routine.exercisesCount} ejercicios'),
                  children: [
                    for (final group in routine.groups)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(group.name, style: Theme.of(context).textTheme.titleSmall),
                            for (final exercise in group.exercises)
                              Row(children: [
                                Expanded(child: Text(exercise.name)),
                                Text(seriesLabel(exercise.series), style: Theme.of(context).textTheme.bodySmall),
                              ]),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
      ),
    );
  }
}

class _FeedbackLine extends StatelessWidget {
  const _FeedbackLine({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$title: ', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              TextSpan(text: text, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            ])),
          ),
        ],
      ),
    );
  }
}
