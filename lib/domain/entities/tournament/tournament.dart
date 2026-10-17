/// Torneos del club (`/admin/tournament`), categorías de los clientes
/// (`/admin/categories`) y ranking (`/admin/ranking`). Ver `turni_mono_be`,
/// docs/feature/TORNEOS.md.
library;

DateTime? _date(dynamic v) => v == null ? null : DateTime.parse(v as String).toLocal();
double? _double(dynamic v) => v == null ? null : (v as num).toDouble();
List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
    (v as List? ?? const []).map((e) => f(e as Map<String, dynamic>)).toList();

enum TournamentStatus { draft, open, closed, inProgress, finished, cancelled }

enum TournamentFormat { singleElimination, groupsKnockout, league }

enum TournamentAdmission { single, sum, open }

enum TournamentBranch { male, female, mixed }

enum FeeMode { perTeam, perPlayer }

enum ResultMode { consensus, admin }

enum Seeding { random, ranking }

enum ScoreMode { sets, points }

enum EntryStatus { pending, confirmed, waitlist, out, withdrawn }

enum MatchStatus { pending, ready, reported, disputed, confirmed, walkover }

enum CategoryObservation { none, up, down }

const _statusCodes = {
  'DRAFT': TournamentStatus.draft,
  'OPEN': TournamentStatus.open,
  'CLOSED': TournamentStatus.closed,
  'IN_PROGRESS': TournamentStatus.inProgress,
  'FINISHED': TournamentStatus.finished,
  'CANCELLED': TournamentStatus.cancelled,
};
const _formatCodes = {
  'SINGLE_ELIMINATION': TournamentFormat.singleElimination,
  'GROUPS_KNOCKOUT': TournamentFormat.groupsKnockout,
  'LEAGUE': TournamentFormat.league,
};
const _admissionCodes = {'SINGLE': TournamentAdmission.single, 'SUM': TournamentAdmission.sum, 'OPEN': TournamentAdmission.open};
const _branchCodes = {'MALE': TournamentBranch.male, 'FEMALE': TournamentBranch.female, 'MIXED': TournamentBranch.mixed};
const _feeCodes = {'PER_TEAM': FeeMode.perTeam, 'PER_PLAYER': FeeMode.perPlayer};
const _resultCodes = {'CONSENSUS': ResultMode.consensus, 'ADMIN': ResultMode.admin};
const _seedingCodes = {'RANDOM': Seeding.random, 'RANKING': Seeding.ranking};
const _scoreCodes = {'SETS': ScoreMode.sets, 'POINTS': ScoreMode.points};
const _entryCodes = {
  'PENDING': EntryStatus.pending,
  'CONFIRMED': EntryStatus.confirmed,
  'WAITLIST': EntryStatus.waitlist,
  'OUT': EntryStatus.out,
  'WITHDRAWN': EntryStatus.withdrawn,
};
const _matchCodes = {
  'PENDING': MatchStatus.pending,
  'READY': MatchStatus.ready,
  'REPORTED': MatchStatus.reported,
  'DISPUTED': MatchStatus.disputed,
  'CONFIRMED': MatchStatus.confirmed,
  'WALKOVER': MatchStatus.walkover,
};
const _observationCodes = {'NONE': CategoryObservation.none, 'UP': CategoryObservation.up, 'DOWN': CategoryObservation.down};

T _enum<T>(Map<String, T> codes, dynamic raw, T fallback) => codes[raw] ?? fallback;
String _code<T>(Map<String, T> codes, T value) => codes.entries.firstWhere((e) => e.value == value).key;

String tournamentStatusCode(TournamentStatus s) => _code(_statusCodes, s);
String formatCode(TournamentFormat f) => _code(_formatCodes, f);
String admissionCode(TournamentAdmission a) => _code(_admissionCodes, a);
String branchCode(TournamentBranch b) => _code(_branchCodes, b);
String feeModeCode(FeeMode f) => _code(_feeCodes, f);
String resultModeCode(ResultMode r) => _code(_resultCodes, r);
String seedingCode(Seeding s) => _code(_seedingCodes, s);
String scoreModeCode(ScoreMode s) => _code(_scoreCodes, s);
String observationCode(CategoryObservation o) => _code(_observationCodes, o);

extension TournamentStatusLabel on TournamentStatus {
  String get label => switch (this) {
        TournamentStatus.draft => 'Borrador',
        TournamentStatus.open => 'Inscripción abierta',
        TournamentStatus.closed => 'Inscripción cerrada',
        TournamentStatus.inProgress => 'En juego',
        TournamentStatus.finished => 'Finalizado',
        TournamentStatus.cancelled => 'Cancelado',
      };
}

extension TournamentFormatLabel on TournamentFormat {
  String get label => switch (this) {
        TournamentFormat.singleElimination => 'Eliminación directa',
        TournamentFormat.groupsKnockout => 'Grupos + eliminación',
        TournamentFormat.league => 'Liga',
      };
}

extension TournamentBranchLabel on TournamentBranch {
  String get label => switch (this) {
        TournamentBranch.male => 'Masculino',
        TournamentBranch.female => 'Femenino',
        TournamentBranch.mixed => 'Mixto',
      };
}

extension EntryStatusLabel on EntryStatus {
  String get label => switch (this) {
        EntryStatus.pending => 'Pagos pendientes',
        EntryStatus.confirmed => 'Confirmado',
        EntryStatus.waitlist => 'En espera',
        EntryStatus.out => 'Fuera',
        EntryStatus.withdrawn => 'Se bajó',
      };
}

extension MatchStatusLabel on MatchStatus {
  String get label => switch (this) {
        MatchStatus.pending => 'Por definir',
        MatchStatus.ready => 'Por jugar',
        MatchStatus.reported => '1 de 2 cargó',
        MatchStatus.disputed => 'En disputa',
        MatchStatus.confirmed => 'Confirmado',
        MatchStatus.walkover => 'Sin jugar',
      };
}

// ---------------------------------------------------------------------------
// Catálogo
// ---------------------------------------------------------------------------

class SportCategory {
  final int id;
  final int clubTypeId;
  final String name;
  final int level;

  const SportCategory({required this.id, required this.clubTypeId, required this.name, required this.level});

  factory SportCategory.fromJson(Map<String, dynamic> json) => SportCategory(
        id: json['sport_category_id'] as int,
        clubTypeId: json['club_type_id'] as int,
        name: json['name'] as String,
        level: json['level'] as int,
      );
}

class TeamFormat {
  final int id;
  final String name;
  final int playersPerTeam;
  final int maxSubstitutes;

  const TeamFormat({required this.id, required this.name, required this.playersPerTeam, required this.maxSubstitutes});

  factory TeamFormat.fromJson(Map<String, dynamic> json) => TeamFormat(
        id: json['sport_team_format_id'] as int,
        name: json['name'] as String,
        playersPerTeam: json['players_per_team'] as int,
        maxSubstitutes: json['max_substitutes'] as int,
      );

  String get description => maxSubstitutes > 0
      ? '$playersPerTeam por equipo · hasta $maxSubstitutes suplentes'
      : '$playersPerTeam por equipo';
}

class TournamentCourt {
  final int id;
  final String name;

  const TournamentCourt({required this.id, required this.name});

  factory TournamentCourt.fromJson(Map<String, dynamic> json) =>
      TournamentCourt(id: json['partition_physical_id'] as int, name: json['name'] as String);
}

class CatalogSport {
  final int clubTypeId;
  final String name;
  final bool categorizes;
  final ScoreMode defaultScoreMode;
  final List<TeamFormat> formats;
  final List<SportCategory> categories;
  final List<TournamentCourt> courts;

  const CatalogSport({
    required this.clubTypeId,
    required this.name,
    required this.categorizes,
    required this.defaultScoreMode,
    required this.formats,
    required this.categories,
    required this.courts,
  });

  factory CatalogSport.fromJson(Map<String, dynamic> json) => CatalogSport(
        clubTypeId: json['club_type_id'] as int,
        name: json['name'] as String,
        categorizes: json['categorizes'] as bool? ?? false,
        defaultScoreMode: _enum(_scoreCodes, json['default_score_mode'], ScoreMode.points),
        formats: _list(json['formats'], TeamFormat.fromJson),
        categories: _list(json['categories'], SportCategory.fromJson),
        courts: _list(json['courts'], TournamentCourt.fromJson),
      );
}

// ---------------------------------------------------------------------------
// Torneo
// ---------------------------------------------------------------------------

class Tournament {
  final int id;
  final String name;
  final String? description;
  final TournamentStatus status;
  final int clubTypeId;
  final String sportName;
  final TeamFormat teamFormat;
  final TournamentFormat format;
  final int? groupSize;
  final int? qualifiersPerGroup;
  final Seeding seeding;
  final TournamentAdmission admission;
  final SportCategory? category;
  final int? lowerCategoriesAllowed;
  final List<String> admittedCategories;
  final int? sumMin;
  final TournamentBranch branch;
  final bool countsForRanking;
  final int minTeams;
  final int maxTeams;
  final double? entryFee;
  final FeeMode feeMode;
  final double? sharePerPlayer;
  final int minPaidPlayers;
  final int finalReminderHours;
  final int matchDurationMinutes;
  final ScoreMode scoreMode;
  final ResultMode resultMode;
  final int? autoConfirmHours;
  final String? prizes;
  final DateTime? registrationClosesAt;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final List<TournamentCourt> courts;
  final bool onlinePayments;
  final int teamsCount;
  final int waitlistCount;

  // Solo en el detalle.
  final List<TournamentEntry> entries;
  final ClosingSummary? closingSummary;
  final List<TournamentMatch> matches;
  final List<StandingGroup> standings;

  const Tournament({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.clubTypeId,
    required this.sportName,
    required this.teamFormat,
    required this.format,
    this.groupSize,
    this.qualifiersPerGroup,
    required this.seeding,
    required this.admission,
    this.category,
    this.lowerCategoriesAllowed,
    this.admittedCategories = const [],
    this.sumMin,
    required this.branch,
    required this.countsForRanking,
    required this.minTeams,
    required this.maxTeams,
    this.entryFee,
    required this.feeMode,
    this.sharePerPlayer,
    required this.minPaidPlayers,
    required this.finalReminderHours,
    required this.matchDurationMinutes,
    required this.scoreMode,
    required this.resultMode,
    this.autoConfirmHours,
    this.prizes,
    this.registrationClosesAt,
    this.startsAt,
    this.endsAt,
    this.courts = const [],
    required this.onlinePayments,
    required this.teamsCount,
    required this.waitlistCount,
    this.entries = const [],
    this.closingSummary,
    this.matches = const [],
    this.standings = const [],
  });

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        id: json['tournament_id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        status: _enum(_statusCodes, json['status'], TournamentStatus.draft),
        clubTypeId: (json['sport'] as Map<String, dynamic>)['club_type_id'] as int,
        sportName: (json['sport'] as Map<String, dynamic>)['name'] as String,
        teamFormat: TeamFormat.fromJson(json['team_format'] as Map<String, dynamic>),
        format: _enum(_formatCodes, json['format'], TournamentFormat.singleElimination),
        groupSize: json['group_size'] as int?,
        qualifiersPerGroup: json['qualifiers_per_group'] as int?,
        seeding: _enum(_seedingCodes, json['seeding'], Seeding.random),
        admission: _enum(_admissionCodes, json['admission'], TournamentAdmission.open),
        category: json['category'] == null ? null : SportCategory.fromJson(json['category'] as Map<String, dynamic>),
        lowerCategoriesAllowed: json['lower_categories_allowed'] as int?,
        admittedCategories: (json['admitted_categories'] as List? ?? const []).cast<String>(),
        sumMin: json['sum_min'] as int?,
        branch: _enum(_branchCodes, json['branch'], TournamentBranch.mixed),
        countsForRanking: json['counts_for_ranking'] as bool? ?? true,
        minTeams: json['min_teams'] as int,
        maxTeams: json['max_teams'] as int,
        entryFee: _double(json['entry_fee']),
        feeMode: _enum(_feeCodes, json['fee_mode'], FeeMode.perTeam),
        sharePerPlayer: _double(json['share_per_player']),
        minPaidPlayers: json['min_paid_players'] as int? ?? 0,
        finalReminderHours: json['final_reminder_hours'] as int? ?? 24,
        matchDurationMinutes: json['match_duration_minutes'] as int? ?? 90,
        scoreMode: _enum(_scoreCodes, json['score_mode'], ScoreMode.points),
        resultMode: _enum(_resultCodes, json['result_mode'], ResultMode.consensus),
        autoConfirmHours: json['auto_confirm_hours'] as int?,
        prizes: json['prizes'] as String?,
        registrationClosesAt: _date(json['registration_closes_at']),
        startsAt: _date(json['starts_at']),
        endsAt: _date(json['ends_at']),
        courts: _list(json['courts'], TournamentCourt.fromJson),
        onlinePayments: json['online_payments'] as bool? ?? false,
        teamsCount: json['teams_count'] as int? ?? 0,
        waitlistCount: json['waitlist_count'] as int? ?? 0,
        entries: _list(json['entries'], TournamentEntry.fromJson),
        closingSummary: json['closing_summary'] == null ? null : ClosingSummary.fromJson(json['closing_summary'] as Map<String, dynamic>),
        matches: _list(json['matches'], TournamentMatch.fromJson),
        standings: _list(json['standings'], StandingGroup.fromJson),
      );

  /// "6ta · Mixto", "Suma 13 · Masculino", "Libre · Mixto".
  String get categoryLabel {
    final cat = switch (admission) {
      TournamentAdmission.single => category?.name ?? 'Categoría',
      TournamentAdmission.sum => 'Suma ${sumMin ?? ''}',
      TournamentAdmission.open => 'Libre',
    };
    return '$cat · ${branch.label}';
  }

  String get modalityLabel => '$sportName · ${teamFormat.name}';

  bool get hasFee => entryFee != null && entryFee! > 0;

  TournamentMatch? matchById(int id) => matches.where((m) => m.id == id).firstOrNull;

  TournamentEntry? entryById(int id) => entries.where((e) => e.id == id).firstOrNull;
}

class ClosingSummary {
  final int entries;
  final int fullyPaid;
  final int meetsMinimum;
  final int belowMinimum;
  final int waitlist;

  const ClosingSummary({required this.entries, required this.fullyPaid, required this.meetsMinimum, required this.belowMinimum, required this.waitlist});

  factory ClosingSummary.fromJson(Map<String, dynamic> json) => ClosingSummary(
        entries: json['entries'] as int,
        fullyPaid: json['fully_paid'] as int,
        meetsMinimum: json['meets_minimum'] as int,
        belowMinimum: json['below_minimum'] as int,
        waitlist: json['waitlist'] as int,
      );
}

class PlayerCategory {
  final String name;
  final int level;

  /// `CLUB` (la de este club) o `PERSONAL`.
  final String source;

  const PlayerCategory({required this.name, required this.level, required this.source});

  factory PlayerCategory.fromJson(Map<String, dynamic> json) =>
      PlayerCategory(name: json['name'] as String, level: json['level'] as int, source: json['source'] as String? ?? 'PERSONAL');

  bool get isClub => source == 'CLUB';
}

class EntryPlayer {
  final int id;
  final String displayName;
  final int? clientId;
  final bool joined;
  final bool isCaptain;
  final String? name;
  final String? lastName;
  final double shareAmount;
  final double paidAmount;
  final double amountDue;
  final bool paid;
  final PlayerCategory? category;
  final String? inviteUrl;

  const EntryPlayer({
    required this.id,
    required this.displayName,
    this.clientId,
    required this.joined,
    required this.isCaptain,
    this.name,
    this.lastName,
    required this.shareAmount,
    required this.paidAmount,
    required this.amountDue,
    required this.paid,
    this.category,
    this.inviteUrl,
  });

  factory EntryPlayer.fromJson(Map<String, dynamic> json) => EntryPlayer(
        id: json['entry_player_id'] as int,
        displayName: json['display_name'] as String,
        clientId: json['client_id'] as int?,
        joined: json['joined'] as bool? ?? false,
        isCaptain: json['is_captain'] as bool? ?? false,
        name: json['name'] as String?,
        lastName: json['last_name'] as String?,
        shareAmount: _double(json['share_amount']) ?? 0,
        paidAmount: _double(json['paid_amount']) ?? 0,
        amountDue: _double(json['amount_due']) ?? 0,
        paid: json['paid'] as bool? ?? false,
        category: json['category'] == null ? null : PlayerCategory.fromJson(json['category'] as Map<String, dynamic>),
        inviteUrl: json['invite_url'] as String?,
      );

  String get shownName {
    if (name == null) return displayName;
    return [name, lastName].where((s) => s != null && s.trim().isNotEmpty).join(' ');
  }
}

class TournamentEntry {
  final int id;
  final EntryStatus status;
  final int? seed;
  final String? groupLabel;
  final String teamName;
  final List<EntryPlayer> players;
  final int paidPlayers;
  final double amountDue;
  final bool meetsMinPayments;
  final DateTime? createdAt;

  const TournamentEntry({
    required this.id,
    required this.status,
    this.seed,
    this.groupLabel,
    required this.teamName,
    required this.players,
    required this.paidPlayers,
    required this.amountDue,
    required this.meetsMinPayments,
    this.createdAt,
  });

  factory TournamentEntry.fromJson(Map<String, dynamic> json) => TournamentEntry(
        id: json['entry_id'] as int,
        status: _enum(_entryCodes, json['status'], EntryStatus.pending),
        seed: json['seed'] as int?,
        groupLabel: json['group_label'] as String?,
        teamName: (json['team'] as Map<String, dynamic>)['name'] as String,
        players: _list(json['players'], EntryPlayer.fromJson),
        paidPlayers: json['paid_players'] as int? ?? 0,
        amountDue: _double(json['amount_due']) ?? 0,
        meetsMinPayments: json['meets_min_payments'] as bool? ?? true,
        createdAt: _date(json['created_at']),
      );

  bool get isActive => status == EntryStatus.pending || status == EntryStatus.confirmed;
}

class ScoreLine {
  final int a;
  final int b;

  const ScoreLine(this.a, this.b);

  factory ScoreLine.fromJson(Map<String, dynamic> json) => ScoreLine(json['a'] as int, json['b'] as int);

  Map<String, dynamic> toJson() => {'a': a, 'b': b};
}

String scoreText(List<ScoreLine>? score) =>
    score == null || score.isEmpty ? '' : score.map((l) => '${l.a}-${l.b}').join(' · ');

class MatchTeam {
  final int entryId;
  final String name;

  const MatchTeam({required this.entryId, required this.name});

  factory MatchTeam.fromJson(Map<String, dynamic> json) => MatchTeam(entryId: json['entry_id'] as int, name: json['name'] as String);
}

class MatchSession {
  final int courtId;
  final String courtName;
  final DateTime start;
  final DateTime end;

  const MatchSession({required this.courtId, required this.courtName, required this.start, required this.end});

  factory MatchSession.fromJson(Map<String, dynamic> json) => MatchSession(
        courtId: json['partition_physical_id'] as int,
        courtName: json['court_name'] as String,
        start: _date(json['start_time'])!,
        end: _date(json['end_time'])!,
      );
}

class MatchReport {
  final int entryId;
  final String teamName;
  final String clientName;
  final List<ScoreLine> score;
  final String? winner;
  final DateTime createdAt;

  const MatchReport({required this.entryId, required this.teamName, required this.clientName, required this.score, this.winner, required this.createdAt});

  factory MatchReport.fromJson(Map<String, dynamic> json) => MatchReport(
        entryId: json['entry_id'] as int,
        teamName: json['team_name'] as String,
        clientName: json['client_name'] as String,
        score: _list(json['score'], ScoreLine.fromJson),
        winner: json['winner'] as String?,
        createdAt: _date(json['created_at'])!,
      );
}

class TournamentMatch {
  final int id;
  final String stage;
  final String? groupLabel;
  final int round;
  final String roundLabel;
  final int position;
  final MatchStatus status;
  final MatchTeam? teamA;
  final MatchTeam? teamB;
  final String? winner;
  final List<ScoreLine>? score;
  final int? nextMatchId;
  final MatchSession? session;
  final List<MatchReport> reports;

  const TournamentMatch({
    required this.id,
    required this.stage,
    this.groupLabel,
    required this.round,
    required this.roundLabel,
    required this.position,
    required this.status,
    this.teamA,
    this.teamB,
    this.winner,
    this.score,
    this.nextMatchId,
    this.session,
    this.reports = const [],
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) => TournamentMatch(
        id: json['match_id'] as int,
        stage: json['stage'] as String,
        groupLabel: json['group_label'] as String?,
        round: json['round'] as int,
        roundLabel: json['round_label'] as String,
        position: json['position'] as int,
        status: _enum(_matchCodes, json['status'], MatchStatus.pending),
        teamA: json['team_a'] == null ? null : MatchTeam.fromJson(json['team_a'] as Map<String, dynamic>),
        teamB: json['team_b'] == null ? null : MatchTeam.fromJson(json['team_b'] as Map<String, dynamic>),
        winner: json['winner'] as String?,
        score: json['score'] == null ? null : _list(json['score'], ScoreLine.fromJson),
        nextMatchId: json['next_match_id'] as int?,
        session: json['session'] == null ? null : MatchSession.fromJson(json['session'] as Map<String, dynamic>),
        reports: _list(json['reports'], MatchReport.fromJson),
      );

  bool get isKnockout => stage == 'KNOCKOUT';
  bool get hasBothTeams => teamA != null && teamB != null;
  bool get isFinished => status == MatchStatus.confirmed || status == MatchStatus.walkover;
}

class StandingRow {
  final int position;
  final int entryId;
  final String teamName;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int points;
  final int scoredFor;
  final int scoredAgainst;

  const StandingRow({
    required this.position,
    required this.entryId,
    required this.teamName,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.points,
    required this.scoredFor,
    required this.scoredAgainst,
  });

  factory StandingRow.fromJson(Map<String, dynamic> json) => StandingRow(
        position: json['position'] as int,
        entryId: json['entry_id'] as int,
        teamName: json['team_name'] as String,
        played: json['played'] as int,
        won: json['won'] as int,
        drawn: json['drawn'] as int,
        lost: json['lost'] as int,
        points: json['points'] as int,
        scoredFor: json['for'] as int,
        scoredAgainst: json['against'] as int,
      );
}

class StandingGroup {
  final String? label;
  final List<StandingRow> rows;

  const StandingGroup({this.label, required this.rows});

  factory StandingGroup.fromJson(Map<String, dynamic> json) =>
      StandingGroup(label: json['group_label'] as String?, rows: _list(json['rows'], StandingRow.fromJson));
}

/// Partido programado de un torneo, para la agenda (`GET /admin/tournament/sessions`).
class TournamentAgendaSlot {
  /// Null = lugar de la llave agendado antes de que se arme.
  final int? matchId;
  final int tournamentId;
  final String tournamentName;
  final int courtId;
  final String courtName;
  final DateTime start;
  final DateTime end;

  const TournamentAgendaSlot({
    required this.matchId,
    required this.tournamentId,
    required this.tournamentName,
    required this.courtId,
    required this.courtName,
    required this.start,
    required this.end,
  });

  factory TournamentAgendaSlot.fromJson(Map<String, dynamic> json) => TournamentAgendaSlot(
        matchId: json['match_id'] as int?,
        tournamentId: json['tournament_id'] as int,
        tournamentName: json['tournament_name'] as String,
        courtId: json['partition_physical_id'] as int,
        courtName: json['court_name'] as String,
        start: _date(json['start_time'])!,
        end: _date(json['end_time'])!,
      );
}

// ---------------------------------------------------------------------------
// Formulario
// ---------------------------------------------------------------------------

/// Lo que se manda al crear o editar (`POST`/`PUT /admin/tournament`).
class TournamentDraft {
  String name = '';
  String? description;
  int? clubTypeId;
  int? teamFormatId;
  TournamentFormat format = TournamentFormat.groupsKnockout;
  int groupSize = 4;
  int qualifiersPerGroup = 2;
  Seeding seeding = Seeding.random;
  TournamentAdmission admission = TournamentAdmission.single;
  int? categoryId;

  /// null = todas las más bajas.
  int? lowerCategoriesAllowed = 2;
  int sumMin = 13;
  TournamentBranch branch = TournamentBranch.mixed;
  bool countsForRanking = true;
  int minTeams = 8;
  int maxTeams = 16;
  double? entryFee;
  FeeMode feeMode = FeeMode.perTeam;
  int minPaidPlayers = 1;
  int finalReminderHours = 24;
  int matchDurationMinutes = 90;
  ScoreMode? scoreMode;
  ResultMode resultMode = ResultMode.consensus;
  int? autoConfirmHours = 24;
  String? prizes;
  DateTime? registrationClosesAt;
  DateTime? startsAt;
  DateTime? endsAt;
  Set<int> courtIds = {};

  TournamentDraft();

  factory TournamentDraft.from(Tournament t) => TournamentDraft()
    ..name = t.name
    ..description = t.description
    ..clubTypeId = t.clubTypeId
    ..teamFormatId = t.teamFormat.id
    ..format = t.format
    ..groupSize = t.groupSize ?? 4
    ..qualifiersPerGroup = t.qualifiersPerGroup ?? 2
    ..seeding = t.seeding
    ..admission = t.admission
    ..categoryId = t.category?.id
    ..lowerCategoriesAllowed = t.lowerCategoriesAllowed
    ..sumMin = t.sumMin ?? 13
    ..branch = t.branch
    ..countsForRanking = t.countsForRanking
    ..minTeams = t.minTeams
    ..maxTeams = t.maxTeams
    ..entryFee = t.entryFee
    ..feeMode = t.feeMode
    ..minPaidPlayers = t.minPaidPlayers
    ..finalReminderHours = t.finalReminderHours
    ..matchDurationMinutes = t.matchDurationMinutes
    ..scoreMode = t.scoreMode
    ..resultMode = t.resultMode
    ..autoConfirmHours = t.autoConfirmHours
    ..prizes = t.prizes
    ..registrationClosesAt = t.registrationClosesAt
    ..startsAt = t.startsAt
    ..endsAt = t.endsAt
    ..courtIds = t.courts.map((c) => c.id).toSet();

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'club_type_id': clubTypeId,
        'sport_team_format_id': teamFormatId,
        'format': formatCode(format),
        'group_size': format == TournamentFormat.groupsKnockout ? groupSize : null,
        'qualifiers_per_group': format == TournamentFormat.groupsKnockout ? qualifiersPerGroup : null,
        'seeding': seedingCode(seeding),
        'admission': admissionCode(admission),
        'sport_category_id': admission == TournamentAdmission.single ? categoryId : null,
        'lower_categories_allowed': admission == TournamentAdmission.single ? lowerCategoriesAllowed : null,
        'sum_min': admission == TournamentAdmission.sum ? sumMin : null,
        'branch': branchCode(branch),
        'counts_for_ranking': countsForRanking,
        'min_teams': minTeams,
        'max_teams': maxTeams,
        'entry_fee': entryFee,
        'fee_mode': feeModeCode(feeMode),
        'min_paid_players': minPaidPlayers,
        'final_reminder_hours': finalReminderHours,
        'match_duration_minutes': matchDurationMinutes,
        if (scoreMode != null) 'score_mode': scoreModeCode(scoreMode!),
        'result_mode': resultModeCode(resultMode),
        'auto_confirm_hours': resultMode == ResultMode.consensus ? autoConfirmHours : null,
        'prizes': prizes,
        'registration_closes_at': registrationClosesAt?.toUtc().toIso8601String(),
        'starts_at': startsAt?.toUtc().toIso8601String(),
        'ends_at': endsAt?.toUtc().toIso8601String(),
        'court_ids': courtIds.toList(),
      };
}

// ---------------------------------------------------------------------------
// Categorías y ranking
// ---------------------------------------------------------------------------

class SportSetting {
  final int clubTypeId;
  final String name;
  final bool categorizes;

  const SportSetting({required this.clubTypeId, required this.name, required this.categorizes});

  factory SportSetting.fromJson(Map<String, dynamic> json) => SportSetting(
        clubTypeId: json['club_type_id'] as int,
        name: json['club_type_name'] as String,
        categorizes: json['categorizes'] as bool? ?? false,
      );
}

class ClubCity {
  final String name;
  final String? province;

  const ClubCity({required this.name, this.province});

  factory ClubCity.fromJson(Map<String, dynamic> json) => ClubCity(name: json['name'] as String, province: json['province'] as String?);
}

class CategorySettings {
  final List<SportSetting> sports;
  final ClubCity? city;

  const CategorySettings({required this.sports, this.city});

  factory CategorySettings.fromJson(Map<String, dynamic> json) => CategorySettings(
        sports: _list(json['sports'], SportSetting.fromJson),
        city: json['city'] == null ? null : ClubCity.fromJson(json['city'] as Map<String, dynamic>),
      );
}

class AssignedCategory {
  final String name;
  final int level;
  final CategoryObservation observation;
  final DateTime? updatedAt;
  final String? clubName;

  const AssignedCategory({required this.name, required this.level, required this.observation, this.updatedAt, this.clubName});

  factory AssignedCategory.fromJson(Map<String, dynamic> json) => AssignedCategory(
        name: json['name'] as String,
        level: json['level'] as int,
        observation: _enum(_observationCodes, json['observation'], CategoryObservation.none),
        updatedAt: _date(json['updated_at']),
        clubName: json['club_name'] as String?,
      );
}

class CategoryChange {
  final String scope;
  final String? clubName;
  final String? from;
  final String? to;
  final CategoryObservation? observation;
  final String reason;
  final String? by;
  final DateTime createdAt;

  const CategoryChange({
    required this.scope,
    this.clubName,
    this.from,
    this.to,
    this.observation,
    required this.reason,
    this.by,
    required this.createdAt,
  });

  factory CategoryChange.fromJson(Map<String, dynamic> json) => CategoryChange(
        scope: json['scope'] as String,
        clubName: json['club_name'] as String?,
        from: (json['from'] as Map<String, dynamic>?)?['name'] as String?,
        to: (json['to'] as Map<String, dynamic>?)?['name'] as String?,
        observation: json['observation'] == null ? null : _enum(_observationCodes, json['observation'], CategoryObservation.none),
        reason: json['reason'] as String,
        by: json['by'] as String?,
        createdAt: _date(json['created_at'])!,
      );

  String get reasonLabel => switch (reason) {
        'DECLARED' => 'La definió el jugador',
        'ASSIGNED' => 'Asignada por el club',
        'PROMOTED' => 'Ascenso',
        'DEMOTED' => 'Descenso',
        'OBSERVATION' => switch (observation) {
            CategoryObservation.up => 'En observación: posible ascenso',
            CategoryObservation.down => 'En observación: posible descenso',
            _ => 'Sale de observación',
          },
        _ => reason,
      };
}

class VoteSummary {
  final int total;
  final int thumbsUp;
  final int thumbsDown;
  final int up;
  final int ok;
  final int down;

  const VoteSummary({required this.total, required this.thumbsUp, required this.thumbsDown, required this.up, required this.ok, required this.down});

  factory VoteSummary.fromJson(Map<String, dynamic> json) {
    final opinions = json['opinions'] as Map<String, dynamic>? ?? const {};
    return VoteSummary(
      total: json['total'] as int? ?? 0,
      thumbsUp: json['thumbs_up'] as int? ?? 0,
      thumbsDown: json['thumbs_down'] as int? ?? 0,
      up: opinions['up'] as int? ?? 0,
      ok: opinions['ok'] as int? ?? 0,
      down: opinions['down'] as int? ?? 0,
    );
  }

  int get opinions => up + ok + down;
}

class CategorySuggestion {
  final String direction;
  final SportCategory to;
  final List<String> reasons;

  const CategorySuggestion({required this.direction, required this.to, required this.reasons});

  factory CategorySuggestion.fromJson(Map<String, dynamic> json) => CategorySuggestion(
        direction: json['direction'] as String,
        to: SportCategory.fromJson(json['to'] as Map<String, dynamic>),
        reasons: (json['reasons'] as List? ?? const []).cast<String>(),
      );

  bool get isUp => direction == 'UP';
}

class RankPosition {
  final int position;
  final int points;

  const RankPosition({required this.position, required this.points});

  static RankPosition? fromJson(dynamic json) => json == null
      ? null
      : RankPosition(position: (json as Map<String, dynamic>)['position'] as int, points: json['points'] as int);
}

/// Ficha de categorías de un cliente en un deporte (`GET /admin/categories/clients/:id`).
class ClientSportCategories {
  final int clubTypeId;
  final String sportName;
  final bool categorizes;
  final AssignedCategory? thisClub;
  final AssignedCategory? personal;
  final List<AssignedCategory> otherClubs;
  final List<CategoryChange> history;
  final List<SportCategory> scale;
  final VoteSummary votes;
  final CategorySuggestion? suggestion;
  final RankPosition? clubRank;
  final RankPosition? cityRank;
  final String? cityName;

  const ClientSportCategories({
    required this.clubTypeId,
    required this.sportName,
    required this.categorizes,
    this.thisClub,
    this.personal,
    required this.otherClubs,
    required this.history,
    required this.scale,
    required this.votes,
    this.suggestion,
    this.clubRank,
    this.cityRank,
    this.cityName,
  });

  factory ClientSportCategories.fromJson(Map<String, dynamic> json) {
    final ranking = json['ranking'] as Map<String, dynamic>? ?? const {};
    return ClientSportCategories(
      clubTypeId: json['club_type_id'] as int,
      sportName: json['club_type_name'] as String,
      categorizes: json['categorizes'] as bool? ?? false,
      thisClub: json['this_club'] == null ? null : AssignedCategory.fromJson(json['this_club'] as Map<String, dynamic>),
      personal: json['personal'] == null ? null : AssignedCategory.fromJson(json['personal'] as Map<String, dynamic>),
      otherClubs: _list(json['other_clubs'], AssignedCategory.fromJson),
      history: _list(json['history'], CategoryChange.fromJson),
      scale: _list(json['scale'], SportCategory.fromJson),
      votes: VoteSummary.fromJson(json['votes'] as Map<String, dynamic>? ?? const {}),
      suggestion: json['suggestion'] == null ? null : CategorySuggestion.fromJson(json['suggestion'] as Map<String, dynamic>),
      clubRank: RankPosition.fromJson(ranking['club']),
      cityRank: RankPosition.fromJson(ranking['city']),
      cityName: ranking['city_name'] as String?,
    );
  }
}

class RankingRow {
  final int position;
  final int clientId;
  final String name;
  final String lastName;
  final int points;
  final int tournaments;
  final String clubName;
  final PlayerCategory? category;
  final CategoryObservation observation;

  const RankingRow({
    required this.position,
    required this.clientId,
    required this.name,
    required this.lastName,
    required this.points,
    required this.tournaments,
    required this.clubName,
    this.category,
    this.observation = CategoryObservation.none,
  });

  factory RankingRow.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return RankingRow(
      position: json['position'] as int,
      clientId: json['client_id'] as int,
      name: json['name'] as String,
      lastName: json['last_name'] as String? ?? '',
      points: json['points'] as int,
      tournaments: json['tournaments'] as int,
      clubName: json['club_name'] as String? ?? '',
      category: category == null ? null : PlayerCategory.fromJson(category),
      observation: _enum(_observationCodes, category?['observation'], CategoryObservation.none),
    );
  }

  String get fullName => [name, lastName].where((s) => s.trim().isNotEmpty).join(' ');
}

class RankingSuggestion {
  final int clientId;
  final String name;
  final String from;
  final CategorySuggestion suggestion;

  const RankingSuggestion({required this.clientId, required this.name, required this.from, required this.suggestion});

  factory RankingSuggestion.fromJson(Map<String, dynamic> json) => RankingSuggestion(
        clientId: json['client_id'] as int,
        name: [json['name'], json['last_name']].whereType<String>().where((s) => s.trim().isNotEmpty).join(' '),
        from: (json['from'] as Map<String, dynamic>)['name'] as String,
        suggestion: CategorySuggestion.fromJson(json),
      );
}

class RankingResult {
  final String scope;
  final ClubCity? city;
  final bool categorizes;
  final List<RankingRow> rows;
  final List<RankingSuggestion> suggestions;
  final int withoutClubCategory;

  const RankingResult({
    required this.scope,
    this.city,
    required this.categorizes,
    required this.rows,
    required this.suggestions,
    required this.withoutClubCategory,
  });

  factory RankingResult.fromJson(Map<String, dynamic> json) => RankingResult(
        scope: json['scope'] as String,
        city: json['city'] == null ? null : ClubCity.fromJson(json['city'] as Map<String, dynamic>),
        categorizes: json['categorizes'] as bool? ?? false,
        rows: _list(json['rows'], RankingRow.fromJson),
        suggestions: _list(json['suggestions'], RankingSuggestion.fromJson),
        withoutClubCategory: json['without_club_category'] as int? ?? 0,
      );
}
