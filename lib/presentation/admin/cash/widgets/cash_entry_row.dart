import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/services/data_changes.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../domain/entities/cash/cash.dart';
import '../../../../domain/entities/payment/payment_method.dart';
import '../../../../domain/repositories/cash_repository.dart';
import '../cash_common.dart';
import '../dialogs/open_cash_dialog.dart';

/// Lo que eligió quien cobra: el puesto a mano (o null, el que corresponda) y
/// si el cobro está frenado hasta abrir una caja.
class CashEntrySelection {
  const CashEntrySelection({this.cashAccountId, this.blocked = false});

  final int? cashAccountId;
  final bool blocked;
}

/// Fila "Entra en" de todo cobro: a qué puesto va el efectivo, o a dónde va
/// otro medio. Si el club no usa caja no ocupa lugar.
class CashEntryRow extends StatefulWidget {
  const CashEntryRow({super.key, required this.method, required this.onChanged, this.sessionId, this.spaceLabel});

  final PaymentMethod? method;
  final ValueChanged<CashEntrySelection> onChanged;

  /// Turno que se cobra; sin turno, va al puesto principal.
  final int? sessionId;

  /// "Cancha 5", para el aviso de caja cerrada.
  final String? spaceLabel;

  @override
  State<CashEntryRow> createState() => CashEntryRowState();
}

class CashEntryRowState extends State<CashEntryRow> with ReloadOnDataChange {
  CashResolution? _resolution;
  CashPointRef? _picked;
  Timer? _debounce;

  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.cash};

  @override
  void onDataChanged(DataChange change) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), reload);
  }

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didUpdateWidget(CashEntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _picked = null;
      reload();
    } else if (oldWidget.method?.paymentMethodId != widget.method?.paymentMethodId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notify();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// También después de que el servidor frenó un cobro (la caja se cerró recién).
  Future<void> reload() async {
    final result = await sl<CashRepository>().resolveAccount(sessionId: widget.sessionId);
    if (!mounted) return;
    setState(() {
      // Sin permiso o sin red no se frena nada: el servidor decide al cobrar.
      _resolution = switch (result) {
        Right(:final value) => value,
        Left() => null,
      };
      final picked = _picked;
      if (picked != null && !(_resolution?.alternatives.any((point) => point.id == picked.id) ?? false)) _picked = null;
    });
    _notify();
  }

  bool get _isCash => widget.method?.kind == 'CASH';

  bool get _blocked {
    final resolution = _resolution;
    return resolution != null &&
        resolution.enabled &&
        _isCash &&
        _picked == null &&
        !resolution.open &&
        (resolution.requireOpenForCash || resolution.point == null);
  }

  void _notify() {
    widget.onChanged(CashEntrySelection(cashAccountId: _isCash ? _picked?.id : null, blocked: _blocked));
  }

  void _pick(CashPointRef? point) {
    setState(() => _picked = point);
    _notify();
  }

  Future<void> _open(CashPointRef point) async {
    final opened = await showOpenCashDialog(context, points: [CashPoint(id: point.id, type: 'CASH_POINT', name: point.name, isPrimary: false, active: true, spaces: const [])], selectedId: point.id);
    if (opened) reload();
  }

  String _otherDestination(PaymentMethod method) => switch (method.kind) {
        'TRANSFER' => 'Transferencias',
        'CARD' => 'Tarjeta',
        'PROVIDER' => method.name,
        _ => 'Para revisar',
      };

  Widget _row(BuildContext context, {required String label, required String title, String? subtitle, Widget? action}) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: muted),
          Text(title, key: const ValueKey('cash.entry.title'), style: textTheme.titleSmall),
          if (subtitle != null) Text(subtitle, style: muted),
        ]),
      ),
      if (action != null) action,
    ]);
  }

  Widget? _changeMenu(List<CashPointRef> options) {
    if (options.isEmpty) return null;
    return PopupMenuButton<CashPointRef>(
      tooltip: 'Cambiar puesto',
      onSelected: _pick,
      itemBuilder: (_) => [for (final option in options) PopupMenuItem(value: option, child: Text(option.name))],
      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Text('Cambiar')),
    );
  }

  Widget _closed(BuildContext context, CashResolution resolution, CashPointRef point) {
    final scheme = Theme.of(context).colorScheme;
    final tone = StatusTone.warning(scheme);
    final first = resolution.alternatives.firstOrNull;
    final space = widget.spaceLabel;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${point.name} está cerrada', key: const ValueKey('cash.entry.closed'), style: TextStyle(fontWeight: FontWeight.w600, color: tone.foreground)),
        const SizedBox(height: 2),
        Text(
          '${resolution.bySpace && space != null ? '$space cobra en ${point.name}. ' : ''}Abrila para registrar el efectivo.',
          style: TextStyle(fontSize: 13, color: tone.foreground),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (Permissions.can(Permissions.CAJA_OPERAR)) FilledButton(onPressed: () => _open(point), child: Text('Abrir ${point.name}')),
          if (first != null) OutlinedButton(onPressed: () => _pick(first), child: Text('Usar ${first.name}')),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolution = _resolution;
    final method = widget.method;
    if (resolution == null || !resolution.enabled || method == null) return const SizedBox.shrink();

    final Widget content;
    final picked = _picked;
    final point = resolution.point;
    if (!_isCash) {
      content = method.kind == null
          ? _row(context, label: 'Va a', title: 'Para revisar', subtitle: 'Este medio todavía no está clasificado.')
          : _row(context, label: 'Va a', title: _otherDestination(method), subtitle: 'No pasa por ningún puesto.');
    } else if (picked != null) {
      content = _row(
        context,
        label: 'Entra en',
        title: picked.name,
        subtitle: picked.openedByName == null ? null : 'Abrió ${picked.openedByName}',
        action: TextButton(onPressed: () => _pick(null), child: const Text('Deshacer')),
      );
    } else if (point == null) {
      content = _row(context, label: 'Entra en', title: 'Sin puesto', subtitle: 'Configurá un puesto principal para registrar el efectivo.');
    } else if (resolution.open) {
      final who = resolution.openedByName == null ? null : 'Abrió ${resolution.openedByName}';
      final manages = resolution.bySpace && widget.spaceLabel != null ? 'gestiona ${widget.spaceLabel}' : null;
      content = _row(
        context,
        label: 'Entra en',
        title: point.name,
        subtitle: [who, manages].nonNulls.join(' · '),
        action: _changeMenu(resolution.alternatives),
      );
    } else if (resolution.requireOpenForCash) {
      content = _closed(context, resolution, point);
    } else {
      content = _row(context, label: 'Entra en', title: point.name, subtitle: 'Está cerrada: el cobro queda para revisar.');
    }

    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: content);
  }
}
