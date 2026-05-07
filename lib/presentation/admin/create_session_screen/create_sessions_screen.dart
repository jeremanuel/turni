import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/chips/filter_chip_interval_date.dart';
import '../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../core/utils/physical_partition_naming.dart';
import '../../../core/utils/types/time_interval.dart';
import '../../../domain/entities/club_partition.dart';
import '../../../domain/entities/create_sessions_result.dart';
import '../../../domain/entities/physical_partition.dart';
import '../../../domain/use_case/session_template/generate_preset_sessions_use_case.dart';
import '../../core/agenda/agenda.dart';
import '../session_manager_screen/bloc/session_manager_bloc.dart';
import '../session_manager_screen/bloc/session_manager_event.dart';
import 'bloc/create_sesssions_form_bloc.dart';

import 'widgets/add_session_button.dart';
import 'widgets/agenda_edit_card.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  int _currentStep = 0;
  int? _selectedMorningDuration;
  int? _selectedAfternoonDuration;
  final GeneratePresetSessionsUseCase _generatePresetSessionsUseCase =
      GeneratePresetSessionsUseCase();

  static const int _customDurationOption = -1;

  static const _steps = [
    _WizardStep(
      title: '1. Plantilla de turnos',
      subtitle: 'Define los horarios base que se van a repetir.',
    ),
    _WizardStep(
      title: '2. Modalidades y particiones',
      subtitle: 'Selecciona donde se van a crear los turnos.',
    ),
    _WizardStep(
      title: '3. Rango de fechas',
      subtitle: 'Define desde cuando y hasta cuando aplica la carga.',
    ),
    _WizardStep(
      title: '4. Confirmacion',
      subtitle: 'Revisa todo antes de crear los turnos.',
    ),
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

    return BlocListener<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      bloc: formBloc,
      listenWhen: (previous, current) =>
          previous.savedSessions != current.savedSessions &&
          current.savedSessions,
      listener: (context, state) async {
        final action = await _showBulkCreationResultDialog(context, state);

        if (!context.mounted) return;

        if (action == _BulkCreationDialogAction.backToCalendar) {
          context.read<SessionManagerBloc>().add(
            SessionManagerEvent.reloadSessionsEvent(),
          );
          context.go(AppRoutes.SESSION_MANAGER_ROUTE.path);
          return;
        }

        if (action == _BulkCreationDialogAction.retryCreation) {
          setState(() {
            _currentStep = _firstWizardStep;
          });
        }
      },
      child: Portal(
        child: BlocBuilder<CreateSesssionsFormBloc, CreateSesssionsFormState>(
          bloc: formBloc,
          builder: (context, state) {
            final width = MediaQuery.sizeOf(context).width;
            final isWide = width >= 1200;
            final isDesktop = width >= 1024;

            final content = isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildSessionsPreviewPanel(context, state),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 430,
                        child: _buildWizardPanel(context, state),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(child: _buildWizardPanel(context, state)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 320,
                        child: _buildSessionsPreviewPanel(context, state),
                      ),
                    ],
                  );

            return Padding(
              padding: const EdgeInsets.all(12),
              child: isDesktop
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            context.go(AppRoutes.SESSION_MANAGER_ROUTE.path);
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Volver a gestor de turnos'),
                        ),
                        const SizedBox(height: 12),
                        Expanded(child: content),
                      ],
                    )
                  : content,
            );
          },
        ),
      ),
    );
  }

  Widget _buildWizardPanel(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    final current = _steps[_currentStep];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creacion guiada de turnos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  current.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(current.subtitle),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _steps.length,
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(_currentStep),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildStepContent(context, state),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _currentStep == 0
                      ? null
                      : () => setState(() {
                          _currentStep -= 1;
                        }),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Atras'),
                ),
                SizedBox(width: 16),
                if (_currentStep < _steps.length - 1)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _onContinuePressed(context, state),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continuar'),
                    ),
                  ),
                if (_currentStep == _steps.length - 1)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isReadyToCreate(state)
                          ? () => sl<CreateSesssionsFormBloc>().add(
                              const CreateSessions(),
                            )
                          : null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Crear turnos'),
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
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.schedule_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arma tu plantilla base',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Puedes crear horarios manualmente o completar bloques rapidos para la manana y la tarde.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Carga rapida por franja',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetFillChip(
                    context,
                    icon: Icons.wb_sunny_outlined,
                    title: 'Completar toda la manana',
                    start: const TimeOfDay(hour: 8, minute: 30),
                    end: const TimeOfDay(hour: 13, minute: 0),
                    label: 'manana',
                    selectedDuration: _selectedMorningDuration,
                    onDurationSelected: (value) {
                      setState(() {
                        _selectedMorningDuration = value;
                      });
                    },
                  ),
                  _buildPresetFillChip(
                    context,
                    icon: Icons.wb_twilight_outlined,
                    title: 'Completar toda la tarde',
                    start: const TimeOfDay(hour: 14, minute: 0),
                    end: const TimeOfDay(hour: 22, minute: 30),
                    label: 'tarde',
                    selectedDuration: _selectedAfternoonDuration,
                    onDurationSelected: (value) {
                      setState(() {
                        _selectedAfternoonDuration = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Agregar horario manual',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const AddSessionButton(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasSessions
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasSessions
                  ? colorScheme.primary.withValues(alpha: 0.45)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasSessions ? Icons.check_circle_outline : Icons.info_outline,
                color: hasSessions
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasSessions
                      ? '${state.sessions.length} horario(s) cargado(s) en la plantilla.'
                      : 'Todavia no hay horarios en la plantilla.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tip: puedes editar o eliminar cada bloque desde la vista previa de la agenda.',
          style: Theme.of(context).textTheme.bodySmall,
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
        const Text('Modalidades'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: clubPartitions
              .map(
                (partition) => FilterChip(
                  selected: state.selectedClubPartitions.contains(partition),
                  label: Text(partition.clubType?.name ?? 'Modalidad'),
                  showCheckmark: false,
                  onSelected: (value) => formBloc.add(
                    ChangeSelectionClubPartition(partition, value),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        Text(pluralPartitionLabel),
        const SizedBox(height: 10),
        if (physicalPartitions.isEmpty)
          Text(
            'Selecciona al menos una modalidad para habilitar ${pluralPartitionLabel.toLowerCase()}.',
          ),
        if (physicalPartitions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: physicalPartitions
                .map(
                  (physicalPartition) => FilterChip(
                    key: ValueKey(physicalPartition.partitionPhysicalId),
                    selected: state.selectedPhysicalPartitions.contains(
                      physicalPartition,
                    ),
                    label: Text(
                      PhysicalPartitionNaming.labelFromIdentifier(
                        physicalIdentifier: physicalPartition.physicalIdentifier,
                        partitionPhysicalId:
                            physicalPartition.partitionPhysicalId,
                        clubPartition: _resolveClubPartitionForPhysicalPartition(
                              state.selectedClubPartitions,
                              physicalPartition.partitionPhysicalId,
                            ) ??
                            defaultClubPartition,
                      ),
                    ),
                    showCheckmark: false,
                    onSelected: (value) => formBloc.add(
                      ChangeSelectionPhysicalPartition(
                        physicalPartition,
                        value,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 18),
        Text(
          'Seleccionadas: ${state.selectedPhysicalPartitions.length} ${state.selectedPhysicalPartitions.length == 1 ? singularPartitionLabel.toLowerCase() : pluralPartitionLabel.toLowerCase()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDateRangeStep(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    final initialDate = state.interval?.initialDate;
    final endDate = state.interval?.endDate;
    final hasSelection = initialDate != null || endDate != null;
    final summary = initialDate == null
        ? 'Aun no seleccionaste una fecha.'
        : endDate == null
        ? DateFormat('dd/MM/yyyy').format(initialDate)
        : '${DateFormat('dd/MM/yyyy').format(initialDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}';

    return ListView(
      children: [
        Text(
          'Selecciona el periodo de creacion',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Puedes elegir un solo dia o un rango completo.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Wrap(
            children: [
              FilterChipIntervalDate(
                initialValue: state.interval,
                label: 'Periodo de carga',
                onApply: (interval) => sl<CreateSesssionsFormBloc>().add(
                  ChangeSelectionInitialDate(interval),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasSelection
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasSelection
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.45)
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasSelection ? Icons.event_available : Icons.event_note,
                color: hasSelection
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(summary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    final initialDate = state.interval?.initialDate;
    final endDate = state.interval?.endDate;

    final int daysCount = initialDate == null
        ? 0
        : (endDate == null ? 1 : endDate.difference(initialDate).inDays + 1);
    final int templateCount = state.sessions.length;
    final int partitionsCount = state.selectedPhysicalPartitions.length;
    final int totalSessions = templateCount * partitionsCount * daysCount;
    final bool canEstimate =
        templateCount > 0 && partitionsCount > 0 && daysCount > 0;

    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        _SummaryTile(
          title: 'Horarios plantilla',
          value: '$templateCount',
          helper: 'Bloques horarios configurados',
        ),
        const SizedBox(height: 10),
        _SummaryTile(
          title:
              '${PhysicalPartitionNaming.pluralFromClubPartition(_defaultClubPartitionFromState(context, state))} seleccionadas',
          value: '$partitionsCount',
          helper: 'Donde se van a crear los turnos',
        ),
        const SizedBox(height: 10),
        _SummaryTile(
          title: 'Rango de carga',
          value: initialDate == null
              ? 'Sin fecha'
              : endDate == null
              ? DateFormat('dd/MM/yyyy').format(initialDate)
              : '${DateFormat('dd/MM/yyyy').format(initialDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
          helper: daysCount == 0
              ? 'Periodo que se usara para crear turnos'
              : daysCount == 1
              ? '1 dia seleccionado'
              : '$daysCount dias seleccionados',
        ),
        const SizedBox(height: 14),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: canEstimate
                ? colorScheme.primaryContainer.withValues(alpha: 0.55)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canEstimate
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: canEstimate
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.layers_outlined,
                  color: canEstimate
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total de turnos a crear',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: canEstimate
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    canEstimate
                        ? Text(
                            '$totalSessions turnos',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          )
                        : Text(
                            'Completa los pasos anteriores para ver el estimado.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Puedes volver atras para ajustar cualquier paso antes de confirmar.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSessionsPreviewPanel(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Text(
              'Vista previa de agenda',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5,
                    spreadRadius: 3,
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.08),
                  ),
                ],
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Agenda(
                sessions: state.sessions,
                buildCard: (session, physicalPartition, height) =>
                    AgendaEditCard(session: session),
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
                  ),
                ],
                fromDate: DateTime.now().applied(
                  const TimeOfDay(hour: 8, minute: 30),
                ),
                lastDate: DateTime.now().applied(
                  const TimeOfDay(hour: 22, minute: 30),
                ),
              ),
            ),
          ),
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

  Future<_BulkCreationDialogAction?> _showBulkCreationResultDialog(
    BuildContext context,
    CreateSesssionsFormState state,
  ) {
    final skipped = [...state.skippedSessions]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final previewItems = skipped.take(30).toList();
    final hiddenCount = skipped.length - previewItems.length;
    final physicalPartitionDisplayLabelMap = _partitionDisplayLabelByPartitionId(
      context,
      state,
    );

    return showDialog<_BulkCreationDialogAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final textTheme = Theme.of(dialogContext).textTheme;
        final hasIncidents = skipped.isNotEmpty;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasIncidents
                      ? colorScheme.tertiaryContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasIncidents ? Icons.info_outline : Icons.check_circle_outline,
                  color: hasIncidents
                      ? colorScheme.onTertiaryContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasIncidents
                          ? 'Carga completada con incidencias'
                          : 'Carga completada',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasIncidents
                          ? 'Algunos turnos no se pudieron crear y requieren revision.'
                          : 'Todos los turnos se crearon correctamente.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 520),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ResultMetricCard(
                          icon: Icons.playlist_add_check_circle_outlined,
                          label: 'Creados',
                          value: '${state.createdCount}',
                          accentColor: colorScheme.primary,
                        ),
                        _ResultMetricCard(
                          icon: Icons.error_outline,
                          label: 'No creados',
                          value: '${skipped.length}',
                          accentColor: hasIncidents
                              ? colorScheme.error
                              : colorScheme.outline,
                        ),
                      ],
                    ),
                    if (skipped.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Turnos no creados:',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        padding: const EdgeInsets.all(10),
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
                      if (hiddenCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Mostrando ${previewItems.length} de ${skipped.length}. Quedaron $hiddenCount turno(s) adicionales con incidencia.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
        
            TextButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(
                _BulkCreationDialogAction.backToCalendar,
              ),
              label: const Text('Volver al calendario'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(
                _BulkCreationDialogAction.retryCreation,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar crear de nuevo'),
            ),
          ],
        );
      },
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
    required IconData icon,
    required String title,
    required TimeOfDay start,
    required TimeOfDay end,
    required String label,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selectedDuration != null
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          border: Border.all(
            color: selectedDuration != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selectedDuration != null
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (selectedDuration != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Text(
                  _formatDurationLabel(selectedDuration),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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

enum _BulkCreationDialogAction { backToCalendar, retryCreation }

class _WizardStep {
  const _WizardStep({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.title,
    required this.value,
    required this.helper,
  });

  final String title;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(helper, style: Theme.of(context).textTheme.bodySmall),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final date = DateFormat('dd/MM/yyyy').format(item.startTime);
    final details = item.reason.label;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetaPill(text: date),
              _MetaPill(text: item.timeRangeLabel),
              _MetaPill(text: physicalPartitionDisplayLabel ?? '-'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            details,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMetricCard extends StatelessWidget {
  const _ResultMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
