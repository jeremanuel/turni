import '../../../core/utils/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/tournament/tournament.dart';
import '../../../domain/repositories/tournament_repository.dart';
import '../club_config/widgets/admin_data_table.dart';
import 'widgets/bracket_view.dart';
import 'widgets/match_dialogs.dart';
import '../../../core/utils/responsive_builder.dart';
import 'widgets/tournament_ui.dart';

/// Un torneo del club: estado, inscripciones con pagos, cuadro y partidos.
class TournamentDetailPage extends StatefulWidget {
  const TournamentDetailPage({super.key, required this.tournamentId});

  final int tournamentId;

  @override
  State<TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends State<TournamentDetailPage> {
  final _repository = sl<TournamentRepository>();

  Tournament? _t;
  String? _error;
  bool _busy = false;

  bool get _canEdit => Permissions.can(Permissions.TORNEOS_EDITAR);
  bool get _canResults => Permissions.can(Permissions.TORNEOS_RESULTADOS);

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Ir a otro torneo con esta pantalla abierta reusa el mismo State.
  @override
  void didUpdateWidget(covariant TournamentDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournamentId != widget.tournamentId) {
      setState(() => _t = null);
      _load();
    }
  }

  Future<void> _load() async {
    final result = await _repository.getTournament(widget.tournamentId);
    if (!mounted) return;
    result.when(
      left: (failure) => setState(() => _error = failure.message),
      right: (t) => setState(() {
        _t = t;
        _error = null;
      }),
    );
  }

  /// Corre una acción que devuelve el torneo actualizado.
  Future<bool> _run(Future<RepositoryResponse<Tournament>> Function() action, {String? success}) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return false;
    setState(() => _busy = false);
    return result.when(
      left: (failure) {
        SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
        return false;
      },
      right: (t) {
        setState(() => _t = t);
        if (success != null) SnackbarsFunctions.showSuccessSnackbar(context, success);
        return true;
      },
    );
  }

  // -- Estado ------------------------------------------------------------------

  Future<void> _changeStatus(TournamentStatus next) async {
    final t = _t!;
    final (title, message, confirm, destructive) = switch (next) {
      TournamentStatus.open => (
          t.status == TournamentStatus.closed ? 'Reabrir la inscripción' : 'Publicar el torneo',
          'El torneo aparece en la app y los equipos se pueden anotar.',
          t.status == TournamentStatus.closed ? 'Reabrir' : 'Publicar',
          false,
        ),
      TournamentStatus.closed => (
          'Cerrar la inscripción',
          t.hasFee
              ? 'Entran al cuadro, por orden de inscripción y hasta ${t.maxTeams}, los equipos con al menos ${t.minPaidPlayers} '
                  'de ${t.teamFormat.playersPerTeam} pagos. Los que no llegan quedan fuera y se les avisa.'
              : 'Entran al cuadro, por orden de inscripción, hasta ${t.maxTeams} equipos.',
          'Cerrar inscripción',
          false,
        ),
      TournamentStatus.draft => ('Volver a borrador', 'El torneo deja de verse en la app.', 'Volver a borrador', false),
      TournamentStatus.finished => (
          'Finalizar el torneo',
          'Se cierra el torneo con los resultados cargados y se reparten los puntos de ranking.',
          'Finalizar',
          false,
        ),
      TournamentStatus.cancelled => (
          'Cancelar el torneo',
          'Se avisa a todos los jugadores. Si cobraste inscripciones, la devolución la hace el club.',
          'Cancelar torneo',
          true,
        ),
      TournamentStatus.inProgress => ('', '', '', false),
    };
    if (!await confirmAction(context, title: title, message: message, confirm: confirm, destructive: destructive)) return;
    await _run(() => _repository.changeStatus(t.id, next), success: next.label);
  }

  /// Sortea y sigue a la programación de los partidos.
  Future<void> _draw() async {
    final t = _t!;
    if (!await confirmAction(
      context,
      title: 'Sortear el cuadro',
      message: '${t.seeding == Seeding.ranking ? 'Los equipos con más puntos de ranking quedan como cabezas de serie. ' : 'El sorteo es al azar. '}'
          'El torneo pasa a "En juego" y se avisa a los jugadores. Después cargás los días de juego y turni reparte los partidos en las canchas.',
      confirm: 'Sortear',
    )) {
      return;
    }
    setState(() => _busy = true);
    final result = await _repository.draw(t.id);
    if (!mounted) return;
    setState(() => _busy = false);
    final drawn = await result.when(
      left: (failure) async {
        final code = failure.details is Map ? (failure.details as Map)['code'] : null;
        if (code == 'NOT_ENOUGH_TEAMS' && failure.message.contains('Podés sortear igual')) {
          if (await confirmAction(context, title: 'Faltan equipos', message: failure.message, confirm: 'Sortear igual')) {
            return _run(() => _repository.draw(t.id, force: true), success: 'Cuadro sorteado');
          }
          return false;
        }
        if (mounted) SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
        return false;
      },
      right: (updated) async {
        setState(() => _t = updated);
        SnackbarsFunctions.showSuccessSnackbar(context, 'Cuadro sorteado');
        return true;
      },
    );
    if (drawn && mounted) await _openSchedule();
  }

  Future<void> _openSchedule() async {
    await context.pushNamed(AppRoutes.TOURNAMENT_SCHEDULE_ROUTE.name, pathParameters: {'tournamentId': '${_t!.id}'});
    if (mounted) _load();
  }

  Future<void> _sendReminders() async {
    final t = _t!;
    if (!await confirmAction(
      context,
      title: 'Avisar pagos pendientes',
      message: 'Se manda un aviso a los equipos con pagos pendientes: cuántos pagos faltan y que si no completan, quedan fuera.',
      confirm: 'Enviar aviso',
    )) {
      return;
    }
    final result = await _repository.sendPaymentReminders(t.id);
    if (!mounted) return;
    result.when(
      left: (failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (sent) => SnackbarsFunctions.showSuccessSnackbar(context, sent == 0 ? 'No hay equipos con pagos pendientes' : 'Aviso enviado a $sent equipo${sent == 1 ? '' : 's'}'),
    );
  }

  // -- Equipos -----------------------------------------------------------------

  Future<void> _markPaid(TournamentEntry e, EntryPlayer p) async {
    if (!await confirmAction(
      context,
      title: 'Registrar pago en el club',
      message: '${p.shownName} pagó ${money(p.amountDue)} de la inscripción de ${e.teamName}.',
      confirm: 'Registrar pago',
    )) {
      return;
    }
    await _run(() => _repository.markPlayerPaid(_t!.id, e.id, p.id), success: 'Pago registrado');
  }

  Future<void> _drop(TournamentEntry e) async {
    final inProgress = _t!.status == TournamentStatus.inProgress;
    if (!await confirmAction(
      context,
      title: 'Dar de baja a ${e.teamName}',
      message: inProgress ? 'Sus partidos sin jugar los gana el rival sin jugar. Se avisa a los jugadores.' : 'El equipo queda fuera del torneo. Se avisa a los jugadores.',
      confirm: 'Dar de baja',
      destructive: true,
    )) {
      return;
    }
    await _run(() => _repository.dropEntry(_t!.id, e.id), success: '${e.teamName} quedó fuera');
  }

  Future<void> _copyLink(EntryPlayer p) async {
    await Clipboard.setData(ClipboardData(text: p.inviteUrl!));
    if (mounted) SnackbarsFunctions.showSuccessSnackbar(context, 'Link de ${p.displayName} copiado');
  }

  // -- Partidos ----------------------------------------------------------------

  Future<void> _matchActions(TournamentMatch m) async {
    final t = _t!;
    final canSchedule = _canEdit && t.status == TournamentStatus.inProgress && !m.isFinished;
    final canResult = _canResults && t.status == TournamentStatus.inProgress && m.hasBothTeams && m.status != MatchStatus.walkover;
    if (!canSchedule && !canResult) return;
    final action = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('${m.roundLabel} · ${m.teamA?.name ?? 'A definir'} vs. ${m.teamB?.name ?? 'A definir'}'),
        children: [
          if (canSchedule)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('schedule'),
              child: ListTile(leading: const Icon(Icons.event_outlined), title: Text(m.session == null ? 'Programar cancha y horario' : 'Cambiar cancha u horario')),
            ),
          if (canResult)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('result'),
              child: ListTile(
                leading: const Icon(Icons.scoreboard_outlined),
                title: Text(m.status == MatchStatus.disputed ? 'Resolver resultado' : m.isFinished ? 'Corregir resultado' : 'Cargar resultado'),
              ),
            ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'schedule') await _schedule(m);
    if (action == 'result') await _result(m);
  }

  Future<void> _schedule(TournamentMatch m) async {
    final choice = await showScheduleMatchDialog(context, _t!, m);
    if (choice == null || !mounted) return;
    setState(() => _busy = true);
    final result = await _repository.scheduleMatch(_t!.id, m.id, courtId: choice.courtId, start: choice.start, durationMinutes: choice.courtId == null ? null : choice.durationMinutes);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      left: (failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (_) {
        SnackbarsFunctions.showSuccessSnackbar(context, choice.courtId == null ? 'Partido desprogramado' : 'Partido programado');
        _load();
      },
    );
  }

  Future<void> _result(TournamentMatch m) async {
    final choice = await showMatchResultDialog(context, _t!, m);
    if (choice == null || !mounted) return;
    await _run(() => _repository.setMatchResult(_t!.id, m.id, sets: choice.sets, score: choice.score), success: 'Resultado confirmado');
  }

  // -- UI ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = _t;
    if (t == null) {
      return Scaffold(
        backgroundColor: scheme.surfaceContainer,
        appBar: AppBar(),
        body: _error != null ? LoadError(message: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator()),
      );
    }

    final hasMatches = t.matches.isNotEmpty;
    final tabs = <(String, Widget)>[
      ('Equipos · ${t.entries.where((e) => e.isActive).length}', _entriesTab(t)),
      if (hasMatches) (t.format == TournamentFormat.league ? 'Tabla' : 'Cuadro', _bracketTab(t)),
      if (hasMatches) ('Partidos', _matchesTab(t)),
    ];

    if (ResponsiveBuilder.isMobile(context)) return _mobileScaffold(t, tabs, hasMatches);

    return DefaultTabController(
      length: tabs.length,
      initialIndex: hasMatches ? 1 : 0,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainer,
        appBar: AppBar(
          title: Text(t.name),
          actions: [
            if (_busy) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ..._actions(t),
            const SizedBox(width: 16),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(124),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: _header(t)),
                Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 4), child: _stepper(t)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TabBar(isScrollable: true, tabs: [for (final (label, _) in tabs) Tab(text: label)]),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(children: [for (final (_, tab) in tabs) tab]),
      ),
    );
  }

  /// Celular: la barra superior lleva solo el nombre y el menú; estado,
  /// avance y la acción principal van debajo, a todo el ancho.
  Widget _mobileScaffold(Tournament t, List<(String, Widget)> tabs, bool hasMatches) {
    final scheme = Theme.of(context).colorScheme;
    final primary = _primaryActions(t).toList();
    return DefaultTabController(
      length: tabs.length,
      initialIndex: hasMatches ? 1 : 0,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainer,
        appBar: AppBar(
          titleSpacing: 0,
          title: Text(t.name, overflow: TextOverflow.ellipsis),
          actions: [
            if (_busy) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ..._menu(t),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: scheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(t),
                  const SizedBox(height: 12),
                  _mobileProgress(t),
                  if (primary.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: primary),
                  ],
                ],
              ),
            ),
            Material(
              color: scheme.surface,
              child: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [for (final (label, _) in tabs) Tab(text: label)]),
            ),
            Expanded(child: TabBarView(children: [for (final (_, tab) in tabs) tab])),
          ],
        ),
      ),
    );
  }

  /// Avance del torneo en una barra de pasos (el stepper de escritorio no
  /// entra a lo ancho del celular).
  Widget _mobileProgress(Tournament t) {
    final scheme = Theme.of(context).colorScheme;
    const steps = [TournamentStatus.draft, TournamentStatus.open, TournamentStatus.closed, TournamentStatus.inProgress, TournamentStatus.finished];
    final current = steps.indexOf(t.status);
    if (current < 0) return _stepper(t);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final (i, _) in steps.indexed) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= current ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Paso ${current + 1} de ${steps.length}'
          '${current + 1 < steps.length ? ' · sigue: ${steps[current + 1].label}' : ''}',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  List<Widget> _actions(Tournament t) => [
        for (final w in _primaryActions(t)) ...[w, const SizedBox(width: 8)],
        ..._menu(t),
      ];

  Iterable<Widget> _primaryActions(Tournament t) sync* {
    if (!_canEdit) return;
    switch (t.status) {
      case TournamentStatus.draft:
        yield FilledButton(onPressed: _busy ? null : () => _changeStatus(TournamentStatus.open), child: const Text('Publicar'));
      case TournamentStatus.open:
        yield FilledButton(onPressed: _busy ? null : () => _changeStatus(TournamentStatus.closed), child: const Text('Cerrar inscripción'));
      case TournamentStatus.closed:
        yield FilledButton.icon(onPressed: _busy ? null : _draw, icon: const Icon(Icons.shuffle), label: const Text('Sortear y programar partidos'));
      case TournamentStatus.inProgress:
        final unscheduled = t.matches.any((m) => m.session == null && !m.isFinished);
        yield unscheduled
            ? FilledButton.icon(onPressed: _busy ? null : _openSchedule, icon: const Icon(Icons.edit_calendar_outlined), label: const Text('Programar partidos'))
            : OutlinedButton.icon(onPressed: _busy ? null : _openSchedule, icon: const Icon(Icons.edit_calendar_outlined), label: const Text('Programación'));
      default:
        break;
    }
  }

  List<Widget> _menu(Tournament t) {
    if (!_canEdit) return const [];
    final hasPending = t.entries.any((e) => e.status == EntryStatus.pending);
    final options = <(String, VoidCallback)>[
      if (t.status != TournamentStatus.finished && t.status != TournamentStatus.cancelled)
        ('Editar datos', () async {
          await context.pushNamed(AppRoutes.TOURNAMENT_EDIT_ROUTE.name, pathParameters: {'tournamentId': '${t.id}'});
          _load();
        }),
      if ((t.status == TournamentStatus.closed || t.status == TournamentStatus.inProgress) && hasPending) ('Avisar pagos pendientes', _sendReminders),
      if (t.status == TournamentStatus.closed) ('Reabrir inscripción', () => _changeStatus(TournamentStatus.open)),
      if (t.status == TournamentStatus.open && t.teamsCount + t.waitlistCount == 0) ('Volver a borrador', () => _changeStatus(TournamentStatus.draft)),
      if (t.status == TournamentStatus.inProgress) ('Finalizar torneo', () => _changeStatus(TournamentStatus.finished)),
      if (t.status != TournamentStatus.finished && t.status != TournamentStatus.cancelled) ('Cancelar torneo', () => _changeStatus(TournamentStatus.cancelled)),
    ];
    if (options.isEmpty) return const [];
    return [
      PopupMenuButton<int>(
        tooltip: 'Más acciones',
        icon: const Icon(Icons.more_vert),
        onSelected: (i) => options[i].$2(),
        itemBuilder: (_) => [for (final (i, (label, _)) in options.indexed) PopupMenuItem(value: i, child: Text(label))],
      ),
    ];
  }

  Widget _header(Tournament t) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusBadge(label: t.status.label, tone: StatusTone.ofTournament(scheme, t.status)),
        Text(
          [
            t.modalityLabel,
            t.categoryLabel,
            t.format.label,
            datesRange(t.startsAt, t.endsAt),
            feeLabel(t),
            t.resultMode == ResultMode.consensus ? 'Resultado por consenso' : 'Resultados del club',
          ].join(' · '),
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _stepper(Tournament t) {
    final scheme = Theme.of(context).colorScheme;
    const steps = [TournamentStatus.draft, TournamentStatus.open, TournamentStatus.closed, TournamentStatus.inProgress, TournamentStatus.finished];
    final current = t.status == TournamentStatus.cancelled ? -1 : steps.indexOf(t.status);
    if (current < 0) {
      return Row(children: [Icon(Icons.cancel_outlined, size: 18, color: scheme.error), const SizedBox(width: 6), Text('Torneo cancelado', style: TextStyle(color: scheme.error))]);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, s) in steps.indexed) ...[
            if (i > 0) Container(width: 32, height: 2, color: i <= current ? scheme.primary : scheme.outlineVariant),
            const SizedBox(width: 6),
            Icon(
              i < current ? Icons.check_circle : (i == current ? Icons.radio_button_checked : Icons.radio_button_unchecked),
              size: 18,
              color: i <= current ? scheme.primary : scheme.outlineVariant,
            ),
            const SizedBox(width: 6),
            Text(
              s.label,
              style: TextStyle(fontSize: 13, fontWeight: i == current ? FontWeight.w700 : FontWeight.w400, color: i <= current ? scheme.onSurface : scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  // -- Pestaña Equipos -------------------------------------------------------------

  Widget _entriesTab(Tournament t) {
    final scheme = Theme.of(context).colorScheme;
    final s = t.closingSummary;
    final entries = [...t.entries]..sort((a, b) {
        int rank(TournamentEntry e) => e.isActive ? 0 : (e.status == EntryStatus.waitlist ? 1 : 2);
        return rank(a).compareTo(rank(b)) != 0 ? rank(a).compareTo(rank(b)) : (a.seed ?? 999).compareTo(b.seed ?? 999);
      });
    final showSummary = s != null && t.hasFee && (t.status == TournamentStatus.open || t.status == TournamentStatus.closed);

    return ListView(
      padding: EdgeInsets.all(ResponsiveBuilder.isMobile(context) ? 16 : 24),
      children: [
        if (showSummary) ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryCard('Inscriptos', '${s.entries}', 'cupo ${t.maxTeams}${s.waitlist > 0 ? ' · ${s.waitlist} en espera' : ''}', null),
              _summaryCard('Todo pago', '${s.fullyPaid}', 'entran', StatusTone.success(scheme).foreground),
              _summaryCard('Con el mínimo', '${s.meetsMinimum}', 'entran · reciben aviso final', StatusTone.warning(scheme).foreground),
              _summaryCard('Bajo el mínimo', '${s.belowMinimum}', t.status == TournamentStatus.open ? 'quedarían fuera al cerrar' : 'quedan fuera', scheme.error),
            ],
          ),
          const SizedBox(height: 16),
          if (!t.onlinePayments)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: InfoBanner(text: 'El club no tiene Mercado Pago vinculado: los jugadores no pueden pagar desde la app. Registrá los pagos en el club desde cada equipo.'),
            ),
        ],
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              t.status == TournamentStatus.draft ? 'Publicá el torneo para que los equipos se anoten desde la app.' : 'Todavía no se anotó ningún equipo.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          )
        else
          AdminDataTable(
            columns: [if (t.matches.isNotEmpty) 'Siembra' else '#', 'Equipo', 'Jugadores · categoría', 'Pagos', 'Estado', ''],
            columnWidths: const {0: FixedColumnWidth(80), 1: FlexColumnWidth(1.4), 2: FlexColumnWidth(2.4), 3: FlexColumnWidth(1.2), 4: FlexColumnWidth(1.3), 5: FixedColumnWidth(64)},
            rowTextColors: [for (final e in entries) e.isActive || e.status == EntryStatus.waitlist ? null : scheme.onSurfaceVariant],
            rows: [
              for (final (i, e) in entries.indexed)
                [
                  Text(e.seed != null ? '${e.seed}${e.groupLabel != null ? ' · Zona ${e.groupLabel}' : ''}' : '${i + 1}'),
                  Text(e.teamName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final p in e.players)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(p.shownName),
                              if (p.isCaptain) Text('(capitán)', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                              if (!p.joined) Text('· falta unirse', style: TextStyle(fontSize: 12, color: StatusTone.warning(scheme).foreground)),
                              if (p.category != null)
                                StatusBadge(label: '${p.category!.name}${p.category!.isClub ? '' : ' (personal)'}', tone: p.category!.isClub ? StatusTone.success(scheme) : StatusTone.neutral(scheme)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  t.hasFee
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${e.paidPlayers} / ${e.players.length}', style: TextStyle(fontWeight: FontWeight.w500, color: e.paidPlayers == e.players.length ? StatusTone.success(scheme).foreground : StatusTone.warning(scheme).foreground)),
                            if (e.amountDue > 0) Text('debe ${money(e.amountDue)}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                          ],
                        )
                      : const Text('Sin cargo'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(
                      label: e.status == EntryStatus.pending && t.status == TournamentStatus.open && !e.meetsMinPayments ? 'Bajo el mínimo' : e.status.label,
                      tone: StatusTone.ofEntry(scheme, e.status),
                    ),
                  ),
                  _entryMenu(t, e),
                ],
            ],
          ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, String caption, Color? color) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 28, color: color ?? scheme.onSurface)),
              Text(caption, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entryMenu(Tournament t, TournamentEntry e) {
    if (!_canEdit || t.status == TournamentStatus.finished || t.status == TournamentStatus.cancelled) return const SizedBox.shrink();
    final options = <(String, VoidCallback)>[
      if (t.hasFee && e.status != EntryStatus.out && e.status != EntryStatus.withdrawn)
        for (final p in e.players.where((p) => !p.paid)) ('Registrar pago de ${p.shownName} (${money(p.amountDue)})', () => _markPaid(e, p)),
      for (final p in e.players.where((p) => !p.joined && p.inviteUrl != null)) ('Copiar link de ${p.displayName}', () => _copyLink(p)),
      if (e.status != EntryStatus.out && e.status != EntryStatus.withdrawn) ('Dar de baja', () => _drop(e)),
    ];
    if (options.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<int>(
      tooltip: 'Acciones',
      icon: const Icon(Icons.more_vert),
      onSelected: (i) => options[i].$2(),
      itemBuilder: (_) => [for (final (i, (label, _)) in options.indexed) PopupMenuItem(value: i, child: Text(label))],
    );
  }

  // -- Pestaña Cuadro ----------------------------------------------------------

  Widget _bracketTab(Tournament t) {
    final text = Theme.of(context).textTheme;
    final groups = t.standings.where((g) => g.label != null).toList();
    final league = t.standings.where((g) => g.label == null).toList();
    final hasKnockout = t.matches.any((m) => m.isKnockout);
    final disputed = t.matches.where((m) => m.status == MatchStatus.disputed).toList();

    return ListView(
      padding: EdgeInsets.all(ResponsiveBuilder.isMobile(context) ? 16 : 24),
      children: [
        for (final m in disputed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InfoBanner(
              error: true,
              icon: Icons.report_outlined,
              text: 'En disputa · ${m.roundLabel}: ${m.teamA?.name} vs. ${m.teamB?.name}. Los capitanes cargaron resultados distintos.',
              action: _canResults ? FilledButton.tonal(onPressed: () => _result(m), child: const Text('Resolver')) : null,
            ),
          ),
        if (groups.isNotEmpty) ...[
          Text('Zonas', style: text.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final g in groups) SizedBox(width: 560, child: StandingsTable(group: g, scoreMode: t.scoreMode, qualifiers: t.qualifiersPerGroup)),
            ],
          ),
          const SizedBox(height: 24),
        ],
        for (final g in league) ...[
          StandingsTable(group: g, scoreMode: t.scoreMode),
          const SizedBox(height: 24),
        ],
        if (hasKnockout) ...[
          Text('Llave', style: text.titleMedium),
          const SizedBox(height: 12),
          BracketView(matches: t.matches, onMatchTap: _matchActions),
        ] else if (t.format == TournamentFormat.groupsKnockout)
          const InfoBanner(text: 'La llave se arma sola cuando terminan todos los partidos de las zonas.'),
      ],
    );
  }

  // -- Pestaña Partidos ------------------------------------------------------

  Widget _matchesTab(Tournament t) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final sections = <String, List<TournamentMatch>>{};
    for (final m in t.matches) {
      final key = m.isKnockout ? m.roundLabel : '${m.groupLabel != null ? 'Zona ${m.groupLabel} · ' : ''}Fecha ${m.round}';
      sections.putIfAbsent(key, () => []).add(m);
    }
    final unscheduled = t.matches.where((m) => m.session == null && !m.isFinished && m.hasBothTeams).length;

    return ListView(
      padding: EdgeInsets.all(ResponsiveBuilder.isMobile(context) ? 16 : 24),
      children: [
        if (unscheduled > 0 && _canEdit && t.status == TournamentStatus.inProgress)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InfoBanner(
              icon: Icons.event_busy_outlined,
              text: '$unscheduled partido${unscheduled == 1 ? '' : 's'} sin cancha ni horario. Programalos todos juntos con los días de juego, o tocá cada uno.',
              action: FilledButton.tonal(onPressed: _openSchedule, child: const Text('Programar')),
            ),
          ),
        for (final entry in sections.entries) ...[
          Text(entry.key, style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [for (final m in entry.value) MatchCard(match: m, width: 300, onTap: () => _matchActions(m))],
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
