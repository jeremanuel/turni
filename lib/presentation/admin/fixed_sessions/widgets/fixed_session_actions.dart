import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/fixed_session.dart';
import '../../../../domain/repositories/fixed_session_repository.dart';
import 'client_search_field.dart';
import 'fixed_session_form_dialog.dart';
import 'fixed_session_texts.dart';

final _repository = sl<FixedSessionRepository>();

/// Abre el panel lateral de alta y, si se cargó, avisa qué días no se
/// pudieron ocupar. Devuelve el turno fijo creado.
Future<FixedSession?> openNewFixedSession(BuildContext context, {Client? client, int? dayOfWeek}) async {
  final created = await showGeneralDialog<FixedSessionCreated>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, __) => Align(
      alignment: Alignment.centerRight,
      child: FixedSessionSheet(initialClient: client, initialDayOfWeek: dayOfWeek),
    ),
    transitionBuilder: (context, animation, _, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
  if (created == null || !context.mounted) return null;

  final total = created.created + created.assigned;
  if (created.conflicts.isEmpty) {
    SnackbarsFunctions.showSuccessSnackbar(context, 'Turno fijo cargado: $total turnos en la agenda.');
  } else {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Turno fijo cargado'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Se cargaron $total turnos. Estos días ya estaban ocupados y no se tocaron:'),
              const SizedBox(height: 12),
              for (final c in created.conflicts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• ${FixedSessionTexts.shortDate(c.date)}: ${FixedSessionTexts.conflictLabel(c)}'),
                ),
            ],
          ),
        ),
        actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido'))],
      ),
    );
  }
  return created.fixedSession;
}

/// "¿Qué querés cancelar?": solo un día (queda libre, el fijo sigue) o todo
/// el turno fijo. Con [date] el día viene elegido (ej. desde la agenda).
/// Devuelve true si se canceló algo.
Future<bool> cancelFixedSession(BuildContext context, FixedSessionRef fixedSession, {DateTime? date, String? place}) async {
  final done = await showDialog<bool>(
    context: context,
    builder: (_) => _CancelFixedDialog(fixedSession: fixedSession, date: date, place: place),
  );
  return done == true;
}

enum _CancelScope { day, all }

class _CancelFixedDialog extends StatefulWidget {
  const _CancelFixedDialog({required this.fixedSession, this.date, this.place});

  final FixedSessionRef fixedSession;
  final DateTime? date;
  final String? place;

  @override
  State<_CancelFixedDialog> createState() => _CancelFixedDialogState();
}

class _CancelFixedDialogState extends State<_CancelFixedDialog> {
  late DateTime? _date = widget.date;
  _CancelScope _scope = _CancelScope.day;
  bool _saving = false;
  String? _error;

  int get _weekday => widget.fixedSession.dayOfWeek == 0 ? 7 : widget.fixedSession.dayOfWeek;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = today.add(Duration(days: (_weekday - today.weekday + 7) % 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? first,
      firstDate: first,
      lastDate: today.add(const Duration(days: 365)),
      selectableDayPredicate: (d) => d.weekday == _weekday,
      helpText: 'Qué ${widget.fixedSession.dayName.toLowerCase()} cancelar',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _confirm() async {
    if (_scope == _CancelScope.day && _date == null) {
      setState(() => _error = 'Elegí qué día cancelar.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = _scope == _CancelScope.day
        ? await _repository.cancelDay(widget.fixedSession.id, DateFormat('yyyy-MM-dd').format(_date!))
        : await _repository.end(widget.fixedSession.id);
    if (!mounted) return;
    switch (result) {
      case Right():
        SnackbarsFunctions.showSuccessSnackbar(
          context,
          _scope == _CancelScope.day ? 'Día cancelado: el horario quedó libre.' : 'Turno fijo dado de baja.',
        );
        Navigator.of(context).pop(true);
      case Left(:final failure):
        setState(() {
          _saving = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final fixed = widget.fixedSession;
    final dayLabel = _date == null ? null : DateFormat("EEEE d/MM", 'es').format(_date!);
    final canEnd = Permissions.can(Permissions.TURNOS_FIJOS_CANCELAR);

    return AlertDialog(
      title: const Text('¿Qué querés cancelar?'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ['Turno fijo de ${fixed.clientName}', 'todos los ${fixed.dayName.toLowerCase()} ${fixed.startTime}', if (widget.place != null) widget.place!].join(' · '),
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _ScopeOption(
              selected: _scope == _CancelScope.day,
              onTap: () => setState(() => _scope = _CancelScope.day),
              title: dayLabel == null ? 'Solo un día' : 'Solo el $dayLabel',
              description: 'El horario queda libre para que lo reserve otro. El turno fijo sigue la semana siguiente.',
              trailing: widget.date == null
                  ? TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(_date == null ? 'Elegir día' : 'Cambiar'),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            if (canEnd)
              _ScopeOption(
                selected: _scope == _CancelScope.all,
                onTap: () => setState(() => _scope = _CancelScope.all),
                title: 'Todo el turno fijo',
                description: 'Se da de baja desde hoy. Los turnos ya cargados quedan libres; los que tienen pagos se mantienen.',
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Volver')),
        FilledButton(
          style: _scope == _CancelScope.all ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError) : null,
          onPressed: _saving ? null : _confirm,
          child: Text(_scope == _CancelScope.all
              ? 'Dar de baja'
              : (_date == null ? 'Cancelar el día' : 'Cancelar el ${DateFormat('dd/MM').format(_date!)}')),
        ),
      ],
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({required this.selected, required this.onTap, required this.title, required this.description, this.trailing});

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? scheme.primary : scheme.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: fg)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(fontSize: 13, height: 1.35, color: selected ? fg : scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Cambia los integrantes. Devuelve el turno fijo actualizado.
Future<FixedSession?> editFixedSessionParticipants(BuildContext context, FixedSession fixedSession) {
  return showDialog<FixedSession>(context: context, builder: (_) => _ParticipantsDialog(fixedSession: fixedSession));
}

class _ParticipantsDialog extends StatefulWidget {
  const _ParticipantsDialog({required this.fixedSession});

  final FixedSession fixedSession;

  @override
  State<_ParticipantsDialog> createState() => _ParticipantsDialogState();
}

class _ParticipantsDialogState extends State<_ParticipantsDialog> {
  late final List<FixedSessionPerson> _participants = [...widget.fixedSession.participants];
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await _repository.updateParticipants(
      widget.fixedSession.id,
      _participants.map((p) => p.clientId).toList(),
    );
    if (!mounted) return;
    switch (result) {
      case Right(:final value):
        Navigator.of(context).pop(value);
      case Left(:final failure):
        setState(() {
          _saving = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final excluded = {widget.fixedSession.client.clientId, ..._participants.map((p) => p.clientId)};
    return AlertDialog(
      title: const Text('Integrantes'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Titular: ${widget.fixedSession.client.fullName}. Los cambios se aplican también a los turnos ya cargados.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_participants.isEmpty) const Text('Sin integrantes.'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _participants)
                  InputChip(label: Text(p.fullName), onDeleted: () => setState(() => _participants.remove(p))),
              ],
            ),
            const SizedBox(height: 12),
            ClientSearchField(
              label: 'Sumar integrante',
              excludeIds: excluded,
              clearOnSelect: true,
              onSelected: (client) => setState(() => _participants.add(FixedSessionPerson(
                    clientId: client.intClientId,
                    name: client.person?.name ?? '',
                    lastName: client.person?.lastName ?? '',
                  ))),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Guardar')),
      ],
    );
  }
}
