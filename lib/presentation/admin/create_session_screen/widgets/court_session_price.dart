import 'package:flutter/material.dart';

import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/use_case/price/session_price_resolver.dart';
import '../../club_config/widgets/price_field.dart';
import 'rework_styles.dart';

/// Iniciales de lunes a domingo (1..7, ISO-8601). "X" para miércoles, para no
/// confundirlo con martes.
const priceDayInitials = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
const priceDayShortNames = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

String formatPriceLabel(double price) => '\$${ThousandsFormat.formatPrice(price)}';

/// Días de una franja en forma corta: "L–V", "S, D", "todos los días".
String formatDaysOfWeek(List<int> days) {
  final sorted = days.toSet().toList()..sort();
  if (sorted.length == 7) return 'todos los días';

  final parts = <String>[];
  var start = 0;
  for (var i = 1; i <= sorted.length; i++) {
    final endsRun = i == sorted.length || sorted[i] != sorted[i - 1] + 1;
    if (!endsRun) continue;
    final from = priceDayInitials[sorted[start] - 1];
    final to = priceDayInitials[sorted[i - 1] - 1];
    final runLength = i - start;
    parts.add(runLength >= 3 ? '$from–$to' : [for (var j = start; j < i; j++) priceDayInitials[sorted[j] - 1]].join(', '));
    start = i;
  }
  return parts.join(', ');
}

/// "L–V $8.000 · S, D $10.000" — precio de un turno agrupado por día. Null si
/// es el mismo todos los días.
String? formatWeekPrices(Map<int, double> weekPrices) {
  final byPrice = <double, List<int>>{};
  for (final entry in weekPrices.entries) {
    byPrice.putIfAbsent(entry.value, () => []).add(entry.key);
  }
  if (byPrice.length <= 1) return null;
  return byPrice.entries
      .map((e) => '${formatDaysOfWeek(e.value)} ${formatPriceLabel(e.key)}')
      .join(' · ');
}

/// Texto corto de la regla que aplica, para la card del turno.
String shortPriceSourceLabel(ResolvedSessionPrice resolved) {
  switch (resolved.source) {
    case SessionPriceSource.manual:
      return 'Precio manual';
    case SessionPriceSource.tariffRule:
      return resolved.tariff!.name;
    case SessionPriceSource.partitionDefault:
      return 'Precio base';
  }
}

IconData priceSourceIcon(SessionPriceSource source) {
  switch (source) {
    case SessionPriceSource.manual:
      return Icons.edit_outlined;
    case SessionPriceSource.tariffRule:
      return Icons.sell_outlined;
    case SessionPriceSource.partitionDefault:
      return Icons.sports_tennis_outlined;
  }
}

/// Selector del día de semana con el que se previsualizan los precios del
/// paso "Canchas" (la plantilla es un día que se repite en todo el rango).
class PriceDayOfWeekSelector extends StatelessWidget {
  const PriceDayOfWeekSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.loading = false,
  });

  final int selected;
  final ValueChanged<int> onChanged;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 6),
          child: Text('Precios del día', style: RW.tSmall),
        ),
        for (var day = 1; day <= 7; day++)
          Tooltip(
            message: priceDayShortNames[day - 1],
            child: InkWell(
              onTap: () => onChanged(day),
              borderRadius: BorderRadius.circular(RW.chipRadius),
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: day == selected ? RW.primary : Colors.transparent,
                  border: Border.all(color: day == selected ? RW.primary : RW.outlineVariant),
                ),
                child: Text(
                  priceDayInitials[day - 1],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: day == selected ? RW.onPrimary : RW.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        if (loading)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: RW.primary),
            ),
          ),
      ],
    );
  }
}

/// Sección de precio dentro del popover de un turno en una cancha: muestra
/// el precio del día elegido, QUÉ regla lo determina (franja de tarifa,
/// precio base de la cancha o precio manual) con un enlace a la
/// configuración de esa regla, y permite pisarlo a mano.
class CourtPriceSection extends StatefulWidget {
  const CourtPriceSection({
    super.key,
    required this.resolved,
    required this.dayOfWeek,
    required this.weekPrices,
    required this.onSetManualPrice,
    required this.onOpenTariff,
    required this.onOpenPartition,
  });

  /// Precio para [dayOfWeek].
  final ResolvedSessionPrice resolved;
  final int dayOfWeek;

  /// Precio de este turno en esta cancha para cada día (1..7).
  final Map<int, double> weekPrices;

  /// null = volver a la tarifa.
  final ValueChanged<double?> onSetManualPrice;

  /// Abre "Tarifas por horario" en la tarifa/franja que aplica.
  final VoidCallback onOpenTariff;

  /// Abre "Deportes y canchas" en esta cancha (donde está su precio base).
  final VoidCallback onOpenPartition;

  @override
  State<CourtPriceSection> createState() => _CourtPriceSectionState();
}

class _CourtPriceSectionState extends State<CourtPriceSection> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.resolved.source == SessionPriceSource.manual
        ? ThousandsFormat.formatPrice(widget.resolved.price)
        : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyManual() {
    final parsed = ThousandsFormat.parsePrice(_controller.text.trim());
    if (parsed == null || parsed < 0) return;
    widget.onSetManualPrice(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.resolved;
    final weekSummary = formatWeekPrices(widget.weekPrices);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 12, color: RW.onSurfaceVariant),
            children: [
              TextSpan(text: 'Precio (${priceDayShortNames[widget.dayOfWeek - 1]}): '),
              TextSpan(
                text: formatPriceLabel(resolved.price),
                style: const TextStyle(fontWeight: FontWeight.w700, color: RW.onPrimaryContainer),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _buildRuleBox(resolved),
        if (weekSummary != null) ...[
          const SizedBox(height: 6),
          Text('Según el día: $weekSummary', style: RW.tSmall),
        ],
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: PriceField(
                controller: _controller,
                isDense: true,
                decoration: const InputDecoration(
                  labelText: 'Precio manual',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: _applyManual,
              style: TextButton.styleFrom(
                backgroundColor: RW.surfaceHigh,
                foregroundColor: RW.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RW.buttonRadius)),
              ),
              child: const Text('Aplicar', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('El precio manual aplica a todos los días, solo en esta cancha.', style: RW.tSmall),
      ],
    );
  }

  Widget _buildRuleBox(ResolvedSessionPrice resolved) {
    final String title;
    final String detail;
    final String linkLabel;
    final VoidCallback onLink;

    switch (resolved.source) {
      case SessionPriceSource.tariffRule:
        final rule = resolved.rule!;
        title = 'Tarifa «${resolved.tariff!.name}»';
        detail = 'Franja ${formatDaysOfWeek(rule.daysOfWeek)} · ${rule.startTime}–${rule.endTime}';
        linkLabel = 'Ver tarifa';
        onLink = widget.onOpenTariff;
      case SessionPriceSource.partitionDefault when resolved.tariff != null:
        title = 'Precio base de la cancha';
        detail = 'Ninguna franja de «${resolved.tariff!.name}» cubre este horario.';
        linkLabel = 'Ver tarifa';
        onLink = widget.onOpenTariff;
      case SessionPriceSource.partitionDefault:
        title = 'Precio base de la cancha';
        detail = 'La cancha no tiene tarifa por horario asignada.';
        linkLabel = 'Ver cancha';
        onLink = widget.onOpenPartition;
      case SessionPriceSource.manual:
        title = 'Precio manual';
        detail = resolved.tariff != null
            ? 'Pisa la tarifa «${resolved.tariff!.name}».'
            : 'Pisa el precio base de la cancha.';
        linkLabel = 'Volver a la tarifa';
        onLink = () => widget.onSetManualPrice(null);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 2),
      decoration: BoxDecoration(
        color: RW.surface,
        borderRadius: BorderRadius.circular(RW.blockRadiusSmall),
        border: Border.all(color: RW.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(priceSourceIcon(resolved.source), size: 14, color: RW.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: RW.tLabel)),
            ],
          ),
          const SizedBox(height: 2),
          Text(detail, style: RW.tSmall),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onLink,
              style: TextButton.styleFrom(
                foregroundColor: RW.primary,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              icon: Icon(
                resolved.source == SessionPriceSource.manual ? Icons.undo : Icons.open_in_new,
                size: 14,
              ),
              label: Text(linkLabel),
            ),
          ),
        ],
      ),
    );
  }
}
