import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/date_picker/interval_calendar_panel.dart';
import '../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../core/utils/thousands_format.dart';
import '../../../core/utils/types/time_interval.dart';
import '../../../domain/entities/bulk_sessions.dart';
import '../../../domain/entities/club_partition.dart';
import '../../../domain/entities/physical_partition.dart';
import '../../../domain/repositories/bulk_session_repository.dart';
import '../club_config/club_config_focus.dart';
import '../club_config/widgets/admin_data_table.dart';
import '../club_config/widgets/duration_minutes_field.dart';
import '../club_config/widgets/inactive_partition_hint.dart';
import '../club_config/widgets/price_field.dart';
import '../club_config/widgets/time_field.dart';
import '../session_manager_screen/bloc/session_manager_bloc.dart';
import '../session_manager_screen/bloc/session_manager_event.dart';
import '../session_manager_screen/bloc/session_manager_state.dart';
import 'bulk_texts.dart';
import 'cubit/bulk_edit_cubit.dart';
import 'dialogs/bulk_confirm_delete_dialog.dart';
import 'dialogs/bulk_result_dialog.dart';
import 'widgets/bulk_widgets.dart';

/// Tab "Editar o eliminar" de Gestión masiva de turnos: reglas (qué turnos),
/// acción (qué hacer) y vista previa, con la barra de aplicar fija abajo.
class BulkEditTab extends StatelessWidget {
  const BulkEditTab({super.key, this.repository});

  /// Inyectable para tests; por default el registrado en el service locator.
  final BulkSessionRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BulkEditCubit(repository ?? sl<BulkSessionRepository>())
        ..initPartitions(context.read<SessionManagerBloc>().state.clubPartitions),
      child: BlocListener<SessionManagerBloc, SessionManagerState>(
        listenWhen: (previous, current) => previous.clubPartitions != current.clubPartitions,
        listener: (context, managerState) =>
            context.read<BulkEditCubit>().initPartitions(managerState.clubPartitions),
        child: const _BulkEditView(),
      ),
    );
  }
}

class _BulkEditView extends StatefulWidget {
  const _BulkEditView();

  @override
  State<_BulkEditView> createState() => _BulkEditViewState();
}

class _BulkEditViewState extends State<_BulkEditView> {
  final _startFrom = TextEditingController(text: '00:00');
  final _startTo = TextEditingController(text: '23:59');
  final _fixedPrice = TextEditingController();
  final _percent = TextEditingController();
  final _roundTo = TextEditingController();
  final _duration = TextEditingController();
  final _shift = TextEditingController();

  static final _timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  BulkEditCubit get _cubit => context.read<BulkEditCubit>();

  @override
  void dispose() {
    for (final c in [_startFrom, _startTo, _fixedPrice, _percent, _roundTo, _duration, _shift]) {
      c.dispose();
    }
    super.dispose();
  }

  static int? _parseSignedInt(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9\-]'), '');
    return int.tryParse(cleaned);
  }

  static double? _parseSignedDouble(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9,\-]'), '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  /// Desplegable del rango personalizado: el mismo calendario que el
  /// "Rango personalizado" del agregador de turnos (IntervalCalendarPanel).
  final _rangeDropdown = DropdownController();

  void _pickRange() => _rangeDropdown.show!();

  void _applyRange(TimeInterval interval) {
    final start = interval.initialDate ?? interval.endDate!;
    _cubit.setRange(start, interval.endDate ?? start);
    _rangeDropdown.hide!();
  }

  Future<void> _apply(BulkEditState state, BulkEditTexts texts) async {
    if (state.actionKind == BulkActionKind.delete) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => BulkConfirmDeleteDialog(
          count: state.preview!.affected,
          period: texts.period,
          days: texts.days,
          hours: texts.hours,
          courts: texts.courts,
          excluded: state.preview!.excluded,
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final result = await _cubit.apply();
    if (result == null || !mounted) return;

    context.read<SessionManagerBloc>().add(ReloadSessionsEvent());

    final next = await showDialog<BulkResultNext>(
      context: context,
      builder: (_) => BulkResultDialog(
        isDelete: state.actionKind == BulkActionKind.delete,
        summary: texts.resultSummary,
        result: result,
      ),
    );
    if (!mounted) return;
    switch (next) {
      case BulkResultNext.showExcluded:
        _cubit.showExcluded();
      case BulkResultNext.goToManager:
        context.go(AppRoutes.SESSION_MANAGER_ROUTE.path);
      case BulkResultNext.newOperation:
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clubPartitions = context.select<SessionManagerBloc, List<ClubPartition>>(
      (bloc) => bloc.state.clubPartitions,
    );

    return BlocConsumer<BulkEditCubit, BulkEditState>(
      // Con una vista previa ya en pantalla (ej. falló el "Aplicar" o un
      // refresco), el error va como SnackBar en vez de reemplazar la tabla.
      listenWhen: (previous, current) =>
          current.previewError != null &&
          previous.previewError != current.previewError &&
          current.preview != null,
      listener: (context, state) => SnackbarsFunctions.showErrorsSnackbar(context, state.previewError!),
      builder: (context, state) {
        final texts = BulkEditTexts(state: state, clubPartitions: clubPartitions);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final rules = _buildRulesCard(context, state, clubPartitions);
                    final right = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildActionCard(context, state),
                        const SizedBox(height: 24),
                        _buildPreviewCard(context, state, texts),
                      ],
                    );
                    // Reglas de ancho fijo a la izquierda y el resto a la
                    // derecha (gap 24); en angosto se apilan. 440px: lo justo
                    // para que los 7 días y los 3 períodos entren en una fila.
                    if (constraints.maxWidth >= 440 + 24 + 560) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 440, child: rules),
                          const SizedBox(width: 24),
                          Expanded(child: right),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: rules),
                        ),
                        const SizedBox(height: 24),
                        right,
                      ],
                    );
                  },
                ),
              ),
            ),
            _buildFooter(context, state, texts, scheme),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // 1. ¿Qué turnos?
  // ------------------------------------------------------------------

  Widget _buildRulesCard(BuildContext context, BulkEditState state, List<ClubPartition> clubPartitions) {
    final scheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final selectedPartitions =
        clubPartitions.where((p) => state.clubPartitionIds.contains(p.club_partition_id)).toList();
    final courts = [
      for (final partition in selectedPartitions)
        for (final court in partition.physicalPartitions ?? const <PhysicalPartition>[]) (partition, court),
    ];

    Widget section(String label, Widget child, {Widget? trailing}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [Expanded(child: BulkFieldLabel(label)), if (trailing != null) trailing],
            ),
            const SizedBox(height: 10),
            child,
          ],
        );

    Widget twoColumns(Widget a, Widget b) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
        );

    // Fecha: campo de solo lectura que abre el calendario de rango.
    Widget dateField(String label, DateTime value) => BulkLabeledField(
          label: label,
          child: InkWell(
            onTap: _pickRange,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: bulkInputDecoration(context),
              child: Text(dateFormat.format(value), style: const TextStyle(fontSize: 14)),
            ),
          ),
        );

    Widget timeField(String label, TextEditingController controller, ValueChanged<String> onValid) =>
        BulkLabeledField(
          label: label,
          child: _ListeningField(
            controller: controller,
            onChanged: (text) {
              if (_timePattern.hasMatch(text)) onValid(text);
            },
            child: TimeField(controller: controller, decoration: bulkInputDecoration(context)),
          ),
        );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BulkCardHeader(
              title: '1. ¿Qué turnos?',
              subtitle: 'Definí las reglas: se toman los turnos que cumplan todas.',
            ),
            const SizedBox(height: 20),
            section(
              'Período',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    BulkChoiceChip(
                      label: 'Esta semana',
                      selected: state.preset == BulkPeriodPreset.thisWeek,
                      onTap: () => _cubit.setPreset(BulkPeriodPreset.thisWeek),
                    ),
                    BulkChoiceChip(
                      label: 'Próximos 30 días',
                      selected: state.preset == BulkPeriodPreset.next30,
                      onTap: () => _cubit.setPreset(BulkPeriodPreset.next30),
                    ),
                    BulkChoiceChip(
                      label: 'Personalizado',
                      selected: state.preset == BulkPeriodPreset.custom,
                      onTap: () {
                        _cubit.setPreset(BulkPeriodPreset.custom);
                        _pickRange();
                      },
                    ),
                  ]),
                  const SizedBox(height: 10),
                  DropdownWidget(
                    dropdownController: _rangeDropdown,
                    menuWidget: IntervalCalendarPanel(
                      initialValue: TimeInterval(initialDate: state.from, endDate: state.to),
                      onApply: _applyRange,
                      onCancel: () => _rangeDropdown.hide!(),
                    ),
                    child: twoColumns(dateField('Desde', state.from), dateField('Hasta', state.to)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            section(
              'Días de la semana',
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (var day = 1; day <= 7; day++)
                  BulkDayPill(
                    letter: BulkEditTexts.dayLetters[day - 1],
                    semanticLabel: BulkEditTexts.dayNames[day - 1],
                    selected: state.daysOfWeek.contains(day),
                    onTap: () => _cubit.toggleDay(day),
                  ),
              ]),
            ),
            const SizedBox(height: 20),
            section(
              'Franja horaria (inicio del turno)',
              twoColumns(
                timeField('Desde', _startFrom, _cubit.setStartFrom),
                timeField('Hasta', _startTo, _cubit.setStartTo),
              ),
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 20),
            section(
              'Modalidades',
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final partition in clubPartitions)
                  InactivePartitionHint(
                    inactive: !partition.active,
                    message: InactivePartitionHint.clubPartitionMessage,
                    focus: ClubConfigFocus.clubPartition(partition.club_partition_id ?? 0),
                    onConfigClosed: () =>
                        context.read<SessionManagerBloc>().add(ReloadClubPartitionsEvent()),
                    child: BulkChoiceChip(
                      label: partition.clubType?.name ?? 'Modalidad',
                      enabled: partition.active,
                      selected: state.clubPartitionIds.contains(partition.club_partition_id),
                      onTap: () => _cubit.toggleClubPartition(partition),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 20),
            section(
              'Canchas',
              courts.isEmpty
                  ? Text(
                      'Elegí al menos una modalidad.',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    )
                  : Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final (partition, court) in courts)
                        InactivePartitionHint(
                          inactive: !court.active,
                          message: InactivePartitionHint.physicalPartitionMessage,
                          focus: ClubConfigFocus.physicalPartition(
                            clubPartitionId: court.clubPartitionId,
                            partitionPhysicalId: court.partitionPhysicalId,
                          ),
                          onConfigClosed: () =>
                              context.read<SessionManagerBloc>().add(ReloadClubPartitionsEvent()),
                          child: BulkChoiceChip(
                            label: BulkEditTexts(state: state, clubPartitions: clubPartitions)
                                .courtChipLabel(partition, court, withModality: selectedPartitions.length > 1),
                            enabled: court.active,
                            selected: state.physicalIds.contains(court.partitionPhysicalId),
                            onTap: () => _cubit.toggleCourt(court),
                          ),
                        ),
                    ]),
              trailing: courts.isEmpty
                  ? null
                  : TextButton(
                      onPressed: () => _cubit.selectAllCourts([for (final (_, court) in courts) court]),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: bulkButtonTextStyle(context),
                      ),
                      child: const Text('Todas'),
                    ),
            ),
            const SizedBox(height: 20),
            BulkInfoBox(
              icon: Icons.lock_outline,
              background: scheme.surfaceContainerLow,
              foreground: scheme.onSurfaceVariant,
              iconColor: scheme.primary,
              child: Text.rich(TextSpan(children: [
                const TextSpan(text: 'Los turnos '),
                TextSpan(
                  text: 'reservados',
                  style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w500),
                ),
                const TextSpan(text: ' o con una '),
                TextSpan(
                  text: 'solicitud pendiente',
                  style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w500),
                ),
                const TextSpan(
                  text: ' nunca se modifican ni se eliminan: se muestran en la vista previa como excluidos.',
                ),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // 2. ¿Qué hacer con ellos?
  // ------------------------------------------------------------------

  Widget _buildActionCard(BuildContext context, BulkEditState state) {
    final scheme = Theme.of(context).colorScheme;

    Widget tile(BulkActionKind kind, String label, String hint) {
      final selected = state.actionKind == kind;
      final isDelete = kind == BulkActionKind.delete;
      final background = selected
          ? (isDelete ? scheme.errorContainer : scheme.secondaryContainer)
          : Colors.transparent;
      final foreground = selected
          ? (isDelete ? scheme.onErrorContainer : scheme.onSecondaryContainer)
          : scheme.onSurfaceVariant;
      return Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: selected ? BorderSide.none : BorderSide(color: scheme.outline),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _cubit.setActionKind(kind),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: foreground)),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: TextStyle(fontSize: 12, height: 16 / 12, color: foreground.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget note(String text, {double bottom = 12}) => Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Text(text, style: TextStyle(fontSize: 12, height: 16 / 12, color: scheme.onSurfaceVariant)),
        );

    Widget params;
    switch (state.actionKind) {
      case BulkActionKind.price:
        Widget modeParams;
        switch (state.priceMode) {
          case BulkPriceMode.fixed:
            modeParams = Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                BulkLabeledField(
                  label: 'Precio nuevo',
                  width: 200,
                  child: _ListeningField(
                    controller: _fixedPrice,
                    onChanged: (text) => _cubit.setFixedPrice(ThousandsFormat.parsePrice(text)),
                    child: PriceField(
                      controller: _fixedPrice,
                      decoration: bulkInputDecoration(context, prefixText: '\$ '),
                    ),
                  ),
                ),
                note('Mismo precio para todos los turnos alcanzados.'),
              ],
            );
          case BulkPriceMode.tariff:
            modeParams = BulkInfoBox(
              icon: Icons.sell_outlined,
              background: scheme.primaryContainer,
              foreground: scheme.onPrimaryContainer,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Cada turno toma el precio de la franja de su tarifa por horario según día y hora de inicio; '
                    'fuera de franja, el precio base de la cancha. Útil después de cambiar una tarifa. ',
                  ),
                  InkWell(
                    onTap: () {
                      final first = state.clubPartitionIds.firstOrNull;
                      if (first != null) openClubConfig(context, ClubConfigFocus.priceTariff(clubPartitionId: first));
                    },
                    child: Text(
                      'Ver tarifas',
                      style: TextStyle(color: scheme.primary, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            );
          case BulkPriceMode.adjust:
            modeParams = Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                BulkLabeledField(
                  label: 'Ajuste',
                  width: 140,
                  child: TextField(
                    controller: _percent,
                    style: const TextStyle(fontSize: 14),
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,+\-]'))],
                    decoration: bulkInputDecoration(context, suffixText: '%'),
                    onChanged: (text) => _cubit.setPercent(_parseSignedDouble(text)),
                  ),
                ),
                BulkLabeledField(
                  label: 'Redondear a',
                  width: 180,
                  child: _ListeningField(
                    controller: _roundTo,
                    onChanged: (text) => _cubit.setRoundTo(ThousandsFormat.parsePrice(text)),
                    child: PriceField(
                      controller: _roundTo,
                      decoration: bulkInputDecoration(context, prefixText: '\$ '),
                    ),
                  ),
                ),
                note('Sobre el precio actual de cada turno. Negativo para bajar.'),
              ],
            );
        }
        params = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(spacing: 8, runSpacing: 8, children: [
              BulkChoiceChip(
                label: 'Precio fijo',
                selected: state.priceMode == BulkPriceMode.fixed,
                onTap: () => _cubit.setPriceMode(BulkPriceMode.fixed),
              ),
              BulkChoiceChip(
                label: 'Recalcular por tarifa',
                selected: state.priceMode == BulkPriceMode.tariff,
                onTap: () => _cubit.setPriceMode(BulkPriceMode.tariff),
              ),
              BulkChoiceChip(
                label: 'Ajustar %',
                selected: state.priceMode == BulkPriceMode.adjust,
                onTap: () => _cubit.setPriceMode(BulkPriceMode.adjust),
              ),
            ]),
            const SizedBox(height: 12),
            modeParams,
          ],
        );
      case BulkActionKind.duration:
        params = Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            BulkLabeledField(
              label: 'Duración nueva (min)',
              width: 200,
              child: _ListeningField(
                controller: _duration,
                onChanged: (text) => _cubit.setDuration(int.tryParse(text.trim())),
                child: DurationMinutesField(controller: _duration, decoration: bulkInputDecoration(context)),
              ),
            ),
            note(
              'Si la nueva duración pisa el turno siguiente de la misma cancha, ese turno queda excluido.',
              bottom: 28,
            ),
          ],
        );
      case BulkActionKind.shift:
        params = Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            BulkLabeledField(
              label: 'Mover el inicio',
              width: 200,
              child: TextField(
                controller: _shift,
                style: const TextStyle(fontSize: 14),
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-]'))],
                decoration: bulkInputDecoration(context, suffixText: 'min'),
                onChanged: (text) => _cubit.setShiftMinutes(_parseSignedInt(text)),
              ),
            ),
            note('Los que se superpongan con otro turno quedan excluidos.'),
          ],
        );
      case BulkActionKind.delete:
        params = BulkInfoBox(
          icon: Icons.warning_amber_rounded,
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
          child: const Text(
            'Los turnos libres alcanzados se borran definitivamente. Antes de aplicar se pide confirmación.',
          ),
        );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BulkCardHeader(
              title: '2. ¿Qué hacer con ellos?',
              subtitle: 'Elegí una acción; la vista previa se actualiza al instante.',
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tile(BulkActionKind.price, 'Cambiar precio', 'Fijo, por tarifa o %')),
                  const SizedBox(width: 8),
                  Expanded(child: tile(BulkActionKind.duration, 'Cambiar duración', 'Minutos por turno')),
                  const SizedBox(width: 8),
                  Expanded(child: tile(BulkActionKind.shift, 'Mover horario', 'Correr el inicio')),
                  const SizedBox(width: 8),
                  Expanded(child: tile(BulkActionKind.delete, 'Eliminar', 'Solo turnos libres')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            params,
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // 3. Vista previa
  // ------------------------------------------------------------------

  Widget _buildPreviewCard(BuildContext context, BulkEditState state, BulkEditTexts texts) {
    final scheme = Theme.of(context).colorScheme;
    final preview = state.preview;
    final isDelete = state.actionKind == BulkActionKind.delete;

    Widget message(String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(text,
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
          ),
        );

    Widget body;
    if (!state.canPreview) {
      body = message(texts.missingRequirement ?? '');
    } else if (state.previewError != null && preview == null) {
      body = Column(children: [
        message(state.previewError!),
        TextButton(onPressed: _cubit.refreshPreview, child: const Text('Reintentar')),
      ]);
    } else if (preview == null) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (preview.matched == 0) {
      body = message('Ningún turno coincide con estas reglas.');
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final table = AdminDataTable(
              cellFontSize: 14,
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1.1),
                2: FlexColumnWidth(1.3),
                3: FlexColumnWidth(1.4),
                4: FlexColumnWidth(1.6),
              },
              columns: ['Fecha', 'Horario', 'Cancha', texts.valueColumn, 'Resultado'],
              rowTextColors: [for (final row in preview.rows) row.result.isExcluded ? scheme.outline : null],
              rows: [for (final row in preview.rows) _previewCells(context, state, texts, row)],
              // Todos los turnos, con scroll propio y el encabezado fijo.
              maxBodyHeight: 480,
            );
            // Tabla ancha: mínimo 720px y scroll horizontal en angosto.
            if (constraints.maxWidth >= 720) return table;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: 720, child: table),
            );
          }),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                state.view == BulkPreviewView.excluded
                    ? 'Mostrando los ${preview.totalRows} turnos excluidos'
                    : 'Mostrando los ${preview.totalRows} turnos',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              Wrap(spacing: 8, children: [
                _linkButton('Ver solo excluidos',
                    preview.excluded.total == 0 || state.view == BulkPreviewView.excluded ? null : _cubit.showExcluded),
                _linkButton('Ver todos', state.view == BulkPreviewView.all ? null : _cubit.showAllRows),
              ]),
            ],
          ),
        ],
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('3. Vista previa',
                        style: TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w500)),
                    if (state.isLoadingPreview && preview != null) ...[
                      const SizedBox(width: 12),
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ],
                ),
                if (preview != null && state.canPreview)
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    BulkSummaryChip(count: preview.matched, label: 'coinciden', outlined: true),
                    BulkSummaryChip(
                      count: preview.affected,
                      label: isDelete ? 'se eliminan' : 'se modifican',
                      background: scheme.primaryContainer,
                      foreground: scheme.onPrimaryContainer,
                    ),
                    BulkSummaryChip(
                      count: preview.excluded.protectedTotal,
                      label: 'excluidos',
                      background: scheme.surfaceContainerHighest,
                      foreground: scheme.onSurfaceVariant,
                    ),
                    if (preview.excluded.unchanged > 0)
                      BulkSummaryChip(
                        count: preview.excluded.unchanged,
                        label: 'sin cambios',
                        background: scheme.surfaceContainerHighest,
                        foreground: scheme.onSurfaceVariant,
                      ),
                  ]),
              ],
            ),
            const SizedBox(height: 16),
            body,
          ],
        ),
      ),
    );
  }

  Widget _linkButton(String label, VoidCallback? onPressed) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: bulkButtonTextStyle(context),
        ),
        child: Text(label),
      );

  List<Widget> _previewCells(BuildContext context, BulkEditState state, BulkEditTexts texts, BulkPreviewRow row) {
    final scheme = Theme.of(context).colorScheme;
    final excluded = row.result.isExcluded;
    final isDelete = state.actionKind == BulkActionKind.delete;
    final (before, after) = texts.valueChange(row);

    final Widget badge;
    if (excluded) {
      badge = BulkStatusBadge(
        text: BulkEditTexts.excludedLabel(row.result),
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
      );
    } else if (isDelete) {
      badge = BulkStatusBadge(
        text: 'Se elimina',
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
        bold: true,
      );
    } else {
      badge = BulkStatusBadge(
        text: 'Se modifica',
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
        bold: true,
      );
    }

    return [
      Text(texts.rowDate(row)),
      Text(texts.rowHours(row.startTime, row.duration)),
      Text(texts.courtLabel(row.partitionPhysicalId)),
      Text.rich(TextSpan(children: [
        TextSpan(
          text: before,
          style: !excluded && isDelete
              ? TextStyle(decoration: TextDecoration.lineThrough, color: scheme.onSurfaceVariant)
              : null,
        ),
        if (!excluded && after != null) ...[
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.arrow_forward, size: 14, color: scheme.onSurfaceVariant),
            ),
          ),
          TextSpan(text: after, style: TextStyle(fontWeight: FontWeight.w500, color: scheme.primary)),
        ],
      ])),
      Align(alignment: Alignment.centerLeft, child: badge),
    ];
  }

  // ------------------------------------------------------------------
  // Barra inferior fija
  // ------------------------------------------------------------------

  Widget _buildFooter(BuildContext context, BulkEditState state, BulkEditTexts texts, ColorScheme scheme) {
    final isDelete = state.actionKind == BulkActionKind.delete;
    final affected = state.preview?.affected ?? 0;
    final onApply = state.canApply ? () => _apply(state, texts) : null;

    final Widget applyButton = isDelete
        ? FilledButton.icon(
            onPressed: onApply,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              textStyle: bulkButtonTextStyle(context),
            ),
            icon: _buttonIcon(state, Icons.delete_outline, scheme.onError),
            label: Text('Eliminar $affected turnos'),
          )
        : FilledButton.icon(
            onPressed: onApply,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              textStyle: bulkButtonTextStyle(context),
            ),
            icon: _buttonIcon(state, Icons.check, scheme.onPrimary),
            label: Text('Aplicar a $affected turnos'),
          );

    // `width: infinity`: la barra ocupa todo el ancho (texto a la izquierda,
    // botones a la derecha); sin esto el Column la centraba al ancho del
    // contenido.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Text(texts.footer, style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.SESSION_MANAGER_ROUTE.path),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                foregroundColor: scheme.primary,
                textStyle: bulkButtonTextStyle(context),
              ),
              child: const Text('Cancelar'),
            ),
            applyButton,
          ]),
        ],
      ),
    );
  }

  Widget _buttonIcon(BulkEditState state, IconData icon, Color color) => state.isApplying
      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color))
      : Icon(icon, size: 18);
}

/// Llama a [onChanged] con cada cambio del [controller] (para campos como
/// `PriceField`/`TimeField`, que no exponen `onChanged`).
class _ListeningField extends StatefulWidget {
  const _ListeningField({required this.controller, required this.onChanged, required this.child});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Widget child;

  @override
  State<_ListeningField> createState() => _ListeningFieldState();
}

class _ListeningFieldState extends State<_ListeningField> {
  late String _last = widget.controller.text;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    final text = widget.controller.text;
    if (text == _last) return;
    _last = text;
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
