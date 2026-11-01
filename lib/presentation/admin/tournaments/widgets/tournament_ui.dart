import 'package:flutter/material.dart';

import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/tournament/tournament.dart';
export '../../../../core/presentation/components/loading/app_skeleton.dart' show LoadError, LoadingView, InlineSpinner, SkeletonCard, SkeletonRows;

const _weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String two(int n) => n.toString().padLeft(2, '0');

/// "sáb 2 nov".
String shortDate(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// "sáb 2 nov · 16:30".
String shortDateTime(DateTime d) => '${shortDate(d)} · ${two(d.hour)}:${two(d.minute)}';

/// "02/11/2026".
String numericDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';

String hhmm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// "1 – 3 nov", "sáb 2 nov" o "Sin fecha".
String datesRange(DateTime? from, DateTime? to) {
  if (from == null) return 'Sin fecha';
  if (to == null || (to.year == from.year && to.month == from.month && to.day == from.day)) return shortDate(from);
  if (from.month == to.month) return '${from.day} – ${to.day} ${_months[to.month - 1]}';
  return '${from.day} ${_months[from.month - 1]} – ${to.day} ${_months[to.month - 1]}';
}

String money(num value) => '\$${ThousandsFormat.formatPrice(value)}';

/// "$24.000 x pareja" / "$8.000 x jugador" / "Sin cargo".
String feeLabel(Tournament t) {
  if (!t.hasFee) return 'Sin cargo';
  final who = t.feeMode == FeeMode.perPlayer ? 'jugador' : (t.teamFormat.playersPerTeam == 2 ? 'pareja' : 'equipo');
  return '${money(t.entryFee!)} x $who';
}

/// Colores de estado sobre el esquema del tema (dark-first).
class StatusTone {
  final Color background;
  final Color foreground;

  const StatusTone(this.background, this.foreground);

  static StatusTone neutral(ColorScheme s) => StatusTone(s.surfaceContainerHighest, s.onSurfaceVariant);
  static StatusTone primary(ColorScheme s) => StatusTone(s.primaryContainer, s.onPrimaryContainer);
  static StatusTone danger(ColorScheme s) => StatusTone(s.errorContainer, s.onErrorContainer);
  static StatusTone success(ColorScheme s) => s.brightness == Brightness.dark
      ? const StatusTone(Color(0xFF1E3A23), Color(0xFF8BD88F))
      : const StatusTone(Color(0xFFDCF5E3), Color(0xFF146C2E));
  static StatusTone warning(ColorScheme s) => s.brightness == Brightness.dark
      ? const StatusTone(Color(0xFF3D2F12), Color(0xFFF5C46B))
      : const StatusTone(Color(0xFFFFEFD1), Color(0xFF8A5300));

  static StatusTone ofTournament(ColorScheme s, TournamentStatus status) => switch (status) {
        TournamentStatus.draft => neutral(s),
        TournamentStatus.open => success(s),
        TournamentStatus.closed => warning(s),
        TournamentStatus.inProgress => primary(s),
        TournamentStatus.finished => neutral(s),
        TournamentStatus.cancelled => danger(s),
      };

  static StatusTone ofEntry(ColorScheme s, EntryStatus status) => switch (status) {
        EntryStatus.confirmed => success(s),
        EntryStatus.pending => warning(s),
        EntryStatus.waitlist => neutral(s),
        EntryStatus.out || EntryStatus.withdrawn => danger(s),
      };

  static StatusTone ofMatch(ColorScheme s, MatchStatus status) => switch (status) {
        MatchStatus.confirmed || MatchStatus.walkover => success(s),
        MatchStatus.reported => warning(s),
        MatchStatus.disputed => danger(s),
        MatchStatus.ready => primary(s),
        MatchStatus.pending => neutral(s),
      };
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone, this.icon});

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: tone.foreground), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tone.foreground)),
        ],
      ),
    );
  }
}

/// Sección con título dentro de una `Card` (surfaceContainerHigh por tema).
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, this.subtitle, required this.child, this.trailing});

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Dato chico con etiqueta arriba (resúmenes).
class LabeledValue extends StatelessWidget {
  const LabeledValue({super.key, required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color ?? scheme.onSurface)),
      ],
    );
  }
}

/// Aviso con ícono sobre `primaryContainer` (información) o `errorContainer`.
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.icon = Icons.info_outline, this.error = false, this.action});

  final String text;
  final IconData icon;
  final bool error;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = error ? scheme.errorContainer : scheme.primaryContainer;
    final fg = error ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: fg, fontSize: 13, height: 1.4))),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );
  }
}


