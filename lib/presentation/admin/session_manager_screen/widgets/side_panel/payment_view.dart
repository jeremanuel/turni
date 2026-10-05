import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/config/service_locator.dart';
import '../../../../../core/utils/either.dart';
import '../../../../../core/utils/thousands_format.dart';
import '../../../../../domain/entities/extra.dart';
import '../../../../../domain/entities/payment/payment.dart';
import '../../../../../domain/entities/payment/payment_method.dart';
import '../../../../../domain/entities/session.dart';
import '../../../../../domain/repositories/admin_repository.dart';
import '../../../../../domain/repositories/session_repository.dart';
import '../../../../../domain/usercases/session_user_cases.dart';
import '../../bloc/session_manager_bloc.dart';
import 'panel_common.dart';

enum _Concept { turno, consumos }

enum _Amount { all, half, player, other }

/// Medios de pago del club; se piden una vez y se reusan.
class PaymentMethods {
  PaymentMethods._();

  static List<PaymentMethod>? _cache;

  static Future<List<PaymentMethod>> load() async {
    if (_cache != null) return _cache!;
    final result = await sl<AdminRepository>().getPaymentMethods();
    if (result case Right(:final value) when value.isNotEmpty) _cache = value;
    return _cache ?? [PaymentMethod(paymentMethodId: 1, name: 'Efectivo')];
  }
}

/// "Cobrar": qué se cobra (saldo del turno o consumos pendientes), cuánto y
/// con qué medio.
class PaymentView extends StatefulWidget {
  const PaymentView({
    super.key,
    required this.session,
    required this.subtitle,
    required this.players,
    required this.onBack,
  });

  final Session session;
  final String subtitle;
  final int players;
  final VoidCallback onBack;

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  final _useCases = SessionUserCases(sl<SessionRepository>());
  final _otherController = TextEditingController();
  final _otherFocus = FocusNode();

  late _Concept _concept = widget.session.remainingSessionPrice > 0 || widget.session.remainingExtrasPrice <= 0
      ? _Concept.turno
      : _Concept.consumos;
  _Amount _amount = _Amount.all;
  List<PaymentMethod> _methods = const [];
  PaymentMethod? _method;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    PaymentMethods.load().then((methods) {
      if (!mounted) return;
      setState(() {
        _methods = methods;
        _method ??= methods.first;
      });
    });
  }

  @override
  void dispose() {
    _otherController.dispose();
    _otherFocus.dispose();
    super.dispose();
  }

  List<Extra> get _unpaidExtras => (widget.session.extras ?? const <Extra>[]).where((e) => !e.payed).toList();

  double get _pending => switch (_concept) {
        _Concept.turno => widget.session.remainingSessionPrice.clamp(0, double.infinity).toDouble(),
        _Concept.consumos => widget.session.remainingExtrasPrice.clamp(0, double.infinity).toDouble(),
      };

  int get _players => widget.players > 0 ? widget.players : 4;

  double get _chosen {
    final pending = _pending;
    if (_concept == _Concept.consumos) return pending;
    return switch (_amount) {
      _Amount.all => pending,
      _Amount.half => (pending / 2).roundToDouble(),
      _Amount.player => (pending / _players).roundToDouble(),
      _Amount.other => ThousandsFormat.parsePrice(_otherController.text) ?? 0,
    };
  }

  bool get _valid => _method != null && _chosen > 0 && _chosen <= _pending;

  Future<void> _charge() async {
    final method = _method!;
    final session = widget.session;
    final bloc = context.read<SessionManagerBloc>();
    setState(() {
      _saving = true;
      _error = null;
    });

    if (_concept == _Concept.turno) {
      final result = await _useCases.addPaymentToSession(
        session.sessionId,
        Payment(
          clientId: -1,
          paymentMethod: method,
          paymentDate: DateTime.now(),
          createdByAdmin: 1,
          amount: _chosen,
          isExtra: false,
        ),
      );
      if (result case Right(:final value)) {
        bloc.updateSessionInState(session.copyWith(payments: [...?session.payments, value]));
        widget.onBack();
        return;
      }
    } else {
      // Los consumos se cobran enteros: uno por uno con el medio elegido.
      final paid = <int?, Extra>{};
      for (final extra in _unpaidExtras) {
        final result = await _useCases.paySessionExtra(
          session.sessionId,
          extra.copyWith(payment: Payment.fromExtra(amount: extra.amount, method: method)),
        );
        if (result case Right(:final value)) paid[extra.extraId] = value;
      }
      if (paid.isNotEmpty) {
        bloc.updateSessionInState(
          session.copyWith(extras: session.extras?.map((e) => paid[e.extraId] ?? e).toList()),
        );
      }
      if (paid.length == _unpaidExtras.length) {
        widget.onBack();
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = 'No se pudo registrar el cobro. Probá de nuevo.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = widget.session;
    final chosen = _chosen;
    final rest = (session.remainingTotalPrice - chosen).clamp(0, double.infinity);

    Widget sectionTitle(String text) =>
        Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface));

    return PanelFrame(
      gap: 18,
      footer: Row(
        children: [
          PanelTextButton(label: 'Cancelar', onPressed: widget.onBack),
          const Spacer(),
          PanelFilledButton(
            label: 'Cobrar ${panelPrice(chosen)}',
            icon: Icons.check,
            loading: _saving,
            onPressed: _valid ? _charge : null,
          ),
        ],
      ),
      children: [
        PanelSubHeader(title: 'Cobrar', subtitle: widget.subtitle, onBack: widget.onBack),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionTitle('¿Qué cobrás?'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ConceptCard(
                    label: 'Turno',
                    amount: session.remainingSessionPrice.clamp(0, double.infinity).toDouble(),
                    selected: _concept == _Concept.turno,
                    onTap: () => setState(() => _concept = _Concept.turno),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ConceptCard(
                    label: 'Consumos',
                    amount: session.remainingExtrasPrice.clamp(0, double.infinity).toDouble(),
                    selected: _concept == _Concept.consumos,
                    onTap: () => setState(() => _concept = _Concept.consumos),
                  ),
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionTitle('Monto'),
            const SizedBox(height: 8),
            if (_concept == _Concept.consumos)
              Row(
                children: [
                  Expanded(child: _AmountTile(label: 'Todo', amount: _pending, selected: true, onTap: () {})),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los consumos se cobran completos.',
                      style: TextStyle(fontSize: 12, height: 16 / 12, color: scheme.outline),
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _AmountTile(
                      label: 'Todo',
                      amount: _pending,
                      selected: _amount == _Amount.all,
                      onTap: () => setState(() => _amount = _Amount.all),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AmountTile(
                      label: 'Mitad',
                      amount: (_pending / 2).roundToDouble(),
                      selected: _amount == _Amount.half,
                      onTap: () => setState(() => _amount = _Amount.half),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _AmountTile(
                      label: 'Por jugador ($_players)',
                      amount: (_pending / _players).roundToDouble(),
                      selected: _amount == _Amount.player,
                      onTap: () => setState(() => _amount = _Amount.player),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _otherTile(context)),
                ],
              ),
            ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionTitle('Medio de pago'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _methods)
                  PanelChoiceChip(
                    label: m.name,
                    selected: _method?.paymentMethodId == m.paymentMethodId,
                    onTap: () => setState(() => _method = m),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total a cobrar',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onPrimaryContainer),
                    ),
                  ),
                  Text(
                    panelPrice(chosen),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _error ??
                  (chosen > _pending
                      ? 'El monto supera lo pendiente (${panelPrice(_pending)}).'
                      : rest <= 0
                          ? 'Con este pago queda todo cobrado.'
                          : 'Después de este pago quedan ${panelPrice(rest)} por cobrar.'),
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                color: _error != null || chosen > _pending ? scheme.error : scheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _otherTile(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _amount == _Amount.other;
    return GestureDetector(
      onTap: () {
        setState(() => _amount = _Amount.other);
        _otherFocus.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? scheme.primary : scheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Otro monto',
              style: TextStyle(fontSize: 13, color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            TextField(
              controller: _otherController,
              focusNode: _otherFocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_GroupDigits()],
              onTap: () => setState(() => _amount = _Amount.other),
              onChanged: (_) => setState(() => _amount = _Amount.other),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: scheme.onSurface),
              decoration: InputDecoration.collapsed(
                hintText: '\$ 0',
                hintStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: scheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Separador de miles mientras se tipea (solo enteros).
class _GroupDigits extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return TextEditingValue.empty;
    final formatted = ThousandsFormat.group(digits);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class _ConceptCard extends StatelessWidget {
  const _ConceptCard({required this.label, required this.amount, required this.selected, required this.onTap});

  final String label;
  final double amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: scheme.primary, width: 4)
                            : Border.all(color: scheme.outline, width: 2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: fg)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(panelPrice(amount), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg)),
                const SizedBox(height: 2),
                Text('restante', style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.85))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({required this.label, required this.amount, required this.selected, required this.onTap});

  final String label;
  final double amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, color: fg)),
                const SizedBox(height: 2),
                Text(panelPrice(amount), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
