import 'package:flutter/material.dart';

import '../../../../domain/entities/gym/gym.dart';
import '../../../../domain/entities/gym/gym_progress.dart';
import '../../club_config/widgets/admin_data_table.dart';

/// Badge de una diferencia ("+5 kg · +1 rep"): relleno si nada bajó, con borde si algo bajó.
class DeltaChip extends StatelessWidget {
  const DeltaChip({super.key, required this.delta, this.emptyLabel = 'Sin cambios'});

  final SeriesDelta? delta;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final delta = this.delta;
    final up = delta?.up ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: delta != null && up ? colorScheme.secondaryContainer : null,
        borderRadius: BorderRadius.circular(8),
        border: delta != null && up ? null : Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        delta?.label ?? emptyLabel,
        style: textTheme.labelMedium?.copyWith(
          color: delta == null ? colorScheme.outline : (up ? colorScheme.onSecondaryContainer : colorScheme.primary),
        ),
      ),
    );
  }
}

/// Gráfico en escalones de un ejercicio: cada valor vale hasta el cambio
/// siguiente; punto lleno = lo cambió el cliente, hueco = el plan.
class ProgressStepChart extends StatelessWidget {
  const ProgressStepChart({super.key, required this.points, required this.metric, this.height = 140});

  final List<ProgressPoint> points;
  final ProgressMetric metric;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final values = [for (final point in points) metricValue(point.series, metric, restSeconds: point.restSeconds)];
    String label(double v) => switch (metric) {
          ProgressMetric.weight => '${formatKg(v)} kg',
          ProgressMetric.rest => formatRest(v.round()),
          _ => v.toStringAsFixed(0),
        };
    return Semantics(
      label: 'Evolución de ${metric.label.toLowerCase()}: ${values.map(label).join(', ')}',
      child: ExcludeSemantics(
        child: Container(
          height: height,
          decoration: BoxDecoration(color: colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: CustomPaint(
            size: Size.infinite,
            painter: _StepPainter(
              values: values,
              byClient: [for (final point in points) point.byClient],
              labels: values.map(label).toList(),
              line: colorScheme.primary,
              fill: colorScheme.surfaceContainer,
              grid: colorScheme.outlineVariant,
              labelStyle: textTheme.labelMedium!.copyWith(color: colorScheme.onSurface),
              markerStyle: textTheme.labelSmall!.copyWith(color: colorScheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepPainter extends CustomPainter {
  _StepPainter({
    required this.values,
    required this.byClient,
    required this.labels,
    required this.line,
    required this.fill,
    required this.grid,
    required this.labelStyle,
    required this.markerStyle,
  });

  final List<double> values;
  final List<bool> byClient;
  final List<String> labels;
  final Color line, fill, grid;
  final TextStyle labelStyle, markerStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const top = 24.0;
    final bottom = size.height - 18;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    double y(double v) => max == min ? (top + bottom) / 2 : bottom - (v - min) / (max - min) * (bottom - top);
    final step = values.length == 1 ? 0.0 : (size.width - 24) / (values.length - 1);
    final pts = [for (var i = 0; i < values.length; i++) Offset(values.length == 1 ? size.width / 2 : 12 + i * step, y(values[i]))];

    canvas.drawLine(Offset(0, bottom), Offset(size.width, bottom), Paint()..color = grid);
    final dash = Paint()
      ..color = line.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 1; i < pts.length; i++) {
      if (byClient[i]) continue;
      for (var dy = 8.0; dy < bottom; dy += 7) {
        canvas.drawLine(Offset(pts[i].dx, dy), Offset(pts[i].dx, (dy + 3).clamp(0, bottom)), dash);
      }
      final text = TextPainter(text: TextSpan(text: 'Cambio de plan', style: markerStyle), textDirection: TextDirection.ltr)..layout();
      text.paint(canvas, Offset((pts[i].dx - text.width / 2).clamp(0.0, size.width - text.width), bottom + 3));
    }

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path
        ..lineTo(pts[i].dx, pts[i - 1].dy)
        ..lineTo(pts[i].dx, pts[i].dy);
    }
    if (pts.length == 1) path.lineTo(size.width - 12, pts.first.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < pts.length; i++) {
      canvas.drawCircle(pts[i], 4.5, Paint()..color = byClient[i] ? line : fill);
      canvas.drawCircle(
        pts[i],
        4.5,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final text = TextPainter(text: TextSpan(text: labels[i], style: labelStyle), textDirection: TextDirection.ltr)..layout();
      text.paint(canvas, Offset((pts[i].dx - text.width / 2).clamp(0.0, size.width - text.width), pts[i].dy - 8 - text.height));
    }
  }

  @override
  bool shouldRepaint(_StepPainter old) => old.values != values || old.byClient != byClient || old.line != line;
}

/// Historial de un ejercicio: gráfico y cada cambio con fecha y quién.
Future<void> showExerciseHistoryDialog(
  BuildContext context, {
  required ExerciseProgress exercise,
  required String clientFirstName,
  required String subtitle,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _HistoryDialog(exercise: exercise, clientFirstName: clientFirstName, subtitle: subtitle),
  );
}

class _HistoryDialog extends StatefulWidget {
  const _HistoryDialog({required this.exercise, required this.clientFirstName, required this.subtitle});

  final ExerciseProgress exercise;
  final String clientFirstName;
  final String subtitle;

  @override
  State<_HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<_HistoryDialog> {
  late ProgressMetric _metric = _initial();

  ProgressMetric _initial() {
    final delta = widget.exercise.totalDelta;
    if (delta == null || delta.kg) return ProgressMetric.weight;
    if (delta.reps) return ProgressMetric.reps;
    if (delta.sets) return ProgressMetric.sets;
    return delta.rest ? ProgressMetric.rest : ProgressMetric.weight;
  }

  /// El gráfico de descanso solo con los puntos que lo tienen.
  List<ProgressPoint> get _chartPoints => _metric == ProgressMetric.rest
      ? widget.exercise.points.where((point) => point.restSeconds != null).toList()
      : widget.exercise.points;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final exercise = widget.exercise;
    final points = exercise.points;
    final withRest = exercise.hasRests;
    final metrics = [for (final metric in ProgressMetric.values) if (metric != ProgressMetric.rest || withRest) metric];

    Widget value(String text, bool changed) => Text(
          text,
          style: TextStyle(
            fontWeight: changed ? FontWeight.w700 : null,
            color: changed ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );

    final rows = <List<Widget>>[
      for (var i = points.length - 1; i >= 0; i--)
        () {
          final point = points[i];
          final delta = exercise.deltaAt(i);
          return [
            Text(weekdayDate(point.date)),
            value('${point.series.length}', delta?.sets ?? false),
            value(
              point.series.map((s) => s.reps).toSet().length <= 1
                  ? '${point.series.isEmpty ? 0 : point.series.first.reps}'
                  : point.series.map((s) => s.reps).join('/'),
              delta?.reps ?? false,
            ),
            value(metricValue(point.series, ProgressMetric.weight) == 0 ? 'Sin peso' : '${formatKg(metricValue(point.series, ProgressMetric.weight))} kg', delta?.kg ?? false),
            if (withRest) value(point.restSeconds == null ? '—' : formatRest(point.restSeconds!), delta?.rest ?? false),
            Text(point.who(widget.clientFirstName, first: i == 0)),
            DeltaChip(delta: delta, emptyLabel: 'Inicio'),
          ];
        }(),
    ];

    return AlertDialog(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name),
                const SizedBox(height: 4),
                Text(widget.subtitle, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final metric in metrics)
                ChoiceChip(
                  label: Text(metric.label),
                  selected: metric == _metric,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _metric = metric),
                ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProgressStepChart(points: _chartPoints, metric: _metric),
              const SizedBox(height: 8),
              Text(
                'Punto lleno: lo cambió ${widget.clientFirstName} entrenando. Punto hueco: una versión del plan.',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              AdminDataTable(
                columns: ['Fecha', 'Series', 'Reps', 'Peso', if (withRest) 'Descanso', 'Quién', 'Cambio'],
                columnWidths: {withRest ? 5 : 4: const FlexColumnWidth()},
                rows: rows,
              ),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
    );
  }
}

/// "Progreso en la rutina" de la ficha: de dónde arrancó y dónde está cada
/// ejercicio, por grupo. Cada fila abre el historial.
class RoutineProgressTable extends StatefulWidget {
  const RoutineProgressTable({super.key, required this.progress, required this.clientFirstName});

  final RoutineProgress progress;
  final String clientFirstName;

  @override
  State<RoutineProgressTable> createState() => _RoutineProgressTableState();
}

class _RoutineProgressTableState extends State<RoutineProgressTable> {
  int? _groupId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = widget.progress;
    // Solo los ejercicios que cambiaron: los que siguen igual que el plan no suman.
    final changed = progress.exercises.where((e) => e.changesCount > 0).toList();
    final groups = <int, String>{for (final exercise in changed) exercise.groupId: exercise.groupName};
    final groupId = groups.containsKey(_groupId) ? _groupId : groups.keys.firstOrNull;
    final exercises = changed.where((e) => e.groupId == groupId).toList();
    final lastChange = progress.lastChangeDate;

    void open(ExerciseProgress exercise) => showExerciseHistoryDialog(
          context,
          exercise: exercise,
          clientFirstName: widget.clientFirstName,
          subtitle: '${exercise.groupName} · rutina desde el ${shortDate(progress.startDate)}',
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progreso en la rutina', style: textTheme.titleSmall),
                Text(
                  'Rutina desde el ${shortDate(progress.startDate)} · ${lastChange == null ? 'todavía sin cambios' : 'último cambio ${weekdayDate(lastChange)}'}',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            if (groups.length > 1)
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in groups.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: entry.key == groupId,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _groupId = entry.key),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (changed.isEmpty)
          Text(
            'Ningún ejercicio cambió todavía. Cuando ${widget.clientFirstName} cambie series, reps, peso o descanso entrenando, o edites el plan, lo vas a ver acá.',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          )
        else
        AdminDataTable(
          columns: const ['Ejercicio', 'Inicio', 'Ahora', 'Cambio', 'Último cambio'],
          columnWidths: const {0: FlexColumnWidth(1.6), 1: FlexColumnWidth(), 2: FlexColumnWidth(), 3: FlexColumnWidth(1.1), 4: FlexColumnWidth()},
          rows: [
            for (final exercise in exercises)
              [
                _ExerciseLink(
                  name: exercise.name,
                  detail: exercise.changesCount == 1 ? '1 cambio' : '${exercise.changesCount} cambios',
                  onTap: () => open(exercise),
                ),
                Text(exercise.first == null ? '—' : seriesLabel(exercise.first!.series), style: TextStyle(color: colorScheme.onSurfaceVariant)),
                Text(exercise.last == null ? '—' : seriesLabel(exercise.last!.series), style: const TextStyle(fontWeight: FontWeight.w500)),
                Align(alignment: Alignment.centerLeft, child: DeltaChip(delta: exercise.totalDelta)),
                exercise.lastChange == null
                    ? Text('—', style: TextStyle(color: colorScheme.outline))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(weekdayDate(exercise.lastChange!.date)),
                          Text(
                            exercise.lastChange!.who(widget.clientFirstName, first: false),
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
              ],
          ],
        ),
      ],
    );
  }
}

/// Nombre de ejercicio que abre su historial, subrayado al pasar el mouse.
class _ExerciseLink extends StatefulWidget {
  const _ExerciseLink({required this.name, required this.detail, required this.onTap});

  final String name;
  final String detail;
  final VoidCallback onTap;

  @override
  State<_ExerciseLink> createState() => _ExerciseLinkState();
}

class _ExerciseLinkState extends State<_ExerciseLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          label: 'Historial de ${widget.name}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.name, style: TextStyle(decoration: _hover ? TextDecoration.underline : null)),
              Text(widget.detail, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
