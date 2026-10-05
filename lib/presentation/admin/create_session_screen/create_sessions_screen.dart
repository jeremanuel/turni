import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart' hide Aligned;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/chips/filter_chip_interval_date.dart';
import '../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../core/utils/physical_partition_naming.dart';
import '../../../core/utils/types/time_interval.dart';
import '../../../domain/entities/club_partition.dart';
import '../../../domain/entities/create_sessions_result.dart';
import '../../../domain/entities/physical_partition.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/use_case/price/session_price_resolver.dart';
import '../../../domain/use_case/session_template/generate_preset_sessions_use_case.dart';
import '../../core/agenda/agenda.dart';
import '../club_config/club_config_focus.dart';
import '../club_config/widgets/inactive_partition_hint.dart';
import '../session_manager_screen/bloc/session_manager_bloc.dart';
import '../session_manager_screen/bloc/session_manager_event.dart';
import '../session_manager_screen/bloc/session_manager_state.dart';
import 'bloc/create_sesssions_form_bloc.dart';
import 'bloc/date_preset.dart';

import 'widgets/agenda_edit_card.dart';
import 'widgets/court_session_price.dart';
import 'widgets/rework_styles.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key, this.showBackButton = true});

  /// false cuando vive como tab de Gestión masiva, que ya tiene su propio
  /// "volver" en la franja de arriba.
  final bool showBackButton;

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  int _currentStep = 0;
  int? _selectedMorningDuration;
  int? _selectedAfternoonDuration;
  final GeneratePresetSessionsUseCase _generatePresetSessionsUseCase =
      GeneratePresetSessionsUseCase();

  /// El turno recién creado clickeando un espacio libre — paso "Horarios" —
  /// para que su card abra el popover de edición sola, sin un botón "+".
  Session? _pendingAutoOpenTemplateSession;

  /// Lo mismo, pero para el turno (de plantilla o extra) recién creado en
  /// una cancha puntual del paso "Canchas".
  Session? _pendingAutoOpenCourtSession;

  static const int _customDurationOption = -1;

  static const _steps = [
    _WizardStep(label: 'Horarios', title: 'Horarios', subtitle: 'Definí los bloques base que se van a repetir cada día.'),
    _WizardStep(label: 'Canchas', title: 'Modalidades y canchas', subtitle: 'Elegí dónde se van a crear los turnos.'),
    _WizardStep(label: 'Fechas', title: 'Rango de fechas', subtitle: 'Elegí el período en el que se repite la plantilla.'),
    _WizardStep(label: 'Confirmar', title: 'Confirmación', subtitle: 'Revisá el total antes de crear los turnos.'),
  ];

  static const int _firstWizardStep = 0;

  @override
  void dispose() {
    sl.resetLazySingleton<CreateSesssionsFormBloc>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formBloc = sl<CreateSesssionsFormBloc>();

    // Si los sectores/canchas cambian (ej. se reactivó o dio de baja uno desde
    // la configuración abierta en el medio del wizard), la selección se
    // actualiza con las versiones frescas y descarta lo que quedó inactivo.
    return BlocListener<SessionManagerBloc, SessionManagerState>(
      listenWhen: (previous, current) =>
          previous.clubPartitions != current.clubPartitions,
      listener: (context, managerState) =>
          formBloc.add(SyncClubPartitions(managerState.clubPartitions)),
      child: Portal(
      child: BlocBuilder<CreateSesssionsFormBloc, CreateSesssionsFormState>(
        bloc: formBloc,
        builder: (context, state) {
          // "Creando turnos" y el resultado se renderizan como overlays DENTRO
          // de este mismo widget (no con showDialog) para que no puedan
          // quedar huérfanos: un showDialog queda pusheado en el Navigator
          // de arriba y go_router no lo saca al navegar afuera de esta
          // pantalla (ej. "Volver a gestor de turnos", o el botón atrás del
          // navegador) — quedaba la tilde de "Creando turnos" trabada en
          // pantalla. Al ser parte del árbol de este widget, desaparecen
          // solos en cuanto esta pantalla se desmonta, sea como sea que se
          // haya salido de ella.
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(RW.cardRadius),
                child: Container(
                  color: RW.card,
                  child: Column(
                    children: [
                      if (widget.showBackButton) _buildTopBar(context),
                      _StepTrackerBar(
                        steps: _steps,
                        currentStep: _currentStep,
                        maxReachable: _maxReachableStep(state),
                        onStepTap: (index) => setState(() => _currentStep = index),
                      ),
                      const Divider(height: 1, color: RW.divider),
                      Expanded(child: _buildWorkArea(context, state)),
                    ],
                  ),
                ),
              ),
              if (state.isSubmitting) Positioned.fill(child: _buildSavingOverlay()),
              if (!state.isSubmitting && state.savedSessions)
                Positioned.fill(child: _buildResultOverlay(context, state)),
            ],
          );
        },
      ),
      ),
    );
  }

  /// Abre la configuración apuntando a [focus] (encima del wizard, sin
  /// perder lo cargado) y al cerrarla recarga sectores/canchas y tarifas,
  /// para que el admin vea reflejado lo que haya cambiado.
  Future<void> _openConfig(ClubConfigFocus focus) async {
    await openClubConfig(context, focus);
    if (!mounted) return;
    _reloadAfterConfig();
  }

  void _reloadAfterConfig() {
    context.read<SessionManagerBloc>().add(ReloadClubPartitionsEvent());
    sl<CreateSesssionsFormBloc>().add(const ReloadTariffs());
  }

  void _handleBackToCalendar(BuildContext context) {
    context.read<SessionManagerBloc>().add(
      SessionManagerEvent.reloadSessionsEvent(),
    );
    context.go(AppRoutes.SESSION_MANAGER_ROUTE.path);
  }

  void _handleCreateMore() {
    sl<CreateSesssionsFormBloc>().add(const ResetForm());
    setState(() {
      _currentStep = _firstWizardStep;
      _selectedMorningDuration = null;
      _selectedAfternoonDuration = null;
    });
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.SESSION_MANAGER_ROUTE.path),
          style: OutlinedButton.styleFrom(
            foregroundColor: RW.onSurfaceVariant,
            side: const BorderSide(color: RW.outlineVariant),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RW.buttonRadius)),
            textStyle: RW.tStepLabel,
          ),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Volver a gestor de turnos'),
        ),
      ),
    );
  }

  Widget _buildWorkArea(BuildContext context, CreateSesssionsFormState state) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1000;

    final left = _buildSessionsPreviewPanel(context, state);
    final right = _buildWizardPanel(context, state);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: left),
                const SizedBox(width: 20),
                SizedBox(width: RW.rightPanelWidth, child: right),
              ],
            )
          : Column(
              children: [
                Expanded(child: left),
                const SizedBox(height: 16),
                SizedBox(height: 420, child: right),
              ],
            ),
    );
  }

  int _maxReachableStep(CreateSesssionsFormState state) {
    var max = 0;
    if (state.sessions.isNotEmpty) max = 1;
    if (max >= 1 && state.selectedPhysicalPartitions.isNotEmpty) max = 2;
    if (max >= 2 && state.interval?.initialDate != null) max = 3;
    return max;
  }

  Widget _buildWizardPanel(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    final current = _steps[_currentStep];
    return Container(
      decoration: BoxDecoration(
        color: RW.panel,
        borderRadius: BorderRadius.circular(RW.panelRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RW.surfaceHigh)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(current.title, style: RW.tPanelTitle),
                const SizedBox(height: 4),
                Text(current.subtitle, style: RW.tPanelSubtitle),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildStepContent(context, state),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: RW.surfaceHigh)),
            ),
            child: Row(
              children: [
                _RWOutlinedButton(
                  label: 'Atrás',
                  icon: Icons.arrow_back,
                  onPressed: _currentStep == 0 || state.isSubmitting
                      ? null
                      : () => setState(() {
                          _currentStep -= 1;
                        }),
                ),
                const SizedBox(width: 12),
                if (_currentStep < _steps.length - 1)
                  Expanded(
                    child: _RWFilledButton(
                      label: 'Continuar',
                      icon: Icons.arrow_forward,
                      onPressed: () => _onContinuePressed(context, state),
                    ),
                  ),
                if (_currentStep == _steps.length - 1)
                  Expanded(
                    child: _RWFilledButton(
                      label: state.isSubmitting ? 'Creando turnos...' : 'Crear turnos',
                      icon: state.isSubmitting ? null : Icons.check_circle_outline,
                      loading: state.isSubmitting,
                      onPressed: _isReadyToCreate(state) && !state.isSubmitting
                          ? () => sl<CreateSesssionsFormBloc>().add(
                              const CreateSessions(),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildTemplateStep(context, state);
      case 1:
        return _buildLocationsStep(context, state);
      case 2:
        return _buildDateRangeStep(context, state);
      case 3:
        return _buildReviewStep(context, state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTemplateStep(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    final hasSessions = state.sessions.isNotEmpty;

    return ListView(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasSessions ? RW.primaryContainer.withValues(alpha: 0.3) : RW.surfaceHigh,
            borderRadius: BorderRadius.circular(RW.columnRadius),
            border: Border.all(color: hasSessions ? RW.primaryContainer : RW.outlineVariant),
          ),
          child: Row(
            children: [
              Text(
                hasSessions ? '✓' : 'ⓘ',
                style: TextStyle(fontSize: 16, color: hasSessions ? RW.primary : RW.muted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasSessions
                      ? '${state.sessions.length} horario(s) cargados en la plantilla.'
                      : 'Todavía no hay horarios en la plantilla.',
                  style: RW.tBody,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Carga rápida por franja', style: RW.tLabel),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetFillChip(
              context,
              title: 'Completar mañana',
              start: const TimeOfDay(hour: 8, minute: 30),
              end: const TimeOfDay(hour: 13, minute: 0),
              label: 'mañana',
              dotColor: RW.accent90min,
              selectedDuration: _selectedMorningDuration,
              onDurationSelected: (value) {
                setState(() {
                  _selectedMorningDuration = value;
                });
              },
            ),
            _buildPresetFillChip(
              context,
              title: 'Completar tarde',
              start: const TimeOfDay(hour: 14, minute: 0),
              end: const TimeOfDay(hour: 22, minute: 30),
              label: 'tarde',
              dotColor: RW.accent60min,
              selectedDuration: _selectedAfternoonDuration,
              onDurationSelected: (value) {
                setState(() {
                  _selectedAfternoonDuration = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'El timeline de la izquierda es editable: clic en una hora libre agrega un turno de 60 min ahí mismo, clic en un turno lo edita o lo borra.',
          style: RW.tSmall,
        ),
      ],
    );
  }

  Widget _buildLocationsStep(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    final clubPartitions = context
        .read<SessionManagerBloc>()
        .state
        .clubPartitions;
    final formBloc = sl<CreateSesssionsFormBloc>();
    final physicalPartitions = state.selectedClubPartitions
        .expand(
          (element) =>
              element.physicalPartitions ?? const <PhysicalPartition>[],
        )
        .fold<Map<int, PhysicalPartition>>(<int, PhysicalPartition>{}, (
          acc,
          item,
        ) {
          acc[item.partitionPhysicalId] = item;
          return acc;
        })
        .values
        .toList();
    final defaultClubPartition = state.selectedClubPartitions.isNotEmpty
        ? state.selectedClubPartitions.first
        : (clubPartitions.isNotEmpty ? clubPartitions.first : null);
    final pluralPartitionLabel = PhysicalPartitionNaming.pluralFromClubPartition(
      defaultClubPartition,
    );
    final singularPartitionLabel =
        PhysicalPartitionNaming.singularFromClubPartition(defaultClubPartition);

    return ListView(
      children: [
        Text('Modalidades', style: RW.tLabel),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: clubPartitions
              .map(
                (partition) => InactivePartitionHint(
                  inactive: !partition.active,
                  message: InactivePartitionHint.clubPartitionMessage,
                  focus: ClubConfigFocus.clubPartition(partition.club_partition_id ?? 0),
                  onConfigClosed: _reloadAfterConfig,
                  child: _RWChip(
                    enabled: partition.active,
                    selected: state.selectedClubPartitions.contains(partition),
                    label: partition.clubType?.name ?? 'Modalidad',
                    onSelected: (value) => formBloc.add(
                      ChangeSelectionClubPartition(partition, value),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        Text(pluralPartitionLabel, style: RW.tLabel),
        const SizedBox(height: 10),
        if (physicalPartitions.isEmpty)
          Text(
            'Seleccioná al menos una modalidad para habilitar ${pluralPartitionLabel.toLowerCase()}.',
            style: RW.tSmall,
          ),
        if (physicalPartitions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: physicalPartitions
                .map(
                  (physicalPartition) => InactivePartitionHint(
                    key: ValueKey(physicalPartition.partitionPhysicalId),
                    inactive: !physicalPartition.active,
                    message: InactivePartitionHint.physicalPartitionMessage,
                    focus: ClubConfigFocus.physicalPartition(
                      clubPartitionId: physicalPartition.clubPartitionId,
                      partitionPhysicalId: physicalPartition.partitionPhysicalId,
                    ),
                    onConfigClosed: _reloadAfterConfig,
                    child: _RWChip(
                    enabled: physicalPartition.active,
                    selected: state.selectedPhysicalPartitions.contains(
                      physicalPartition,
                    ),
                    label: PhysicalPartitionNaming.labelFromIdentifier(
                      physicalIdentifier: physicalPartition.physicalIdentifier,
                      partitionPhysicalId:
                          physicalPartition.partitionPhysicalId,
                      clubPartition: _resolveClubPartitionForPhysicalPartition(
                            state.selectedClubPartitions,
                            physicalPartition.partitionPhysicalId,
                          ) ??
                          defaultClubPartition,
                    ),
                    helper: physicalPartition.minPlayers > 0
                        ? '${physicalPartition.minPlayers}–${physicalPartition.maxPlayers ?? physicalPartition.minPlayers} jug.'
                        : null,
                    onSelected: (value) => formBloc.add(
                      ChangeSelectionPhysicalPartition(
                        physicalPartition,
                        value,
                      ),
                    ),
                  ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 18),
        Text(
          'Seleccionadas: ${state.selectedPhysicalPartitions.length} ${state.selectedPhysicalPartitions.length == 1 ? singularPartitionLabel.toLowerCase() : pluralPartitionLabel.toLowerCase()}',
          style: RW.tSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'La plantilla repetida en cada cancha — ajustá cada una por separado en la vista previa: clic en una hora libre de esa columna agrega un turno solo ahí, clic en la × lo quita solo de esa cancha.',
          style: RW.tSmall,
        ),
      ],
    );
  }

  Widget _buildDateRangeStep(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    return ListView(
      children: [
        for (final preset in DatePreset.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RWSelectableTile(
              label: preset.label,
              selected: state.datePreset == preset,
              onTap: () => sl<CreateSesssionsFormBloc>().add(
                ChangeDatePreset(preset),
              ),
            ),
          ),
        if (state.datePreset == DatePreset.custom) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: RW.surface,
              borderRadius: BorderRadius.circular(RW.surfaceRadius),
              border: Border.all(color: RW.outlineVariant),
            ),
            child: Wrap(
              children: [
                FilterChipIntervalDate(
                  initialValue: state.interval,
                  label: 'Rango personalizado',
                  onApply: (interval) => sl<CreateSesssionsFormBloc>().add(
                    ChangeSelectionInitialDate(interval),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewStep(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    final templateCount = state.sessions.length;
    final partitionsCount = state.selectedPhysicalPartitions.length;

    return ListView(
      children: [
        _SummaryTile(
          title: 'Horarios plantilla',
          value: '$templateCount',
        ),
        const SizedBox(height: 10),
        _SummaryTile(
          title:
              '${PhysicalPartitionNaming.pluralFromClubPartition(_defaultClubPartitionFromState(context, state))} seleccionadas',
          value: '$partitionsCount',
        ),
        const SizedBox(height: 10),
        _SummaryTile(
          title: 'Rango de carga',
          value: state.datePreset.label,
        ),
        const SizedBox(height: 16),
        Text(
          'Podés volver atrás para ajustar cualquier paso antes de confirmar.',
          style: RW.tSmall,
        ),
      ],
    );
  }

  int? _daysCount(CreateSesssionsFormState state) {
    final initialDate = state.interval?.initialDate;
    final endDate = state.interval?.endDate;
    if (initialDate == null) return null;
    if (endDate == null) return 1;
    return endDate.difference(initialDate).inDays + 1;
  }

  Widget _buildSessionsPreviewPanel(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPreviewHeader(state),
        const SizedBox(height: 14),
        Expanded(child: _buildPreviewBody(context, state)),
      ],
    );
  }

  Widget _buildPreviewHeader(CreateSesssionsFormState state) {
    switch (_currentStep) {
      case 0:
        return const _PreviewHeader(
          title: 'Plantilla del día',
          subtitle: 'Hacé clic en una hora libre para agregar un turno. Hacé clic en un turno para editarlo.',
          legend: [
            _LegendDot(color: RW.accent30min, label: '30 min'),
            _LegendDot(color: RW.accent60min, label: '60 min'),
            _LegendDot(color: RW.accent90min, label: '90+ min'),
          ],
        );
      case 1:
        return _PreviewHeader(
          title: 'Cómo se reparte entre canchas',
          subtitle: 'La plantilla repetida en cada cancha — clic en una hora libre de esa columna agrega un turno solo ahí. '
              'Cada turno muestra su precio según la tarifa por horario de la cancha; clic en el turno para ver qué regla aplica o cambiarlo a mano.',
          legend: const [
            _LegendDot(color: RW.accent60min, label: 'de la plantilla'),
            _LegendDot(color: RW.accentExtra, label: 'agregado en esta cancha'),
            _LegendIcon(icon: Icons.sell_outlined, label: 'tarifa por horario'),
            _LegendIcon(icon: Icons.sports_tennis_outlined, label: 'precio base'),
            _LegendIcon(icon: Icons.edit_outlined, label: 'precio manual'),
          ],
          trailing: PriceDayOfWeekSelector(
            selected: state.priceDayOfWeek,
            loading: state.isLoadingTariffs,
            onChanged: (day) =>
                sl<CreateSesssionsFormBloc>().add(ChangePriceDayOfWeek(day)),
          ),
        );
      case 2:
        return const _PreviewHeader(
          title: 'Días que incluye la carga',
          subtitle: 'La plantilla se va a repetir en cada uno de estos días.',
        );
      default:
        return const _PreviewHeader(
          title: 'Muestra de lo que se va a crear',
          subtitle: 'Revisá antes de confirmar — podés volver a cualquier paso.',
        );
    }
  }

  Widget _buildPreviewBody(BuildContext context, CreateSesssionsFormState state) {
    switch (_currentStep) {
      case 0:
        return _buildTemplatePreview(state);
      case 1:
        return _buildCourtsPreview(state);
      case 2:
        return _buildDaysPreview(state);
      default:
        return _buildConfirmationPreview(state);
    }
  }

  Widget _buildTemplatePreview(CreateSesssionsFormState state) {
    final today = DateTime.now();

    return _RWSurfaceBox(
      child: Agenda(heightPerMinute: 1,
        sessions: state.sessions,
        buildCard: (session, physicalPartition, height) {
          final autoOpen = _pendingAutoOpenTemplateSession == session;
          return AgendaEditCard(
            session: session,
            height: height,
            autoOpen: autoOpen,
            onAutoOpened: autoOpen
                ? () => setState(() => _pendingAutoOpenTemplateSession = null)
                : null,
          );
        },
        partitionLabelBuilder: (physicalPartition) =>
            PhysicalPartitionNaming.labelFromPhysicalPartition(
          physicalPartition,
        ),
        physicalPartitions: [
          PhysicalPartition(
            partitionPhysicalId: 1,
            clubPartitionId: 1,
            minPlayers: 1,
            maxPlayers: 1,
            physicalIdentifier: 1,
            isCover: 'true',
            description: '',
            // No-null: habilita el hover/click sobre huecos libres para
            // agregar un turno ahí mismo (reemplaza al botón "+").
            durationInMinutes: 60,
          ),
        ],
        fromDate: today.applied(TimeOfDay(hour: RW.firstHour, minute: 0)),
        lastDate: today.applied(TimeOfDay(hour: RW.lastHour, minute: 0)),
        onBlankSpaceTap: (partition, interval) {
          final startTime = interval.initialDate!;
          final newSession = Session.fromDates(
            DateTime(startTime.year, startTime.month, startTime.day, startTime.hour, 0),
            const TimeOfDay(hour: 1, minute: 0),
          );
          setState(() => _pendingAutoOpenTemplateSession = newSession);
          sl<CreateSesssionsFormBloc>().add(AddSession(newSession));
        },
      ),
    );
  }

  Widget _buildCourtsPreview(CreateSesssionsFormState state) {
    if (state.selectedPhysicalPartitions.isEmpty) {
      return _RWEmptyBox(message: 'Seleccioná al menos una cancha para previsualizarla aquí.');
    }

    final today = DateTime.now();
    final resolver = state.priceResolver;
    final previewSessions = <Session>[];
    final meta = <Session, ({Session original, bool isExtra})>{};

    for (final p in state.selectedPhysicalPartitions) {
      final removed = state.courtRemovedSessions[p.partitionPhysicalId] ?? const <Session>[];
      for (final s in state.sessions) {
        if (removed.contains(s)) continue;
        final preview = _toPreviewSession(s, p, today);
        previewSessions.add(preview);
        meta[preview] = (original: s, isExtra: false);
      }
      for (final s in state.courtExtraSessions[p.partitionPhysicalId] ?? const <Session>[]) {
        final preview = _toPreviewSession(s, p, today);
        previewSessions.add(preview);
        meta[preview] = (original: s, isExtra: true);
      }
    }

    return Column(
      children: [
        Expanded(
          child: _RWSurfaceBox(
            child: Agenda(
              heightPerMinute: 1,
              sessions: previewSessions,
              physicalPartitions: state.selectedPhysicalPartitions,
              columnWidth: RW.courtColumnWidth + 50,
              partitionLabelBuilder: (p) => _courtColumnLabel(state, p),
              fromDate: today.applied(TimeOfDay(hour: RW.firstHour, minute: 0)),
              lastDate: today.applied(TimeOfDay(hour: RW.lastHour, minute: 0)),
              onBlankSpaceTap: (partition, interval) {
                final startTime = interval.initialDate!;
                final newSession = Session.fromDates(
                  DateTime(today.year, today.month, today.day, startTime.hour, 0),
                  const TimeOfDay(hour: 1, minute: 0),
                ).copyWith(partitionPhysicalId: partition.partitionPhysicalId);
                setState(() {
                  _pendingAutoOpenCourtSession =
                      _toPreviewSession(newSession, partition, today);
                });
                sl<CreateSesssionsFormBloc>().add(
                  AddExtraSessionToPartition(partition.partitionPhysicalId, newSession),
                );
              },
              buildCard: (session, partition, height) {
                final info = meta[session];
                final isExtra = info?.isExtra ?? false;
                final autoOpen = _pendingAutoOpenCourtSession == session;
                final original = info?.original ?? session;
                final startMinutes =
                    original.startTime.hour * 60 + original.startTime.minute;
                return _CourtSessionEditCard(
                  previewSession: session,
                  original: original,
                  isExtra: isExtra,
                  partition: partition,
                  height: height,
                  dayOfWeek: state.priceDayOfWeek,
                  resolvedPrice: state.resolvePrice(partition, original, resolver: resolver),
                  weekPrices: resolver.pricesByDayOfWeek(
                    partition: partition,
                    startMinutes: startMinutes,
                    manualPrice: state.manualPriceFor(partition.partitionPhysicalId, original),
                  ),
                  onOpenConfig: _openConfig,
                  autoOpen: autoOpen,
                  onAutoOpened: autoOpen
                      ? () => setState(() => _pendingAutoOpenCourtSession = null)
                      : null,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildCourtsTotalsFooter(state),
      ],
    );
  }

  /// Fila de totales por columna, debajo de la grilla del paso "Canchas" —
  /// cantidad de turnos y subtotal de esa cancha para el día elegido (cada
  /// turno con su precio resuelto por tarifa), alineada con cada columna
  /// (64px de hueco a la izquierda, igual que el ancho reservado por Agenda
  /// para la columna de horarios).
  Widget _buildCourtsTotalsFooter(CreateSesssionsFormState state) {
    final resolver = state.priceResolver;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 64),
          for (final p in state.selectedPhysicalPartitions)
            SizedBox(
              width: RW.courtColumnWidth + 50,
              child: Builder(builder: (context) {
                final effective =
                    state.effectiveSessionsForPartition(p.partitionPhysicalId);
                return _CourtTotalSummary(
                  total: effective.fold<double>(
                    0,
                    (sum, s) => sum + state.resolvePrice(p, s, resolver: resolver).price,
                  ),
                  sessionsCount: effective.length,
                  dayLabel: priceDayShortNames[state.priceDayOfWeek - 1],
                );
              }),
            ),
        ],
      ),
    );
  }

  /// Label de columna para el preview de "Canchas" — antepone la modalidad
  /// (ej. "Pádel") a la cancha ("cancha 1") para distinguir columnas cuando
  /// hay varias modalidades seleccionadas a la vez, ej. "Pádel cancha 1".
  String _courtColumnLabel(CreateSesssionsFormState state, PhysicalPartition p) {
    final clubPartition = _resolveClubPartitionForPhysicalPartition(
      state.selectedClubPartitions,
      p.partitionPhysicalId,
    );
    final unitLabel = PhysicalPartitionNaming.labelFromIdentifier(
      physicalIdentifier: p.physicalIdentifier,
      partitionPhysicalId: p.partitionPhysicalId,
      clubPartition: clubPartition,
    );
    final modality = clubPartition?.clubType?.name;
    if (modality == null || modality.isEmpty) return unitLabel;
    return '$modality ${unitLabel.toLowerCase()}';
  }

  Session _toPreviewSession(Session s, PhysicalPartition p, DateTime today) {
    // El precio NO va en la sesión de preview: lo resuelve la card con las
    // tarifas (ver _CourtSessionEditCard.resolvedPrice).
    return s.copyWith(
      partitionPhysicalId: p.partitionPhysicalId,
      startTime: DateTime(today.year, today.month, today.day, s.startTime.hour, s.startTime.minute),
    );
  }

  Widget _buildDaysPreview(CreateSesssionsFormState state) {
    if (state.datePreset == DatePreset.custom && state.interval?.initialDate == null) {
      return _RWEmptyBox(message: 'Elegí fechas específicas desde "Rango personalizado", a la derecha.');
    }

    final dates = state.interval?.generateDateRange() ?? const <DateTime>[];
    final daysCount = dates.length;
    final preview = dates.take(14).toList();
    final extra = daysCount - preview.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: RW.surface,
              borderRadius: BorderRadius.circular(RW.surfaceRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$daysCount día(s)', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: RW.primary)),
                const SizedBox(height: 2),
                Text('van a tener esta plantilla cargada', style: RW.tSubtitle),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in preview)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: RW.surfaceHigh,
                    borderRadius: BorderRadius.circular(RW.chipRadius),
                    border: Border.all(color: RW.primaryContainer),
                  ),
                  child: Text(DateFormat('EEE dd/MM', 'es').format(d), style: const TextStyle(fontSize: 12, color: RW.onPrimaryContainer)),
                ),
              if (extra > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: RW.panel,
                    borderRadius: BorderRadius.circular(RW.chipRadius),
                  ),
                  child: Text('+$extra más', style: RW.tSubtitle),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationPreview(CreateSesssionsFormState state) {
    final daysCount = _daysCount(state);
    final perDayTotal = state.selectedPhysicalPartitions.fold<int>(
      0,
      (sum, p) => sum + state.effectiveSessionsForPartition(p.partitionPhysicalId).length,
    );
    final canEstimate = perDayTotal > 0 && daysCount != null && daysCount > 0;
    final total = canEstimate ? perDayTotal * daysCount : null;

    final dayLabels = state.interval?.generateDateRange() ?? const <DateTime>[];
    final sampleDays = dayLabels.take(3).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: canEstimate ? RW.primaryContainer.withValues(alpha: 0.35) : RW.surface,
              borderRadius: BorderRadius.circular(RW.surfaceRadius),
              border: Border.all(color: canEstimate ? RW.primaryContainer : RW.surfaceHigh),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: canEstimate ? RW.primaryContainer : RW.panel,
                    borderRadius: BorderRadius.circular(RW.columnRadius),
                  ),
                  child: Icon(Icons.layers_outlined, color: canEstimate ? RW.onPrimaryContainer : RW.mutedMore),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total de turnos a crear', style: RW.tBody),
                      const SizedBox(height: 2),
                      if (canEstimate)
                        Text('$total turnos', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: RW.onPrimaryContainer))
                      else
                        Text('Completá los pasos anteriores para ver el estimado.', style: RW.tSmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (sampleDays.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final day in sampleDays)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: RW.surface,
                  borderRadius: BorderRadius.circular(RW.columnRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('EEE dd/MM', 'es').format(day)} — $perDayTotal turno(s) en ${state.selectedPhysicalPartitions.length} cancha(s)',
                      style: RW.tLabel,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.sessions.map((s) => DateFormat.Hm().format(s.startTime)).join(' · '),
                      style: RW.tSmall,
                    ),
                  ],
                ),
              ),
            if (dayLabels.length > sampleDays.length)
              Text('y ${dayLabels.length - sampleDays.length} día(s) más con la misma plantilla…', style: RW.tSmall),
          ],
        ],
      ),
    );
  }

  void _onContinuePressed(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    final currentValidationMessage = _validateCurrentStep(context, state);

    if (currentValidationMessage != null) {
      SnackbarsFunctions.showErrorsSnackbar(context, currentValidationMessage);
      return;
    }

    setState(() {
      _currentStep += 1;
    });
  }

  String? _validateCurrentStep(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    if (_currentStep == 0 && state.sessions.isEmpty) {
      return 'Agrega al menos un horario para continuar.';
    }

    if (_currentStep == 1 && state.selectedPhysicalPartitions.isEmpty) {
      final singularPartitionLabel = PhysicalPartitionNaming
          .singularFromClubPartition(_defaultClubPartitionFromState(context, state))
          .toLowerCase();
      return 'Selecciona al menos una $singularPartitionLabel para continuar.';
    }

    if (_currentStep == 2 && state.interval?.initialDate == null) {
      return 'Selecciona una fecha inicial para continuar.';
    }

    return null;
  }

  bool _isReadyToCreate(CreateSesssionsFormState state) {
    return state.sessions.isNotEmpty &&
        state.selectedPhysicalPartitions.isNotEmpty &&
        state.interval?.initialDate != null;
  }

  Map<int, String> _partitionDisplayLabelByPartitionId(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    final fromManager = context
        .read<SessionManagerBloc>()
        .state
        .clubPartitions
        .fold<Map<int, String>>(<int, String>{}, (map, clubPartition) {
          final currentPhysicalPartitions =
              clubPartition.physicalPartitions ?? const <PhysicalPartition>[];

          for (final partition in currentPhysicalPartitions) {
            map[partition.partitionPhysicalId] =
                PhysicalPartitionNaming.labelFromIdentifier(
              physicalIdentifier: partition.physicalIdentifier,
              partitionPhysicalId: partition.partitionPhysicalId,
              clubPartition: clubPartition,
            );
          }

          return map;
        });

    final defaultClubPartition = _defaultClubPartitionFromState(context, state);

    final fromSelection = state.selectedPhysicalPartitions.fold<Map<int, String>>(
      Map<int, String>.from(fromManager),
      (map, partition) {
        map[partition.partitionPhysicalId] =
            PhysicalPartitionNaming.labelFromIdentifier(
          physicalIdentifier: partition.physicalIdentifier,
          partitionPhysicalId: partition.partitionPhysicalId,
          clubPartition: _resolveClubPartitionForPhysicalPartition(
                state.selectedClubPartitions,
                partition.partitionPhysicalId,
              ) ??
              defaultClubPartition,
        );
        return map;
      },
    );

    return fromSelection;
  }

  Widget _buildSavingOverlay() {
    return Container(
      color: const Color(0xB80A090D),
      alignment: Alignment.center,
      child: Container(
        width: 320,
        decoration: BoxDecoration(color: RW.card, borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 4, color: RW.primary),
            ),
            const SizedBox(height: 18),
            const Text('Creando turnos…', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: RW.onSurface)),
            const SizedBox(height: 6),
            Text('Validando superposiciones con turnos existentes.', style: RW.tSubtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildResultOverlay(BuildContext context, CreateSesssionsFormState state) {
    final skipped = [...state.skippedSessions]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final previewItems = skipped.take(30).toList();
    final hiddenCount = skipped.length - previewItems.length;
    final physicalPartitionDisplayLabelMap = _partitionDisplayLabelByPartitionId(
      context,
      state,
    );
    final hasIncidents = skipped.isNotEmpty;

    return Container(
      color: const Color(0xB80A090D),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 620),
        child: Container(
          decoration: BoxDecoration(color: RW.card, borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasIncidents ? RW.errorContainer : RW.primaryContainer,
                      borderRadius: BorderRadius.circular(RW.columnRadius),
                    ),
                    child: Center(
                      child: Text(
                        hasIncidents ? 'ⓘ' : '✓',
                        style: TextStyle(color: hasIncidents ? RW.onErrorContainer : RW.onPrimaryContainer, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasIncidents ? 'Carga completada con incidencias' : 'Carga completada',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: RW.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasIncidents
                              ? 'Algunos turnos no se pudieron crear y requieren revisión.'
                              : 'Todos los turnos se crearon correctamente.',
                          style: RW.tSubtitle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ResultMetricCard(
                      label: 'Creados',
                      value: '${state.createdCount}',
                      accentColor: RW.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ResultMetricCard(
                      label: 'No creados',
                      value: '${skipped.length}',
                      accentColor: hasIncidents ? RW.error : RW.mutedMore,
                    ),
                  ),
                ],
              ),
              if (skipped.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Turnos no creados:', style: RW.tLabel),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: previewItems
                          .map(
                            (item) => _SkippedSessionTile(
                              item: item,
                              physicalPartitionDisplayLabel:
                                  physicalPartitionDisplayLabelMap[item.partitionPhysicalId],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                if (hiddenCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Mostrando ${previewItems.length} de ${skipped.length}. Quedaron $hiddenCount turno(s) adicionales con incidencia.',
                      style: RW.tSmall,
                    ),
                  ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _RWOutlinedButton(
                      label: 'Volver al gestor',
                      onPressed: () => _handleBackToCalendar(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RWFilledButton(
                      label: 'Cargar más turnos',
                      icon: Icons.add,
                      onPressed: _handleCreateMore,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ClubPartition? _resolveClubPartitionForPhysicalPartition(
    List<ClubPartition> selectedClubPartitions,
    int partitionPhysicalId,
  ) {
    for (final clubPartition in selectedClubPartitions) {
      final matchesPartition =
          (clubPartition.physicalPartitions ?? const <PhysicalPartition>[]).any(
        (partition) => partition.partitionPhysicalId == partitionPhysicalId,
      );

      if (matchesPartition) {
        return clubPartition;
      }
    }

    return null;
  }

  ClubPartition? _defaultClubPartitionFromState(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    if (state.selectedClubPartitions.isNotEmpty) {
      return state.selectedClubPartitions.first;
    }

    final managerClubPartitions = context
        .read<SessionManagerBloc>()
        .state
        .clubPartitions;

    if (managerClubPartitions.isNotEmpty) {
      return managerClubPartitions.first;
    }

    return null;
  }

  Widget _buildPresetFillChip(
    BuildContext context, {
    required String title,
    required TimeOfDay start,
    required TimeOfDay end,
    required String label,
    required Color dotColor,
    required int? selectedDuration,
    required ValueChanged<int> onDurationSelected,
  }) {
    return PopupMenuButton<int>(
      tooltip: 'Seleccionar duracion',
      onSelected: (durationMinutes) async {
        final selectedValue = durationMinutes == _customDurationOption
            ? await _askCustomDurationMinutes(context)
            : durationMinutes;

        if (!mounted || selectedValue == null) {
          return;
        }

        onDurationSelected(selectedValue);

        _fillPresetSessions(
          context,
          start: start,
          end: end,
          label: label,
          durationMinutes: selectedValue,
        );
      },
      itemBuilder: (context) => [
        ..._durationOptions(context).map(
          (minutes) => PopupMenuItem<int>(
            value: minutes,
            child: Text(_formatDurationLabel(minutes)),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<int>(
          value: _customDurationOption,
          child: Row(
            children: [
              Icon(Icons.tune, size: 18),
              SizedBox(width: 8),
              Text('Custom...'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RW.chipRadius),
          color: selectedDuration != null ? RW.surfaceHigh : RW.panel,
          border: Border.all(color: RW.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RW.onSurface)),
            if (selectedDuration != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: RW.surface),
                child: Text(_formatDurationLabel(selectedDuration), style: RW.tSmall),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: RW.muted),
          ],
        ),
      ),
    );
  }

  void _fillPresetSessions(
    BuildContext context, {
    required TimeOfDay start,
    required TimeOfDay end,
    required String label,
    required int durationMinutes,
  }) {
    final generatedSessions = _generatePresetSessionsUseCase.execute(
      start: start,
      end: end,
      durationMinutes: durationMinutes,
      existingSessions: sl<CreateSesssionsFormBloc>().state.sessions,
    );

    if (generatedSessions.isEmpty) {
      SnackbarsFunctions.showErrorsSnackbar(
        context,
        'No se pudieron generar turnos con esa duracion en el rango elegido.',
      );
      return;
    }

    final formBloc = sl<CreateSesssionsFormBloc>();
    formBloc.add(AddSessions(generatedSessions));

    SnackbarsFunctions.showSuccessSnackbar(
      context,
      'Se agregaron ${generatedSessions.length} turnos de ${_formatDurationLabel(durationMinutes)} para la $label.',
    );
  }

  Future<int?> _askCustomDurationMinutes(BuildContext context) async {
    final controller = TextEditingController();
    String? errorText;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: const Text('Duracion custom'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Minutos',
                      hintText: 'Ej: 75',
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tip: para una grilla prolija usa multiplos de 15.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = int.tryParse(controller.text.trim());
                    if (parsed == null || parsed <= 0) {
                      setInnerState(() {
                        errorText = 'Ingresa una duracion valida';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(parsed);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  List<int> _durationOptions(BuildContext context) {
    final defaultsFromPhysical =
        context
            .read<SessionManagerBloc>()
            .state
            .clubPartitions
            .expand(
              (partition) =>
                  partition.physicalPartitions ?? const <PhysicalPartition>[],
            )
            .where((physical) => physical.active)
            .map((physical) => physical.defaultSessionDuration)
            .whereType<int>()
            .where((minutes) => minutes > 0)
            .toSet()
            .toList()
          ..sort();

    final options = <int>[...defaultsFromPhysical, 30, 60, 90];

    final deduped = <int>[];
    for (final option in options) {
      if (!deduped.contains(option)) {
        deduped.add(option);
      }
    }

    return deduped;
  }

  String _formatDurationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) {
      return '$minutes min';
    }

    if (remainingMinutes == 0) {
      return '${hours}hs';
    }

    return '${hours}hs ${remainingMinutes}min';
  }
}

class _WizardStep {
  const _WizardStep({required this.label, required this.title, required this.subtitle});

  final String label;
  final String title;
  final String subtitle;
}

/// Barra de pasos clickeable que abarca toda la pantalla (reemplaza al
/// titulo+barra de progreso que antes vivian solo dentro de la tarjeta
/// derecha) — asi queda claro que izquierda y derecha responden al mismo paso.
class _StepTrackerBar extends StatelessWidget {
  const _StepTrackerBar({
    required this.steps,
    required this.currentStep,
    required this.maxReachable,
    required this.onStepTap,
  });

  final List<_WizardStep> steps;
  final int currentStep;
  final int maxReachable;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _buildStep(i),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: i < currentStep ? RW.primaryContainer : RW.surfaceHigh,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(int index) {
    final isCurrent = index == currentStep;
    final isDone = index < currentStep;
    final isLocked = index > maxReachable;

    final circleBg = isCurrent ? RW.primary : isDone ? RW.primaryContainer : isLocked ? RW.card : RW.surfaceHigh;
    final circleColor = isCurrent ? RW.onPrimary : isDone ? RW.onPrimaryContainer : isLocked ? RW.outlineVariant : RW.onSurfaceVariant;
    final labelColor = isCurrent ? RW.onSurface : isLocked ? RW.outlineVariant : RW.onSurfaceVariant;

    return InkWell(
      onTap: isLocked ? null : () => onStepTap(index),
      borderRadius: BorderRadius.circular(999),
      child: Opacity(
        opacity: isLocked ? 0.55 : 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: isDone
                  ? Text('✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: circleColor))
                  : Text('${index + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: circleColor)),
            ),
            const SizedBox(width: 10),
            Text(
              steps[index].label,
              style: TextStyle(fontSize: 13, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500, color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.title, required this.subtitle, this.legend = const [], this.trailing});

  final String title;
  final String subtitle;
  final List<Widget> legend;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: RW.tTitle),
        const SizedBox(height: 2),
        Text(subtitle, style: RW.tSubtitle),
        if (legend.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 14, runSpacing: 4, children: legend),
        ],
        if (trailing != null) ...[
          const SizedBox(height: 10),
          trailing!,
        ],
      ],
    );
  }
}

class _LegendIcon extends StatelessWidget {
  const _LegendIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: RW.muted),
        const SizedBox(width: 4),
        Text(label, style: RW.tSmall),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: RW.tSmall),
      ],
    );
  }
}

class _RWSurfaceBox extends StatelessWidget {
  const _RWSurfaceBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RW.surface,
        borderRadius: BorderRadius.circular(RW.surfaceRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _RWEmptyBox extends StatelessWidget {
  const _RWEmptyBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RW.surface,
        borderRadius: BorderRadius.circular(RW.surfaceRadius),
        border: Border.all(color: RW.outlineVariant, style: BorderStyle.solid),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Text(message, style: RW.tSubtitle, textAlign: TextAlign.center),
    );
  }
}

/// Resumen por columna, debajo de la grilla del paso "Canchas": cantidad de
/// turnos y subtotal de esa cancha para el día de semana elegido.
class _CourtTotalSummary extends StatelessWidget {
  const _CourtTotalSummary({
    required this.total,
    required this.sessionsCount,
    required this.dayLabel,
  });

  final double total;
  final int sessionsCount;
  final String dayLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$sessionsCount turno(s) · $dayLabel', style: RW.tSmall),
        const SizedBox(height: 2),
        Text(
          '${formatPriceLabel(total)} total',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RW.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Card de un turno en la vista por cancha (paso "Canchas") — funciona
/// idéntico a la card de la plantilla (paso "Horarios"): clic en la card
/// abre el mismo popover de edición (nudges de hora/15min + duración),
/// clic en la × la borra. Si el turno viene de la plantilla, editarlo lo
/// "desprende" en un ajuste propio de esta cancha (se quita de la plantilla
/// compartida y se agrega como extra con el valor nuevo), ya que esta vista
/// no puede modificar el horario global sin afectar a las demás canchas.
///
/// Muestra el precio del turno en esa cancha (resuelto por la tarifa por
/// horario, el precio base de la cancha o un precio manual) y qué regla lo
/// determina; el popover agrega el detalle, el enlace a la configuración de
/// esa regla y la opción de pisar el precio a mano.
class _CourtSessionEditCard extends StatefulWidget {
  const _CourtSessionEditCard({
    required this.previewSession,
    required this.original,
    required this.isExtra,
    required this.partition,
    required this.height,
    required this.dayOfWeek,
    required this.resolvedPrice,
    required this.weekPrices,
    required this.onOpenConfig,
    this.autoOpen = false,
    this.onAutoOpened,
  });

  final Session previewSession;
  final Session original;
  final bool isExtra;
  final PhysicalPartition partition;
  final double height;

  /// Día (1..7) para el que está calculado [resolvedPrice].
  final int dayOfWeek;
  final ResolvedSessionPrice resolvedPrice;

  /// Precio de este turno en esta cancha para cada día de la semana.
  final Map<int, double> weekPrices;
  final Future<void> Function(ClubConfigFocus focus) onOpenConfig;
  final bool autoOpen;
  final VoidCallback? onAutoOpened;

  int get partitionPhysicalId => partition.partitionPhysicalId;

  @override
  State<_CourtSessionEditCard> createState() => _CourtSessionEditCardState();
}

class _CourtSessionEditCardState extends State<_CourtSessionEditCard> {
  final dropdownController = DropdownController();

  @override
  void initState() {
    super.initState();
    _maybeAutoOpen();
  }

  @override
  void didUpdateWidget(covariant _CourtSessionEditCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoOpen && !oldWidget.autoOpen) _maybeAutoOpen();
  }

  void _maybeAutoOpen() {
    if (!widget.autoOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      dropdownController.show!();
      widget.onAutoOpened?.call();
    });
  }

  void _replaceWith(Session updated) {
    final bloc = sl<CreateSesssionsFormBloc>();
    // Un precio manual sigue al turno aunque se le cambie el horario.
    final manualPrice = bloc.state.manualPriceFor(widget.partitionPhysicalId, widget.original);
    if (widget.isExtra) {
      bloc.add(RemoveExtraSessionFromPartition(widget.partitionPhysicalId, widget.original));
    } else {
      bloc.add(RemoveSessionFromPartition(widget.partitionPhysicalId, widget.original));
    }
    bloc.add(AddExtraSessionToPartition(widget.partitionPhysicalId, updated));
    if (manualPrice != null) {
      bloc.add(SetManualPrice(widget.partitionPhysicalId, widget.original, null));
      bloc.add(SetManualPrice(widget.partitionPhysicalId, updated, manualPrice));
    }
  }

  void _setManualPrice(double? price) {
    sl<CreateSesssionsFormBloc>().add(
      SetManualPrice(widget.partitionPhysicalId, widget.original, price),
    );
  }

  void _openConfig(ClubConfigFocus focus) {
    dropdownController.hide!();
    widget.onOpenConfig(focus);
  }

  void _openTariff() {
    final resolved = widget.resolvedPrice;
    _openConfig(ClubConfigFocus.priceTariff(
      clubPartitionId: resolved.tariff?.clubPartitionId ?? widget.partition.clubPartitionId,
      priceTariffId: resolved.tariff?.priceTariffId,
      priceRuleId: resolved.rule?.priceRuleId,
    ));
  }

  void _openPartition() {
    _openConfig(ClubConfigFocus.physicalPartition(
      clubPartitionId: widget.partition.clubPartitionId,
      partitionPhysicalId: widget.partitionPhysicalId,
    ));
  }

  void _nudge(int deltaMinutes) {
    final base = widget.original;
    final totalMinutes = (base.startTime.hour * 60 + base.startTime.minute + deltaMinutes)
        .clamp(RW.firstHour * 60, RW.lastHour * 60 - 15);
    final newStart = DateTime(
      base.startTime.year,
      base.startTime.month,
      base.startTime.day,
      totalMinutes ~/ 60,
      totalMinutes % 60,
    );
    _replaceWith(base.copyWith(startTime: newStart));
  }

  void _setDuration(int minutes) {
    _replaceWith(widget.original.copyWith(duration: minutes));
  }

  void _delete() {
    final bloc = sl<CreateSesssionsFormBloc>();
    if (widget.isExtra) {
      bloc.add(RemoveExtraSessionFromPartition(widget.partitionPhysicalId, widget.original));
    } else {
      bloc.add(RemoveSessionFromPartition(widget.partitionPhysicalId, widget.original));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownWidget(
      aligned: const Aligned(
        follower: Alignment.topLeft,
        target: Alignment.bottomLeft,
        offset: Offset(0, 6),
      ),
      width: 290,
      obscureBackground: false,
      dropdownController: dropdownController,
      menuWidget: SessionEditPopover(
        session: widget.original,
        onNudge: _nudge,
        onSetDuration: _setDuration,
        onDelete: () {
          _delete();
          dropdownController.hide!();
        },
        onClose: () => dropdownController.hide!(),
        extraSection: CourtPriceSection(
          resolved: widget.resolvedPrice,
          dayOfWeek: widget.dayOfWeek,
          weekPrices: widget.weekPrices,
          onSetManualPrice: _setManualPrice,
          onOpenTariff: _openTariff,
          onOpenPartition: _openPartition,
        ),
      ),
      child: _buildBlock(context),
    );
  }

  Widget _buildBlock(BuildContext context) {
    final session = widget.previewSession;
    final end = session.endTime as DateTime;
    final resolved = widget.resolvedPrice;
    final label = '${DateFormat.Hm().format(session.startTime)}–${DateFormat.Hm().format(end)}'
        ' · ${formatPriceLabel(resolved.price)}';
    final accent = widget.isExtra ? RW.accentExtra : RW.accent60min;
    final varies = widget.weekPrices.values.toSet().length > 1;
    // Segunda línea con la regla que aplica, si el bloque es lo bastante alto.
    final showSource = widget.height >= 30;
    final sourceLabel = shortPriceSourceLabel(resolved);
    final tooltip = [
      switch (resolved.source) {
        SessionPriceSource.tariffRule =>
          'Tarifa «${resolved.tariff!.name}» · franja ${formatDaysOfWeek(resolved.rule!.daysOfWeek)} '
              '${resolved.rule!.startTime}–${resolved.rule!.endTime}',
        SessionPriceSource.partitionDefault => 'Precio base de la cancha',
        SessionPriceSource.manual => 'Precio manual',
      },
      if (varies) 'Según el día: ${formatWeekPrices(widget.weekPrices)}',
    ].join('\n');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => dropdownController.show!(),
                borderRadius: BorderRadius.circular(RW.blockRadiusSmall),
                child: Container(
                  decoration: BoxDecoration(
                    color: RW.primaryContainer,
                    borderRadius: BorderRadius.circular(RW.blockRadiusSmall),
                    border: Border(left: BorderSide(color: accent, width: 3)),
                  ),
                  padding: const EdgeInsets.fromLTRB(6, 4, 18, 4),
                  alignment: Alignment.topLeft,
                  child: Tooltip(
                    message: tooltip,
                    waitDuration: const Duration(milliseconds: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(fontSize: 10, color: RW.onPrimaryContainer),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (showSource) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(priceSourceIcon(resolved.source), size: 10, color: RW.primary),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  varies ? '$sourceLabel · varía x día' : sourceLabel,
                                  style: const TextStyle(fontSize: 9, color: RW.onPrimaryContainer),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: InkWell(
              onTap: _delete,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.32),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '×',
                  style: TextStyle(fontSize: 10, color: RW.onPrimaryContainer, height: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RWChip extends StatelessWidget {
  const _RWChip({
    required this.selected,
    required this.label,
    this.helper,
    required this.onSelected,
    this.enabled = true,
  });

  final bool selected;
  final String label;
  final String? helper;
  final ValueChanged<bool> onSelected;

  /// false para un sector/cancha inactivo: se ve apagado y no se puede tocar.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
      onTap: enabled ? () => onSelected(!selected) : null,
      borderRadius: BorderRadius.circular(RW.chipRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? RW.primaryContainer : RW.panel,
          borderRadius: BorderRadius.circular(RW.chipRadius),
          border: Border.all(color: selected ? RW.primaryContainer : RW.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!enabled) ...[
              const Icon(Icons.block, size: 12, color: RW.muted),
              const SizedBox(width: 4),
            ],
            Text(
              helper == null ? label : '$label · $helper',
              style: TextStyle(
                fontSize: 12,
                color: selected ? RW.onPrimaryContainer : RW.onSurfaceVariant,
                decoration: enabled ? null : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _RWSelectableTile extends StatelessWidget {
  const _RWSelectableTile({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RW.columnRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? RW.primaryContainer : RW.surface,
          borderRadius: BorderRadius.circular(RW.columnRadius),
          border: Border.all(color: selected ? RW.primaryContainer : RW.surfaceHigh),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: selected ? RW.onPrimaryContainer : RW.onSurfaceVariant)),
            if (selected) const Text('✓', style: TextStyle(color: RW.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }
}

class _RWOutlinedButton extends StatelessWidget {
  const _RWOutlinedButton({required this.label, this.icon, required this.onPressed});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: disabled ? RW.outlineVariant : RW.onSurfaceVariant,
        side: BorderSide(color: RW.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RW.buttonRadius)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: RW.tButton,
      ),
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _RWFilledButton extends StatelessWidget {
  const _RWFilledButton({required this.label, this.icon, this.loading = false, required this.onPressed});

  final String label;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: disabled ? RW.surfaceHigh : RW.primary,
        foregroundColor: disabled ? RW.mutedMore : RW.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RW.buttonRadius)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: RW.tButton,
      ),
      icon: loading
          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: disabled ? RW.mutedMore : RW.onPrimary))
          : (icon == null ? const SizedBox.shrink() : Icon(icon, size: 16)),
      label: Text(label),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: RW.surface,
        borderRadius: BorderRadius.circular(RW.columnRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: RW.tSmall),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: RW.onSurface)),
        ],
      ),
    );
  }
}

class _SkippedSessionTile extends StatelessWidget {
  const _SkippedSessionTile({
    required this.item,
    required this.physicalPartitionDisplayLabel,
  });

  final SkippedSession item;
  final String? physicalPartitionDisplayLabel;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(item.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RW.surface,
        borderRadius: BorderRadius.circular(RW.columnRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetaPill(text: date),
              _MetaPill(text: item.timeRangeLabel),
              _MetaPill(text: physicalPartitionDisplayLabel ?? '-'),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.reason.label, style: const TextStyle(fontSize: 11, color: RW.error)),
        ],
      ),
    );
  }
}

class _ResultMetricCard extends StatelessWidget {
  const _ResultMetricCard({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: RW.surface,
        borderRadius: BorderRadius.circular(RW.columnRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: RW.tSmall),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: accentColor)),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: RW.panel,
        borderRadius: BorderRadius.circular(RW.chipRadius),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, color: RW.onSurfaceVariant)),
    );
  }
}
