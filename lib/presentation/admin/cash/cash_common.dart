import 'package:flutter/material.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/links/entity_links.dart';
import '../../../core/utils/thousands_format.dart';
import '../../../domain/entities/cash/cash.dart';
import '../club_config/widgets/admin_data_table.dart';
import '../tournaments/widgets/tournament_ui.dart';
import '../../core/cubit/auth/auth_cubit.dart';

export '../tournaments/widgets/tournament_ui.dart' show StatusTone;

/// Id nuevo para no registrar dos veces lo mismo si se reintenta.
String cashRequestId() {
  final admin = sl<AuthCubit>().state.userCredential?.admin?.adminId ?? 0;
  return '$admin-${DateTime.now().microsecondsSinceEpoch}';
}

String cashMoney(num value) => '\$ ${ThousandsFormat.formatPrice(value)}';

/// "+ $ 24.000", "− $ 8.500", "$ 0".
String cashSigned(num value) {
  if (value == 0) return '\$ 0';
  return '${value > 0 ? '+' : '−'} \$ ${ThousandsFormat.formatPrice(value.abs())}';
}

String cashTime(DateTime date) => '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String cashDay(DateTime date) => '${date.day} ${_months[date.month - 1]}';

/// "Canchas 1 a 4 y Sala 1" sería ideal, pero los nombres son libres: se listan.
String cashSpacesLabel(List<CashSpace> spaces) => spaces.isEmpty ? 'Sin espacios asignados' : spaces.map((space) => space.name).join(', ');

String cashMovementLabel(String kind) => switch (kind) {
      'SALE' => 'Cobro',
      'REVERSAL' => 'Anulación',
      'EXPENSE' => 'Gasto',
      'WITHDRAWAL' => 'Retiro',
      'DEPOSIT' => 'Ingreso',
      'ADJUSTMENT' => 'Ajuste',
      'REFUND' => 'Devolución',
      'CHARGEBACK' => 'Contracargo',
      'PROVIDER_FEE' || 'PLATFORM_FEE' => 'Comisión',
      _ => 'Movimiento',
    };

StatusTone cashMovementTone(ColorScheme scheme, String kind) => switch (kind) {
      'SALE' || 'DEPOSIT' => StatusTone.success(scheme),
      'ADJUSTMENT' => StatusTone.primary(scheme),
      'REVERSAL' || 'REFUND' || 'CHARGEBACK' => StatusTone.danger(scheme),
      _ => StatusTone.warning(scheme),
    };

Color cashAmountColor(ColorScheme scheme, num value) {
  if (value == 0) return scheme.onSurfaceVariant;
  return value > 0 ? StatusTone.success(scheme).foreground : scheme.error;
}

class CashTag extends StatelessWidget {
  const CashTag({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tone.foreground)),
    );
  }
}

class CashStat {
  const CashStat(this.label, this.value, {this.note});

  final String label;
  final String value;
  final String? note;
}

/// Fila de indicadores, todos del mismo alto; en pantallas angostas van de a dos.
class CashStats extends StatelessWidget {
  const CashStats({super.key, required this.stats});

  final List<CashStat> stats;

  Widget _box(BuildContext context, CashStat stat) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(stat.label, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(stat.value, style: textTheme.titleLarge),
          if (stat.note != null) ...[
            const SizedBox(height: 2),
            Text(stat.note!, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 620) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final stat in stats) SizedBox(width: width, child: _box(context, stat)),
        ]);
      }
      return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (index, stat) in stats.indexed) ...[
            if (index > 0) const SizedBox(width: 12),
            Expanded(child: _box(context, stat)),
          ],
        ]),
      );
    });
  }
}

/// Tabla de movimientos: la usan el detalle de una caja y la pestaña Movimientos.
class CashMovementsTable extends StatelessWidget {
  const CashMovementsTable({super.key, required this.movements, this.showAccount = false});

  final List<CashMovement> movements;

  /// En la pestaña general: fecha y puesto de cada movimiento.
  final bool showAccount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AdminDataTable(
      columns: [showAccount ? 'Fecha' : 'Hora', 'Tipo', 'Concepto', 'Cliente', if (showAccount) 'Caja', 'Monto'],
      defaultColumnWidth: const FlexColumnWidth(),
      columnWidths: {
        0: FixedColumnWidth(showAccount ? 120 : 76),
        1: const FixedColumnWidth(116),
        2: const FlexColumnWidth(2),
        (showAccount ? 5 : 4): const FixedColumnWidth(130),
      },
      rows: [
        for (final movement in movements)
          [
            Text(showAccount ? '${cashDay(movement.createdAt)} · ${cashTime(movement.createdAt)}' : cashTime(movement.createdAt)),
            Align(alignment: Alignment.centerLeft, child: CashTag(label: cashMovementLabel(movement.kind), tone: cashMovementTone(scheme, movement.kind))),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(movement.concept ?? '—'),
              if (movement.reason != null) Text(movement.reason!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ]),
            movement.clientId == null ? const Text('') : ClientLink(clientId: movement.clientId!, name: movement.clientName ?? 'Cliente'),
            if (showAccount) Text(movement.accountName ?? 'No aplica'),
            Text(cashSigned(movement.amount), style: TextStyle(fontWeight: FontWeight.w500, color: cashAmountColor(scheme, movement.amount))),
          ],
      ],
    );
  }
}

/// Filtro desplegable de una pantalla de caja, igual a "Todos los medios".
class CashFilterMenu<T> extends StatelessWidget {
  const CashFilterMenu({super.key, required this.tooltip, required this.value, required this.allLabel, required this.options, required this.onSelected});

  final String tooltip;
  final T? value;
  final String allLabel;
  final List<(T, String)> options;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = options.where((option) => option.$1 == value).firstOrNull;
    return PopupMenuButton<T?>(
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: (_) => [
        PopupMenuItem<T?>(value: null, child: Text(allLabel)),
        for (final (id, label) in options) PopupMenuItem<T?>(value: id, child: Text(label)),
      ],
      child: Chip(label: Text(selected?.$2 ?? allLabel), avatar: const Icon(Icons.arrow_drop_down, size: 18)),
    );
  }
}

class CashMessage extends StatelessWidget {
  const CashMessage(this.text, {super.key, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ]),
    );
  }
}
