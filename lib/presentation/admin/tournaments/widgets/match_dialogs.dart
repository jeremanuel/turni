import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/tournament/tournament.dart';
import '../../club_config/widgets/duration_minutes_field.dart';
import '../../club_config/widgets/time_field.dart';
import 'tournament_ui.dart';

/// Lo que eligió el admin al programar un partido. `courtId` null = desprogramar.
typedef ScheduleChoice = ({int? courtId, DateTime? start, int durationMinutes});

/// Cancha, día, hora y duración de un partido.
Future<ScheduleChoice?> showScheduleMatchDialog(BuildContext context, Tournament t, TournamentMatch m) {
  return showDialog<ScheduleChoice>(context: context, builder: (_) => _ScheduleMatchDialog(t: t, m: m));
}

class _ScheduleMatchDialog extends StatefulWidget {
  const _ScheduleMatchDialog({required this.t, required this.m});

  final Tournament t;
  final TournamentMatch m;

  @override
  State<_ScheduleMatchDialog> createState() => _ScheduleMatchDialogState();
}

class _ScheduleMatchDialogState extends State<_ScheduleMatchDialog> {
  final _formKey = GlobalKey<FormState>();
  late int? _courtId = widget.m.session?.courtId ?? widget.t.courts.firstOrNull?.id;
  late DateTime _day = widget.m.session?.start ?? widget.t.startsAt ?? DateTime.now();
  late final _time = TextEditingController(text: widget.m.session == null ? '19:00' : hhmm(widget.m.session!.start));
  late final _duration = TextEditingController(
    text: '${widget.m.session == null ? widget.t.matchDurationMinutes : widget.m.session!.end.difference(widget.m.session!.start).inMinutes}',
  );

  @override
  void dispose() {
    _time.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _day = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final parts = _time.text.split(':');
    final start = DateTime(_day.year, _day.month, _day.day, int.parse(parts[0]), int.parse(parts[1]));
    Navigator.of(context).pop((courtId: _courtId, start: start, durationMinutes: int.parse(_duration.text)));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    return AlertDialog(
      title: Text('Programar · ${m.roundLabel}'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${m.teamA?.name ?? 'A definir'} vs. ${m.teamB?.name ?? 'A definir'}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _courtId,
                decoration: const InputDecoration(labelText: 'Cancha'),
                items: [for (final c in widget.t.courts) DropdownMenuItem(value: c.id, child: Text(c.name))],
                validator: (v) => v == null ? 'Elegí la cancha' : null,
                onChanged: (v) => setState(() => _courtId = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDay,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Día', suffixIcon: Icon(Icons.event_outlined)),
                        child: Text(shortDate(_day)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: TimeField(
                      controller: _time,
                      decoration: const InputDecoration(labelText: 'Hora'),
                      validator: (v) => RegExp(r'^\d{2}:\d{2}$').hasMatch(v ?? '') ? null : 'HH:mm',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DurationMinutesField(
                controller: _duration,
                decoration: const InputDecoration(labelText: 'Duración (min)'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 15 || n > 300 ? 'Entre 15 y 300 minutos' : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (m.session != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop((courtId: null, start: null, durationMinutes: 0)),
            child: const Text('Desprogramar'),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}

/// Resultado que carga o resuelve el club. Devuelve los sets (SETS) o el marcador (POINTS).
typedef ResultChoice = ({List<ScoreLine>? sets, ScoreLine? score});

Future<ResultChoice?> showMatchResultDialog(BuildContext context, Tournament t, TournamentMatch m) {
  return showDialog<ResultChoice>(context: context, builder: (_) => _MatchResultDialog(t: t, m: m));
}

class _MatchResultDialog extends StatefulWidget {
  const _MatchResultDialog({required this.t, required this.m});

  final Tournament t;
  final TournamentMatch m;

  @override
  State<_MatchResultDialog> createState() => _MatchResultDialogState();
}

class _MatchResultDialogState extends State<_MatchResultDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<(TextEditingController, TextEditingController)> _lines = _initialLines();

  bool get _sets => widget.t.scoreMode == ScoreMode.sets;

  List<(TextEditingController, TextEditingController)> _initialLines() {
    final source = widget.m.score ?? widget.m.reports.firstOrNull?.score;
    final count = _sets ? (source?.length ?? 2).clamp(1, 5) : 1;
    return [
      for (var i = 0; i < count; i++)
        (
          TextEditingController(text: source != null && i < source.length ? '${source[i].a}' : ''),
          TextEditingController(text: source != null && i < source.length ? '${source[i].b}' : ''),
        ),
    ];
  }

  @override
  void dispose() {
    for (final (a, b) in _lines) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  void _useReport(MatchReport r) {
    setState(() {
      while (_lines.length < r.score.length) {
        _lines.add((TextEditingController(), TextEditingController()));
      }
      while (_lines.length > r.score.length) {
        final (a, b) = _lines.removeLast();
        a.dispose();
        b.dispose();
      }
      for (var i = 0; i < r.score.length; i++) {
        _lines[i].$1.text = '${r.score[i].a}';
        _lines[i].$2.text = '${r.score[i].b}';
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final lines = [for (final (a, b) in _lines) ScoreLine(int.parse(a.text), int.parse(b.text))];
    Navigator.of(context).pop(_sets ? (sets: lines, score: null) : (sets: null, score: lines.first));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final m = widget.m;
    final teamA = m.teamA?.name ?? 'Equipo A';
    final teamB = m.teamB?.name ?? 'Equipo B';
    String? number(String? v) => RegExp(r'^\d{1,3}$').hasMatch(v ?? '') ? null : '';

    return AlertDialog(
      title: Text(m.status == MatchStatus.disputed ? 'Resolver resultado' : 'Cargar resultado'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${m.roundLabel} · $teamA vs. $teamB', style: Theme.of(context).textTheme.titleSmall),
                if (m.reports.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final r in m.reports)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(scoreText(r.score)),
                        subtitle: Text('Cargó ${r.clientName} (${r.teamName}) · ${shortDateTime(r.createdAt)}'),
                        trailing: TextButton(onPressed: () => _useReport(r), child: const Text('Usar este')),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(width: 72),
                    Expanded(child: Text(teamA, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
                    Expanded(child: Text(teamB, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
                  ],
                ),
                const SizedBox(height: 8),
                for (final (i, (a, b)) in _lines.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 72, child: Text(_sets ? 'Set ${i + 1}' : 'Marcador', style: TextStyle(color: scheme.onSurfaceVariant))),
                        Expanded(child: _scoreField(a, number)),
                        const SizedBox(width: 12),
                        Expanded(child: _scoreField(b, number)),
                      ],
                    ),
                  ),
                if (_sets)
                  Row(
                    children: [
                      if (_lines.length < 5)
                        TextButton.icon(
                          onPressed: () => setState(() => _lines.add((TextEditingController(), TextEditingController()))),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar set'),
                        ),
                      if (_lines.length > 1)
                        TextButton(
                          onPressed: () => setState(() {
                            final (a, b) = _lines.removeLast();
                            a.dispose();
                            b.dispose();
                          }),
                          child: const Text('Quitar el último'),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  m.isKnockout ? 'En la llave no puede haber empate: el ganador pasa a la ronda siguiente.' : 'Al confirmar se actualiza la tabla.',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Confirmar resultado')),
      ],
    );
  }

  Widget _scoreField(TextEditingController controller, FormFieldValidator<String> validator) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
      decoration: const InputDecoration(isDense: true, errorStyle: TextStyle(height: 0)),
      validator: validator,
    );
  }
}

/// Confirmación de una acción con consecuencias.
Future<bool> confirmAction(BuildContext context, {required String title, required String message, required String confirm, bool destructive = false}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(width: 420, child: Text(message)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError) : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}
