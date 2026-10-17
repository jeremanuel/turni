import 'package:flutter/material.dart';

import '../../../../domain/entities/tournament/tournament.dart';
import '../../club_config/widgets/admin_data_table.dart';
import 'tournament_ui.dart';

/// Tarjeta de un partido: cancha y horario, los dos equipos (el ganador en
/// negrita) y el estado. Tocarla abre las acciones del partido.
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
    this.width = 250,
  });

  final TournamentMatch match;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = StatusTone.ofMatch(scheme, match.status);
    final m = match;
    final score = m.score;

    Widget team(MatchTeam? t, String side) {
      final won = m.winner == side;
      final games = score == null
          ? ''
          : score.map((l) => side == 'A' ? l.a : l.b).join(' ');
      return Row(
        children: [
          Expanded(
            child: Text(
              t?.name ??
                  (m.status == MatchStatus.walkover && m.winner != side
                      ? 'Pasa libre'
                      : 'A definir'),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: won ? FontWeight.w700 : FontWeight.w400,
                color: t == null
                    ? scheme.onSurfaceVariant
                    : (won || m.winner == null
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant),
              ),
            ),
          ),
          if (games.isNotEmpty)
            Text(
              games,
              style: TextStyle(
                fontSize: 13,
                fontWeight: won ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
        ],
      );
    }

    return SizedBox(
      width: width,
      child: Material(
        color: m.status == MatchStatus.disputed
            ? scheme.errorContainer.withValues(alpha: 0.18)
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: tone.foreground),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m.session == null
                                      ? 'Sin programar'
                                      : '${m.session!.courtName} · ${shortDateTime(m.session!.start)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              StatusBadge(label: m.status.label, tone: tone),
                            ],
                          ),
                          const SizedBox(height: 8),
                          team(m.teamA, 'A'),
                          const SizedBox(height: 6),
                          team(m.teamB, 'B'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Llave de eliminación: una columna por ronda, de izquierda a derecha.
class BracketView extends StatelessWidget {
  const BracketView({
    super.key,
    required this.matches,
    required this.onMatchTap,
  });

  final List<TournamentMatch> matches;
  final void Function(TournamentMatch) onMatchTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final knockout = matches.where((m) => m.isKnockout).toList();
    if (knockout.isEmpty) return const SizedBox.shrink();
    final rounds = (knockout.map((m) => m.round).toSet().toList()..sort());
    final firstCount = knockout.where((m) => m.round == rounds.first).length;
    final height = (firstCount * 118.0).clamp(160.0, 4000.0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final round in rounds) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  knockout
                      .firstWhere((m) => m.round == round)
                      .roundLabel
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final m
                          in knockout.where((m) => m.round == round).toList()
                            ..sort((a, b) => a.position.compareTo(b.position)))
                        MatchCard(match: m, onTap: () => onMatchTap(m)),
                    ],
                  ),
                ),
              ],
            ),
            if (round != rounds.last) const SizedBox(width: 40),
          ],
        ],
      ),
    );
  }
}

/// Tabla de una zona o de la liga.
class StandingsTable extends StatelessWidget {
  const StandingsTable({
    super.key,
    required this.group,
    required this.scoreMode,
    this.qualifiers,
  });

  final StandingGroup group;
  final ScoreMode scoreMode;

  /// Cuántos clasifican (se resaltan), en zonas.
  final int? qualifiers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final diffLabel = scoreMode == ScoreMode.sets ? 'Sets' : 'Goles';
    return AdminDataTable(
      // Tabla de posiciones: se compara entre filas, queda como tabla.
      mobileLayout: AdminTableMobileLayout.scroll,
      columns: [
        '#',
        group.label == null ? 'Equipo' : 'Zona ${group.label}',
        'PJ',
        'G',
        'E',
        'P',
        diffLabel,
        'Pts',
      ],
      columnWidths: const {
        0: FixedColumnWidth(44),
        1: FlexColumnWidth(3),
        2: FixedColumnWidth(52),
        3: FixedColumnWidth(48),
        4: FixedColumnWidth(48),
        5: FixedColumnWidth(48),
        6: FixedColumnWidth(72),
        7: FixedColumnWidth(56),
      },
      rowTextColors: [
        for (final r in group.rows)
          qualifiers != null && r.position <= qualifiers!
              ? scheme.onSurface
              : (qualifiers != null ? scheme.onSurfaceVariant : null),
      ],
      rows: [
        for (final r in group.rows)
          [
            Text(
              '${r.position}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: qualifiers != null && r.position <= qualifiers!
                    ? scheme.primary
                    : null,
              ),
            ),
            Text(r.teamName),
            Text('${r.played}'),
            Text('${r.won}'),
            Text('${r.drawn}'),
            Text('${r.lost}'),
            Text('${r.scoredFor}-${r.scoredAgainst}'),
            Text(
              '${r.points}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
      ],
    );
  }
}
