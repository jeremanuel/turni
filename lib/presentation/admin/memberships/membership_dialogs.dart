import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/thousands_format.dart';
import '../../../domain/entities/membership/membership.dart';
import '../../../domain/entities/subscription/client_subscription.dart';
import '../../../domain/repositories/subscription_repository.dart';
import '../../core/cubit/auth/auth_cubit.dart';
import '../../../domain/entities/payment/payment_method.dart';
import '../../../domain/repositories/membership_repository.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../club_config/widgets/price_field.dart';
import 'widgets/membership_widgets.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Future<DateTime?> _pickDay(BuildContext context, DateTime initial, {DateTime? first, DateTime? last}) => showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first ?? DateTime(initial.year - 1),
      lastDate: last ?? DateTime(initial.year + 1, 12, 31),
    );

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap, this.helper});

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? helper;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          child: Text(value),
        ),
      );
}

class _Info extends StatelessWidget {
  const _Info({required this.text, this.icon = Icons.info_outline});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = (scheme.primaryContainer, scheme.onPrimaryContainer);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: fg),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg))),
      ]),
    );
  }
}

// ─── Pausar ──────────────────────────────────────────────────────────────

/// Pausar un abono (vacaciones, lesión). Devuelve el abono actualizado.
Future<Membership?> showPauseDialog(BuildContext context, Membership membership) =>
    showDialog<Membership>(context: context, builder: (_) => _PauseDialog(membership: membership));

class _PauseDialog extends StatefulWidget {
  const _PauseDialog({required this.membership});

  final Membership membership;

  @override
  State<_PauseDialog> createState() => _PauseDialogState();
}

class _PauseDialogState extends State<_PauseDialog> {
  /// La cuota impaga más vieja: pausar desde ahí la saca de la deuda.
  late final DateTime? _unpaidDue = widget.membership.overdueSince;
  late bool _fromDue = _unpaidDue != null;
  late DateTime _start = _unpaidDue ?? _today();
  DateTime? _end;
  bool _untilBack = true;
  String? _reason = 'Vacaciones';
  bool _saving = false;
  String? _error;

  DateTime get _effectiveStart => _fromDue && _unpaidDue != null ? _unpaidDue : _start;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await sl<MembershipRepository>().pause(
      widget.membership.id,
      startDate: _effectiveStart,
      endDate: _untilBack ? null : _end,
      reason: _reason,
    );
    if (!mounted) return;
    result.when(
      left: (f) => setState(() {
        _saving = false;
        _error = f.message;
      }),
      right: (m) => Navigator.of(context).pop(m),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final m = widget.membership;
    final unpaid = _unpaidDue;

    return AlertDialog(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Pausar abono de ${m.clientName}'),
        const SizedBox(height: 4),
        Text(
          '${m.plan.name} · ${dueDescription(m)}${unpaid != null ? ' · la cuota del ${dayLabel(unpaid)} no está pagada' : ''}',
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ]),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Text('¿Desde cuándo?', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            RadioGroup<bool>(
              groupValue: _fromDue,
              onChanged: (value) => setState(() => _fromDue = value ?? _fromDue),
              child: Column(children: [
                if (unpaid != null)
                  RadioListTile<bool>(
                    value: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Desde el vencimiento impago: ${weekdayLabel(unpaid)}'),
                    subtitle: const Text('No vino desde que venció: esa cuota no se cobra y deja de figurar como deuda.'),
                  ),
                RadioListTile<bool>(
                  value: false,
                  contentPadding: EdgeInsets.zero,
                  title: Text(unpaid != null ? 'Desde otra fecha' : 'Desde'),
                  subtitle: Text(unpaid != null ? 'Lo que venció antes sigue como deuda.' : 'No genera cuotas desde ese día.'),
                ),
              ]),
            ),
            if (!_fromDue || unpaid == null)
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 8),
                child: _DateField(
                  label: 'Arranca la pausa',
                  value: weekdayLabel(_start),
                  onTap: () async {
                    final picked = await _pickDay(context, _start, first: m.startDate);
                    if (picked != null) setState(() => _start = picked);
                  },
                ),
              ),
            const SizedBox(height: 12),
            Text('¿Hasta cuándo?', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ChoiceChip(label: const Text('Hasta que vuelva'), selected: _untilBack, showCheckmark: false, onSelected: (_) => setState(() => _untilBack = true)),
              ChoiceChip(
                label: Text(_end == null ? 'Hasta una fecha' : 'Hasta el ${dayLabel(_end!)}'),
                selected: !_untilBack,
                showCheckmark: false,
                onSelected: (_) async {
                  final picked = await _pickDay(context, _end ?? _effectiveStart.add(const Duration(days: 15)), first: _effectiveStart.add(const Duration(days: 1)));
                  if (picked != null) {
                    setState(() {
                      _end = picked;
                      _untilBack = false;
                    });
                  }
                },
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              _untilBack
                  ? 'Queda en pausa hasta que alguien toque "Retomar" (o registre un pago, que la retoma sola).'
                  : 'Ese día vuelve a estar activo y vence su próxima cuota. Se puede retomar antes.',
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text('Motivo (opcional)', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final option in const ['Vacaciones', 'Lesión', 'Viaje', 'Otro'])
                ChoiceChip(
                  label: Text(option),
                  selected: _reason == option,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _reason = _reason == option ? null : option),
                ),
            ]),
            const SizedBox(height: 16),
            _Info(
              icon: Icons.pause,
              text: m.plan.billingMode == BillingMode.anniversary
                  ? 'Mientras esté en pausa no genera cuotas, no figura como vencido y no recibe avisos. Cuando vuelva, paga ese día y a partir de ahí vence ese mismo día de cada mes.'
                  : 'Mientras esté en pausa no genera cuotas, no figura como vencido y no recibe avisos. Cuando vuelva, paga la parte proporcional hasta el día ${m.plan.billingDay} y sigue como siempre.',
            ),
            if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: scheme.error))],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Pausar abono'),
        ),
      ],
    );
  }
}

// ─── Editar pausa ────────────────────────────────────────────────────────

/// Cambiar la fecha de vuelta o el motivo de la pausa actual.
Future<Membership?> showEditPauseDialog(BuildContext context, Membership membership) =>
    showDialog<Membership>(context: context, builder: (_) => _EditPauseDialog(membership: membership));

class _EditPauseDialog extends StatefulWidget {
  const _EditPauseDialog({required this.membership});

  final Membership membership;

  @override
  State<_EditPauseDialog> createState() => _EditPauseDialogState();
}

class _EditPauseDialogState extends State<_EditPauseDialog> {
  late final MembershipPause _pause = widget.membership.pause!;
  late DateTime? _end = _pause.end;
  late String? _reason = _pause.reason;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await sl<MembershipRepository>().updatePause(
      widget.membership.id,
      _pause.id,
      endDate: _end,
      clearEnd: _end == null,
      reason: _reason ?? '',
    );
    if (!mounted) return;
    result.when(
      left: (f) => setState(() {
        _saving = false;
        _error = f.message;
      }),
      right: (m) => Navigator.of(context).pop(m),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text('Pausa de ${widget.membership.clientName}'),
      content: SizedBox(
        width: 480,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text('En pausa desde el ${weekdayLabel(_pause.start)}.', style: textTheme.bodyMedium),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(label: const Text('Hasta que vuelva'), selected: _end == null, showCheckmark: false, onSelected: (_) => setState(() => _end = null)),
            ChoiceChip(
              label: Text(_end == null ? 'Hasta una fecha' : 'Hasta el ${dayLabel(_end!)}'),
              selected: _end != null,
              showCheckmark: false,
              onSelected: (_) async {
                final picked = await _pickDay(context, _end ?? _today().add(const Duration(days: 7)), first: _pause.start.add(const Duration(days: 1)));
                if (picked != null) setState(() => _end = picked);
              },
            ),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in const ['Vacaciones', 'Lesión', 'Viaje', 'Otro'])
              ChoiceChip(label: Text(option), selected: _reason == option, showCheckmark: false, onSelected: (_) => setState(() => _reason = _reason == option ? null : option)),
          ]),
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Guardar')),
      ],
    );
  }
}

// ─── Retomar ─────────────────────────────────────────────────────────────

/// Retomar un abono en pausa, opcionalmente registrando el pago en el mismo paso.
Future<Membership?> showResumeDialog(BuildContext context, Membership membership) =>
    showDialog<Membership>(context: context, builder: (_) => _ResumeDialog(membership: membership));

class _ResumeDialog extends StatefulWidget {
  const _ResumeDialog({required this.membership});

  final Membership membership;

  @override
  State<_ResumeDialog> createState() => _ResumeDialogState();
}

class _ResumeDialogState extends State<_ResumeDialog> {
  DateTime _back = _today();
  bool _pay = true;
  late final _amount = TextEditingController(text: ThousandsFormat.formatPrice(_estimate()));
  List<PaymentMethod>? _methods;
  int? _methodId;
  bool _saving = false;
  String? _error;

  Membership get _m => widget.membership;

  @override
  void initState() {
    super.initState();
    sl<PaymentRepository>().getPaymentMethods().then((result) {
      if (!mounted) return;
      result.when(
        left: (_) => setState(() => _methods = const []),
        right: (methods) => setState(() {
          _methods = methods;
          _methodId = methods.firstWhereOrNull((m) => m.name.toLowerCase() == 'efectivo')?.paymentMethodId ?? methods.firstOrNull?.paymentMethodId;
        }),
      );
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Próximo vencimiento después de volver.
  DateTime _nextDue() {
    if (_m.plan.billingMode == BillingMode.anniversary) {
      // Mismo día del mes siguiente; si ese mes es más corto, su último día.
      final lastDay = DateTime(_back.year, _back.month + 2, 0).day;
      return DateTime(_back.year, _back.month + 1, _back.day.clamp(1, lastDay));
    }
    final day = _m.plan.billingDay;
    return _back.day < day ? DateTime(_back.year, _back.month, day) : DateTime(_back.year, _back.month + 1, day);
  }

  /// Lo que paga al volver: la cuota entera o, con día fijo, lo proporcional.
  double _estimate() {
    final price = _m.plan.price;
    if (_m.plan.billingMode == BillingMode.anniversary) return price;
    final next = _nextDue();
    final previous = DateTime(next.year, next.month - 1, next.day);
    final full = next.difference(previous).inDays;
    final used = next.difference(_back).inDays;
    if (used >= full) return price;
    return ((price * used / full) / 100).round() * 100;
  }

  Future<void> _save() async {
    final repository = sl<MembershipRepository>();
    final pause = _m.pause;
    if (pause == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    String? error;
    Membership? result;
    final resumed = await repository.updatePause(_m.id, pause.id, endDate: _back);
    resumed.when(left: (f) => error = f.message, right: (m) => result = m);
    if (error == null && _pay) {
      final amount = ThousandsFormat.parsePrice(_amount.text.trim());
      if (amount != null && amount > 0) {
        final paid = await repository.registerPayment(_m.id, periods: 1, amount: amount.toDouble(), paymentMethodId: _methodId, paymentDate: _back.isAfter(_today()) ? _today() : _back);
        paid.when(left: (f) => error = 'Se retomó, pero el pago no se pudo registrar: ${f.message}', right: (m) => result = m);
      }
    }
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final pause = _m.pause;
    final next = _nextDue();
    final days = pause == null ? 0 : _back.difference(pause.start).inDays;
    final newDay = _m.plan.billingMode == BillingMode.anniversary ? _back.day : _m.plan.billingDay;
    final oldDay = _m.plan.billingMode == BillingMode.anniversary ? (_m.paidUntil ?? _m.startDate).day : _m.plan.billingDay;

    return AlertDialog(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Retomar abono de ${_m.clientName}'),
        if (pause != null) ...[
          const SizedBox(height: 4),
          Text('En pausa desde el ${dayLabel(pause.start)} ($days días)${pause.reason != null ? ' · ${pause.reason}' : ''}',
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ]),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            _DateField(
              label: 'Vuelve el',
              value: _back == _today() ? 'Hoy, ${weekdayLabel(_back)}' : weekdayLabel(_back),
              helper: 'Desde este día se cuenta su nuevo mes.',
              onTap: () async {
                final picked = await _pickDay(context, _back, first: pause?.start.add(const Duration(days: 1)), last: _today());
                if (picked != null) {
                  setState(() {
                    _back = picked;
                    _amount.text = ThousandsFormat.formatPrice(_estimate());
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Registrar el pago ahora'),
              subtitle: Text('Cuota del ${dayLabel(_back)} al ${dayLabel(next)}'),
              value: _pay,
              onChanged: (v) => setState(() => _pay = v),
            ),
            if (_pay) ...[
              const SizedBox(height: 8),
              PriceField(
                controller: _amount,
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                  border: const OutlineInputBorder(),
                  helperText: _m.plan.billingMode == BillingMode.fixedDay && _estimate() < _m.plan.price ? 'Proporcional hasta el día ${_m.plan.billingDay}.' : null,
                ),
              ),
              const SizedBox(height: 12),
              if (_methods == null)
                const LinearProgressIndicator()
              else
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final method in _methods!)
                    ChoiceChip(label: Text(method.name), selected: method.paymentMethodId == _methodId, showCheckmark: false, onSelected: (_) => setState(() => _methodId = method.paymentMethodId)),
                ]),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _m.plan.billingMode == BillingMode.anniversary ? 'Desde ahora vence el $newDay de cada mes' : 'Sigue venciendo el día $newDay',
                  style: textTheme.titleSmall?.copyWith(color: scheme.onSecondaryContainer),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  if (_m.plan.billingMode == BillingMode.anniversary && oldDay != newDay) ...[
                    Text('Vencía el $oldDay', style: textTheme.bodyMedium?.copyWith(color: scheme.onSecondaryContainer, decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16, color: scheme.onSecondaryContainer),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      _pay ? 'Al día hasta el ${dayLabel(next)}' : 'La cuota del ${dayLabel(_back)} queda pendiente',
                      style: textTheme.bodyMedium?.copyWith(color: scheme.onSecondaryContainer),
                    ),
                  ),
                ]),
                if (_m.plan.billingMode == BillingMode.anniversary && newDay > 28) ...[
                  const SizedBox(height: 4),
                  Text('En meses más cortos vence el último día.', style: textTheme.bodySmall?.copyWith(color: scheme.onSecondaryContainer)),
                ],
              ]),
            ),
            if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: scheme.error))],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_pay ? 'Retomar y registrar ${money(ThousandsFormat.parsePrice(_amount.text.trim()) ?? 0)}' : 'Retomar'),
        ),
      ],
    );
  }
}

// ─── Avisar ──────────────────────────────────────────────────────────────

/// Avisar de la cuota a uno o varios clientes. Devuelve true si se mandó.
Future<bool?> showReminderDialog(BuildContext context, List<Membership> memberships) =>
    showDialog<bool>(context: context, builder: (_) => _ReminderDialog(memberships: memberships));

class _ReminderDialog extends StatefulWidget {
  const _ReminderDialog({required this.memberships});

  final List<Membership> memberships;

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  bool _app = true;
  bool _whatsApp = false;
  late final _message = TextEditingController(text: _defaultMessage());
  bool _saving = false;
  String? _error;

  bool get _single => widget.memberships.length == 1;

  String _defaultMessage() {
    final m = widget.memberships.first;
    final first = m.clientName.split(' ').first;
    if (m.owes && m.overdueSince != null) {
      return 'Hola $first, tu cuota del abono "${m.plan.name}" (${money(m.debt)}) venció el ${dayLabel(m.overdueSince!)}. Podés pagarla en recepción. ¡Gracias!';
    }
    if (m.nextDueDate != null) {
      return 'Hola $first, tu cuota del abono "${m.plan.name}" (${money(m.nextDueAmount ?? m.plan.price)}) vence el ${dayLabel(m.nextDueDate!)}. ¡Gracias!';
    }
    return 'Hola $first, recordá pagar tu abono "${m.plan.name}". ¡Gracias!';
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final ids = widget.memberships.map((m) => m.id).toList();
    if (_whatsApp && _single) await Clipboard.setData(ClipboardData(text: _message.text.trim()));
    final repository = sl<MembershipRepository>();
    String? error;
    var sent = 0;
    var withoutApp = 0;
    if (_app) {
      final result = await repository.sendReminders(ids, message: _single ? _message.text.trim() : null);
      result.when(left: (f) => error = f.message, right: (value) => (sent, withoutApp) = value);
    } else if (_whatsApp) {
      final result = await repository.sendReminders(ids, channel: 'WHATSAPP', message: _message.text.trim());
      result.when(left: (f) => error = f.message, right: (_) {});
    }
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    final parts = [
      if (_app && sent > 0) sent == 1 ? 'Aviso enviado.' : '$sent avisos enviados.',
      if (_app && withoutApp > 0) withoutApp == 1 ? '1 cliente no tiene la app.' : '$withoutApp clientes no tienen la app.',
      if (_whatsApp && _single) 'Mensaje copiado para WhatsApp.',
    ];
    if (parts.isNotEmpty) messenger.showSnackBar(SnackBar(content: Text(parts.join(' '))));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final m = widget.memberships.first;
    final withoutApp = widget.memberships.where((x) => !x.hasApp).length;

    return AlertDialog(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_single ? 'Avisar a ${m.clientName}' : 'Avisar a ${widget.memberships.length} clientes'),
        const SizedBox(height: 4),
        Text(
          _single
              ? [
                  if (m.owes && m.overdueSince != null) 'Cuota vencida el ${dayLabel(m.overdueSince!)} · debe ${money(m.debt)}' else if (m.nextDueDate != null) 'Vence el ${dayLabel(m.nextDueDate!)}',
                  if (m.lastReminderAt != null) 'último aviso el ${dayLabel(m.lastReminderAt!)}',
                ].join(' · ')
              : 'A cada uno le llega su propio mensaje con su cuota.',
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ]),
      content: SizedBox(
        width: 540,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text('Por dónde', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilterChip(label: const Text('Notificación en la app'), selected: _app, showCheckmark: false, onSelected: (v) => setState(() => _app = v)),
            if (_single)
              FilterChip(label: const Text('WhatsApp (copia el mensaje)'), selected: _whatsApp, showCheckmark: false, onSelected: (v) => setState(() => _whatsApp = v)),
          ]),
          const SizedBox(height: 4),
          Text(
            _app
                ? (withoutApp == 0
                    ? 'Le llega a la app de Turni y lo ve en la pestaña Gym.'
                    : (_single ? '${m.clientName.split(' ').first} no tiene la app: no le va a llegar la notificación.' : '$withoutApp no tienen la app: a ellos no les llega.'))
                : 'No le va a llegar nada en la app.',
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (_single) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _message,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Mensaje', border: OutlineInputBorder(), counterText: ''),
            ),
          ],
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: scheme.error))],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving || (!_app && !_whatsApp) ? null : _send,
          child: Text(_whatsApp && !_app ? 'Copiar mensaje' : (_whatsApp ? 'Enviar y copiar' : 'Enviar aviso')),
        ),
      ],
    );
  }
}

// ─── Cambiar abono ───────────────────────────────────────────────────────

/// Cambiar el abono del cliente por otro del mismo servicio.
Future<Membership?> showChangePlanDialog(BuildContext context, Membership membership, List<MembershipPlan> plans) =>
    showDialog<Membership>(context: context, builder: (_) => _ChangePlanDialog(membership: membership, plans: plans));

class _ChangePlanDialog extends StatefulWidget {
  const _ChangePlanDialog({required this.membership, required this.plans});

  final Membership membership;
  final List<MembershipPlan> plans;

  @override
  State<_ChangePlanDialog> createState() => _ChangePlanDialogState();
}

class _ChangePlanDialogState extends State<_ChangePlanDialog> {
  int? _planId;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_planId == null) return;
    setState(() => _saving = true);
    final result = await sl<MembershipRepository>().changePlan(widget.membership.id, _planId!);
    if (!mounted) return;
    result.when(
      left: (f) => setState(() {
        _saving = false;
        _error = f.message;
      }),
      right: (m) => Navigator.of(context).pop(m),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.plans.where((p) => p.id != widget.membership.plan.id && !p.archived && p.partitionId == widget.membership.plan.partitionId).toList();
    return AlertDialog(
      title: Text('Cambiar abono de ${widget.membership.clientName}'),
      content: SizedBox(
        width: 480,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text('Hoy tiene "${widget.membership.plan.name}". El nuevo arranca hoy; los pagos anteriores quedan en el abono viejo.'),
          const SizedBox(height: 12),
          if (options.isEmpty)
            const Text('No hay otros abonos en este servicio.')
          else
            RadioGroup<int>(
              groupValue: _planId,
              onChanged: (value) => setState(() => _planId = value),
              child: Column(children: [
                for (final plan in options)
                  RadioListTile<int>(value: plan.id, contentPadding: EdgeInsets.zero, title: Text(plan.name), subtitle: Text('${money(plan.price)} por mes · ${plan.dueLabel}')),
              ]),
            ),
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _saving || _planId == null ? null : _save, child: const Text('Cambiar')),
      ],
    );
  }
}

// ─── Asignar abono ───────────────────────────────────────────────────────

/// Darle un abono con cuotas a un cliente. Lee los abonos al momento (uno
/// recién creado en Configuración ya aparece). Devuelve el alta.
Future<ClientSubscription?> showAssignMembershipDialog(BuildContext context, {required int clientId, required String clientName}) =>
    showDialog<ClientSubscription>(context: context, builder: (_) => _AssignDialog(clientId: clientId, clientName: clientName));

class _AssignDialog extends StatefulWidget {
  const _AssignDialog({required this.clientId, required this.clientName});

  final int clientId;
  final String clientName;

  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  List<MembershipPlansPartition>? _partitions;
  int? _planId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    sl<MembershipRepository>().plans().then((result) {
      if (!mounted) return;
      result.when(
        left: (f) => setState(() => _error = f.message),
        right: (value) => setState(() {
          _partitions = value;
          _planId = value.expand((p) => p.plans).where((p) => !p.archived).firstOrNull?.id;
        }),
      );
    });
  }

  Future<void> _save() async {
    if (_planId == null) return;
    setState(() => _saving = true);
    final result = await sl<SubscriptionRepository>().subscribeClient({
      'client_id': widget.clientId,
      'subscription_id': _planId,
      'created_by_admin': sl<AuthCubit>().state.userCredential!.admin!.adminId,
    }, widget.clientId);
    if (!mounted) return;
    result.when(
      left: (f) => setState(() {
        _saving = false;
        _error = f.message;
      }),
      right: (subscription) => Navigator.of(context).pop(subscription),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final partitions = _partitions;
    return AlertDialog(
      title: Text('Abono para ${widget.clientName}'),
      content: SizedBox(
        width: 520,
        child: partitions == null && _error == null
            ? const LinearProgressIndicator()
            : SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                  if (partitions != null && partitions.every((p) => p.plans.where((x) => !x.archived).isEmpty))
                    const Text('Todavía no hay abonos. Creálos en Configuración › Abonos.')
                  else if (partitions != null)
                    RadioGroup<int>(
                      groupValue: _planId,
                      onChanged: (value) => setState(() => _planId = value),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        for (final partition in partitions)
                          if (partition.plans.any((p) => !p.archived)) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: Text(partition.partition.name, style: textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
                            ),
                            for (final plan in partition.plans.where((p) => !p.archived))
                              RadioListTile<int>(
                                value: plan.id,
                                contentPadding: EdgeInsets.zero,
                                title: Text(plan.name),
                                subtitle: Text('${money(plan.price)} por mes · ${plan.dueLabel}'),
                              ),
                          ],
                      ]),
                    ),
                  const SizedBox(height: 8),
                  Text('Arranca hoy. La primera cuota queda pendiente hasta que la registres.', style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: scheme.error))],
                ]),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _saving || _planId == null ? null : _save, child: const Text('Asignar abono')),
      ],
    );
  }
}
