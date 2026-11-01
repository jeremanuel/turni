import 'package:flutter/material.dart';

import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/membership/membership.dart';

String money(num value) => '\$ ${ThousandsFormat.formatPrice(value)}';

/// Colores de cada estado: se distinguen también por claridad, no solo por tono.
({Color background, Color foreground, Color? border, bool dashed}) statusColors(ColorScheme scheme, MembershipStatus status) =>
    switch (status) {
      MembershipStatus.ok => (background: scheme.secondaryContainer, foreground: scheme.onSecondaryContainer, border: null, dashed: false),
      MembershipStatus.soon => (background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer, border: null, dashed: false),
      MembershipStatus.late => (background: scheme.errorContainer, foreground: scheme.onErrorContainer, border: null, dashed: false),
      MembershipStatus.pendingFirst => (background: Colors.transparent, foreground: scheme.onSurfaceVariant, border: scheme.outline, dashed: false),
      MembershipStatus.paused => (background: Colors.transparent, foreground: scheme.onSurfaceVariant, border: scheme.outline, dashed: true),
      MembershipStatus.ended => (background: Colors.transparent, foreground: scheme.outline, border: scheme.outlineVariant, dashed: false),
    };

/// Chip de estado de un abono ("Vencido", "Al día"…). [label] lo pisa ("Hace 6 días").
class MembershipStatusChip extends StatelessWidget {
  const MembershipStatusChip({super.key, required this.status, this.label});

  final MembershipStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = statusColors(Theme.of(context).colorScheme, status);
    final text = Text(
      label ?? status.label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.foreground),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: colors.border != null && !colors.dashed ? Border.all(color: colors.border!) : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (status == MembershipStatus.paused) ...[Icon(Icons.pause, size: 14, color: colors.foreground), const SizedBox(width: 4)],
        Flexible(child: text),
      ]),
    );
    if (!colors.dashed) return box;
    return CustomPaint(painter: DashedRRectPainter(color: colors.border!, radius: 8), child: box);
  }
}

/// Borde punteado redondeado (pausas).
class DashedRRectPainter extends CustomPainter {
  DashedRRectPainter({required this.color, this.radius = 8});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedRRectPainter old) => old.color != color || old.radius != radius;
}

/// Una celda de la tira de cuotas: pagada, vencida, pendiente o pausa.
enum StripTone { paid, late, pending, pause }

class StripItem {
  const StripItem({required this.title, required this.state, required this.detail, required this.tone});

  final String title;
  final String state;
  final String detail;
  final StripTone tone;
}

/// Las últimas cuotas de un abono, con las pausas en el medio.
List<StripItem> membershipStrip(Membership membership, {int count = 7}) {
  final items = <(DateTime, StripItem)>[];
  for (final period in membership.periods) {
    final late = !period.paid && daysSince(period.start) > membership.plan.graceDays;
    items.add((
      period.start,
      StripItem(
        title: monthShort(period.start),
        state: period.paid ? 'Pagada' : (late ? 'Vencida' : 'Pendiente'),
        detail: period.paid
            ? [if (period.paymentDate != null) dayLabel(period.paymentDate!), if (period.method != null) period.method!].join(' · ')
            : 'Debe ${money(period.amount)}',
        tone: period.paid ? StripTone.paid : (late ? StripTone.late : StripTone.pending),
      ),
    ));
  }
  for (final pause in membership.pauses) {
    items.add((
      pause.start,
      StripItem(
        title: monthShort(pause.start),
        state: 'Pausa',
        detail: pause.end == null ? 'Desde el ${dayLabel(pause.start)}' : '${dayLabel(pause.start)} – ${dayLabel(pause.end!)}',
        tone: StripTone.pause,
      ),
    ));
  }
  items.sort((a, b) => a.$1.compareTo(b.$1));
  final list = items.map((item) => item.$2).toList();
  return list.length <= count ? list : list.sublist(list.length - count);
}

class MembershipStrip extends StatelessWidget {
  const MembershipStrip({super.key, required this.items});

  final List<StripItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 640 ? 7 : (constraints.maxWidth >= 420 ? 4 : 3);
      final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
      final visible = items.length <= columns ? items : items.sublist(items.length - columns);
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in visible)
            SizedBox(
              width: width,
              child: _StripCell(item: item, scheme: scheme, textTheme: textTheme),
            ),
        ],
      );
    });
  }
}

class _StripCell extends StatelessWidget {
  const _StripCell({required this.item, required this.scheme, required this.textTheme});

  final StripItem item;
  final ColorScheme scheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (item.tone) {
      StripTone.paid => (scheme.surfaceContainerHighest, scheme.onSurface, scheme.outlineVariant),
      StripTone.late => (scheme.errorContainer, scheme.onErrorContainer, scheme.errorContainer),
      StripTone.pending => (Colors.transparent, scheme.onSurfaceVariant, scheme.outline),
      StripTone.pause => (Colors.transparent, scheme.onSurfaceVariant, scheme.outline),
    };
    final cell = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: item.tone == StripTone.pause ? null : Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: textTheme.labelMedium?.copyWith(color: foreground)),
          const SizedBox(height: 2),
          Text(item.state, style: textTheme.titleSmall?.copyWith(color: foreground)),
          Text(item.detail, style: textTheme.bodySmall?.copyWith(color: foreground.withValues(alpha: 0.85)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
    if (item.tone != StripTone.pause) return cell;
    return CustomPaint(painter: DashedRRectPainter(color: border), child: cell);
  }
}

/// Cómo vence un abono, en palabras: "vence el día 10" / "vence el 15 de cada mes".
String dueDescription(Membership membership) {
  if (membership.plan.billingMode == BillingMode.fixedDay) return 'vence el día ${membership.plan.billingDay}';
  final anchor = membership.nextDueDate ?? membership.paidUntil;
  return anchor == null ? 'vence a un mes del alta' : 'vence el ${anchor.day} de cada mes';
}
