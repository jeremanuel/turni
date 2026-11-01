import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../../core/presentation/components/loading/app_skeleton.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_portal/flutter_portal.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/date_picker/date_dropdown_field.dart';
import '../../../core/presentation/components/inputs/option_chip.dart';
import '../../../core/presentation/components/links/entity_links.dart';
import '../../../core/utils/admin_features.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/utils/thousands_format.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/membership/membership.dart';
import '../../../domain/entities/payment/payment_method.dart';
import '../../../domain/repositories/membership_repository.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../../core/cubit/auth/auth_cubit.dart';
import '../../../core/presentation/components/inputs/client_search_field.dart';
import '../club_config/widgets/price_field.dart';
import 'widgets/membership_widgets.dart';

/// Botón "Registrar pago" (abre [showRegisterPaymentDialog]). Respeta el permiso.
class RegisterPaymentButton extends StatelessWidget {
  const RegisterPaymentButton({super.key, this.client, required this.onPaid, this.compact = false, this.filled = false});

  final Client? client;
  final VoidCallback onPaid;
  final bool compact;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (!Permissions.can(Permissions.PAGOS_REGISTRAR)) return const SizedBox.shrink();
    Future<void> open() async {
      final paid = await showRegisterPaymentDialog(context, client: client);
      if (paid == true) onPaid();
    }

    if (compact) return IconButton(tooltip: 'Registrar pago', icon: const Icon(Icons.add_card_outlined), onPressed: open);
    if (filled) return FilledButton.icon(onPressed: open, icon: const Icon(Icons.add, size: 18), label: const Text('Registrar pago'));
    return OutlinedButton.icon(onPressed: open, icon: const Icon(Icons.add_card_outlined, size: 18), label: const Text('Registrar pago'));
  }
}

/// Registrar un pago: la cuota de un abono (eligiendo cuántas) u otra cosa
/// (un turno, un producto, una seña). Sin [client], primero se elige. Con
/// [membership], arranca con ese abono elegido. Devuelve true si se registró.
Future<bool?> showRegisterPaymentDialog(BuildContext context, {Client? client, Membership? membership}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => Portal(child: _RegisterPaymentDialog(client: client, membership: membership)),
  );
}

class _RegisterPaymentDialog extends StatefulWidget {
  const _RegisterPaymentDialog({this.client, this.membership});

  final Client? client;
  final Membership? membership;

  @override
  State<_RegisterPaymentDialog> createState() => _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState extends State<_RegisterPaymentDialog> {
  final _memberships = sl<MembershipRepository>();
  final _payments = sl<PaymentRepository>();
  final _formKey = GlobalKey<FormBuilderState>();
  final _amount = TextEditingController();
  final _observation = TextEditingController();

  late Client? _client = widget.client;

  /// Abierto desde el estado de cuotas: solo ese abono, sin elegir cliente ni "Otra cosa".
  bool get _membershipOnly => widget.client == null && widget.membership != null;
  List<Membership> _active = const [];
  bool _loadingMemberships = false;

  /// null = "Otra cosa".
  Membership? _selected;
  int _periods = 1;
  List<PaymentMethod>? _methods;
  int? _methodId;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // El botón muestra el monto mientras se escribe.
    _amount.addListener(() {
      if (mounted) setState(() {});
    });
    _loadMethods();
    if (widget.membership != null) {
      _active = [widget.membership!];
      _select(widget.membership);
    }
    if (_client != null) _loadMemberships();
  }

  int? get _clientId => _client?.intClientId ?? widget.membership?.clientId;

  @override
  void dispose() {
    _amount.dispose();
    _observation.dispose();
    super.dispose();
  }

  Future<void> _loadMethods() async {
    final result = await _payments.getPaymentMethods();
    if (!mounted) return;
    result.when(
      left: (_) => setState(() => _methods = const []),
      right: (methods) => setState(() {
        _methods = methods;
        _methodId = methods.firstWhereOrNull((m) => m.name.toLowerCase() == 'efectivo')?.paymentMethodId ?? methods.firstOrNull?.paymentMethodId;
      }),
    );
  }

  Future<void> _loadMemberships() async {
    final client = _client;
    if (client == null || !AdminFeatures.memberships) return;
    setState(() => _loadingMemberships = true);
    final result = await _memberships.clientMemberships(client.intClientId);
    if (!mounted) return;
    result.when(
      left: (_) => setState(() => _loadingMemberships = false),
      right: (value) => setState(() {
        _loadingMemberships = false;
        _active = value.active;
        // El que estaba elegido, refrescado; si no, el primero.
        final current = _active.firstWhereOrNull((m) => m.id == _selected?.id) ?? (widget.membership == null && _selected == null ? _active.firstOrNull : null);
        if (current != null || _active.isEmpty) _select(current);
      }),
    );
  }

  void _select(Membership? membership) {
    _selected = membership;
    _periods = membership == null ? 1 : (membership.unpaidCount > 0 ? membership.unpaidCount.clamp(1, membership.upcoming.length.clamp(1, 6)) : 1);
    _syncAmount();
  }

  void _syncAmount() {
    final membership = _selected;
    if (membership == null) {
      _amount.text = '';
      return;
    }
    final total = membership.upcoming.take(_periods).fold<double>(0, (sum, p) => sum + p.amount);
    _amount.text = total == 0 ? '' : ThousandsFormat.formatPrice(total);
  }

  Future<void> _save() async {
    final client = _client;
    final amount = ThousandsFormat.parsePrice(_amount.text.trim());
    if (_clientId == null) return setState(() => _error = 'Elegí el cliente.');
    if (amount == null || amount <= 0) return setState(() => _error = 'Poné el monto.');
    setState(() {
      _saving = true;
      _error = null;
    });

    final membership = _selected;
    final String? error;
    if (membership != null) {
      final result = await _memberships.registerPayment(
        membership.id,
        periods: _periods,
        amount: amount.toDouble(),
        paymentMethodId: _methodId,
        paymentDate: _date,
        observation: _observation.text.trim().isEmpty ? null : _observation.text.trim(),
      );
      error = result.when(left: (f) => f.message, right: (_) => null);
    } else if (client != null) {
      final auth = sl<AuthCubit>();
      final result = await _payments.createPayment({
        'amount': amount.toDouble(),
        'payment_method_id': _methodId,
        'observation': _observation.text.trim().isEmpty ? null : _observation.text.trim(),
        'client_subscription_id': null,
        'client_id': client.intClientId,
        'client': client.copyWith(clubId: auth.getClubId()),
        'created_by_admin': auth.state.userCredential!.admin!.adminId,
      });
      error = result.when(left: (f) => f.message, right: (_) => null);
    } else {
      error = 'Elegí el cliente.';
    }
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final client = _client;
    final membership = _selected;
    final total = ThousandsFormat.parsePrice(_amount.text.trim());

    final subtitleStyle = textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    Widget label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: textTheme.titleSmall));
    Widget fieldLabel(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(text, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        );
    const gap = SizedBox(height: 18);

    // "¿Qué paga?": las opciones lado a lado y todas del mismo alto. El abono,
    // un poco más ancho que "Otra cosa" (como en el diseño).
    final concepts = <(int, Widget)>[
      for (final m in _active)
        (
          14,
          _ConceptCard(
            selected: membership?.id == m.id,
            title: 'Abono ${m.plan.name}',
            subtitle: '${money(m.plan.price)} por mes · ${dueDescription(m)}',
            status: m.status == MembershipStatus.ok ? null : m.status,
            onTap: () => setState(() => _select(m)),
          ),
        ),
      if (!_membershipOnly)
        (
          10,
          _ConceptCard(
            selected: membership == null,
            title: 'Otra cosa',
            subtitle: 'Un turno, un producto o una seña',
            onTap: () => setState(() => _select(null)),
          ),
        ),
    ];

    return AlertDialog(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Registrar pago'),
        if (client != null && widget.client != null) ...[
          const SizedBox(height: 4),
          ClientLink(clientId: client.intClientId, name: client.person?.fullName.trim() ?? 'Cliente', style: subtitleStyle),
        ] else if (_membershipOnly) ...[
          const SizedBox(height: 4),
          ClientLink(clientId: widget.membership!.clientId, name: widget.membership!.clientName, style: subtitleStyle),
        ],
      ]),
      content: SizedBox(
        width: 640,
        child: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.client == null && !_membershipOnly) ...[
                  ClientSearchFormField(
                    name: 'client',
                    isRequired: true,
                    onChanged: (picked) {
                      setState(() {
                        _client = picked;
                        _active = const [];
                        _select(null);
                      });
                      _loadMemberships();
                    },
                  ),
                  gap,
                ],
                if (client != null || _membershipOnly) ...[
                  label('¿Qué paga?'),
                  if (_loadingMemberships) const Padding(padding: EdgeInsets.only(bottom: 8), child: LinearProgressIndicator()),
                  IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      for (final (i, (flex, card)) in concepts.indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(flex: flex, child: card),
                      ],
                      // Una sola opción: no ocupa todo el ancho.
                      if (concepts.length == 1) const Spacer(flex: 10),
                    ]),
                  ),
                  if (membership != null && membership.upcoming.isNotEmpty) ...[
                    gap,
                    label('¿Qué cuotas?'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final (i, period) in membership.upcoming.indexed)
                        OptionChip(
                          selected: i < _periods,
                          label: _capitalize(monthLong(period.start)),
                          subtitle: _periodSubtitle(membership, period),
                          // Se paga en orden: tocar una marca todas las anteriores.
                          onTap: () => setState(() {
                            _periods = (i + 1 == _periods && i > 0) ? i : i + 1;
                            _syncAmount();
                          }),
                        ),
                    ]),
                  ],
                  gap,
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        fieldLabel('Monto'),
                        PriceField(
                          controller: _amount,
                          decoration: InputDecoration(
                            prefixText: '\$ ',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            border: const OutlineInputBorder(),
                            helperText: membership == null
                                ? 'Lo que pagó.'
                                : (_periods == 1 ? 'El precio de la cuota. Podés cambiarlo si paga distinto.' : '$_periods cuotas.'),
                            helperMaxLines: 2,
                          ),
                        ),
                      ]),
                    ),
                    if (membership != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          fieldLabel('Fecha'),
                          DateDropdownField(
                            value: _date,
                            firstDate: DateTime(DateTime.now().year - 1),
                            lastDate: DateTime.now(),
                            onChanged: (picked) => setState(() => _date = picked),
                          ),
                        ]),
                      ),
                    ],
                  ]),
                  gap,
                  label('Medio de pago'),
                  if (_methods == null)
                    const LinearProgressIndicator()
                  else
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final method in _methods!)
                        OptionChip(
                          label: method.name,
                          selected: method.paymentMethodId == _methodId,
                          onTap: () => setState(() => _methodId = method.paymentMethodId),
                        ),
                    ]),
                  gap,
                  fieldLabel('Observación (opcional)'),
                  TextField(
                    controller: _observation,
                    maxLength: 500,
                    minLines: 2,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Ej.: pagó la mitad, completa el viernes',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  if (membership != null && membership.upcoming.isNotEmpty) ...[
                    gap,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(Icons.check, size: 20, color: scheme.onSecondaryContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            [
                              if (membership.status == MembershipStatus.paused) 'Retoma el abono ese día.',
                              'Queda al día hasta el ${dayLabel(membership.upcoming[(_periods - 1).clamp(0, membership.upcoming.length - 1)].end)}.',
                            ].join(' '),
                            style: textTheme.bodyMedium?.copyWith(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: scheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving || _clientId == null ? null : _save,
          child: _saving
              ? const InlineSpinner(size: 16)
              : Text(total == null || total <= 0 ? 'Registrar' : 'Registrar ${money(total)}'),
        ),
      ],
    );
  }

  static String _capitalize(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  static String _periodSubtitle(Membership membership, MembershipPeriod period) {
    final since = daysSince(period.start);
    final prefix = period.prorated ? 'Proporcional · ' : '';
    if (since > membership.plan.graceDays) return '${prefix}Vencida · ${dayLabel(period.start)}';
    if (since >= 0) return '${prefix}Vence hoy o en gracia · ${dayLabel(period.start)}';
    return '${prefix}Vence el ${dayLabel(period.start)}';
  }
}

class _ConceptCard extends StatelessWidget {
  const _ConceptCard({required this.selected, required this.title, required this.subtitle, required this.onTap, this.status});

  final bool selected;
  final String title;
  final String subtitle;
  final MembershipStatus? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: textTheme.titleSmall?.copyWith(color: selected ? scheme.onPrimaryContainer : null))),
              if (status != null) MembershipStatusChip(status: status!),
            ]),
            const SizedBox(height: 4),
            Text(subtitle, style: textTheme.bodySmall?.copyWith(color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
