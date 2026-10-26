import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/gym/gym.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../../../domain/entities/gym/gym_progress.dart';
import '../../../domain/repositories/gym_repository.dart';
import 'routine_draft.dart';
import 'widgets/copy_panel.dart';
import 'widgets/exercise_picker.dart';
import 'widgets/group_card.dart';
import 'widgets/mobile_editor.dart' show MobileGroupTabs, MobileRoutineEditor;
import 'widgets/start_chooser.dart';
import '../../../core/presentation/components/onboarding/tour_anchor.dart';

/// Editor de rutinas de un cliente. Sin [editRoutineId] arranca eligiendo de
/// dónde partir (copiar su rutina actual, otra de base o de cero); con
/// [editRoutineId] edita esa rutina conservando su historial.
///
/// Al guardar vuelve a la ficha con `true` (para que recargue la card).
class RoutineEditorPage extends StatefulWidget {
  const RoutineEditorPage({super.key, required this.clientId, this.client, this.editRoutineId});

  final int clientId;
  final Client? client;
  final String? editRoutineId;

  @override
  State<RoutineEditorPage> createState() => _RoutineEditorPageState();
}

class _RoutineEditorPageState extends State<RoutineEditorPage> {
  final _repository = sl<GymRepository>();
  bool _loading = true;
  String? _error;
  String _clientName = 'Cliente';
  List<Routine> _clientRoutines = const [];
  List<Routine> _recentRoutines = const [];
  ExerciseCatalog _catalog = const ExerciseCatalog(exercises: [], muscles: []);
  RoutineDraft? _draft;
  bool _saving = false;

  /// Micro-progresos de la rutina que se edita: lo que hizo el cliente de cada ejercicio.
  RoutineProgress? _progress;

  String get _firstName => _clientName.split(' ').first;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _draft?.removeListener(_onDraftChanged);
    _draft?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final name = widget.client?.person?.fullName;
    final routinesCall = _repository.routines(widget.clientId);
    final recentCall = _repository.recentRoutines();
    final catalogCall = _repository.catalog(clientId: widget.clientId);
    final clientCall = name == null ? sl<AdminRepository>().getClientById(widget.clientId) : null;
    final progressCall = widget.editRoutineId == null ? null : _repository.progress(widget.editRoutineId!);

    String? error;
    T? valueOf<T>(Either<DomainError, T> result) => result.when(
          left: (failure) {
            error ??= failure.message;
            return null;
          },
          right: (value) => value,
        );

    final routines = valueOf(await routinesCall);
    final recent = valueOf(await recentCall);
    final catalog = valueOf(await catalogCall);
    final client = clientCall == null ? null : valueOf(await clientCall);
    // Sin progreso el editor funciona igual: no es un error de carga.
    final progress = progressCall == null ? null : (await progressCall).when(left: (_) => null, right: (value) => value);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _error = routines == null || catalog == null ? (error ?? 'No pudimos cargar las rutinas.') : null;
      _clientRoutines = routines ?? const [];
      _recentRoutines = recent ?? const [];
      _catalog = catalog ?? _catalog;
      _clientName = (name ?? client?.person?.fullName ?? 'Cliente').trim();
      _progress = progress;
      if (widget.editRoutineId != null && routines != null) {
        final routine = routines.where((r) => r.id == widget.editRoutineId).firstOrNull;
        if (routine != null) _setDraft(RoutineDraft.edit(routine));
      }
    });
  }

  void _setDraft(RoutineDraft draft) {
    _draft?.removeListener(_onDraftChanged);
    _draft?.dispose();
    _draft = draft..addListener(_onDraftChanged);
  }

  void _onDraftChanged() {
    final draft = _draft;
    if (draft == null) return;
    setState(() {});
    final label = draft.undoLabel;
    if (label != null) {
      draft.undoLabel = null;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Reemplazaste la rutina por una copia de $label.'),
          action: SnackBarAction(label: 'Deshacer', onPressed: draft.undo),
          duration: const Duration(seconds: 8),
        ));
    }
  }

  Future<bool> _confirmDiscard() async {
    final draft = _draft;
    if (draft == null || !draft.dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar los cambios?'),
        content: const Text('La rutina no se guardó.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Seguir editando')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _close() async {
    if (await _confirmDiscard() && mounted) context.pop();
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final problem = draft.validate();
    if (problem != null) {
      SnackbarsFunctions.showErrorsSnackbar(context, problem);
      return;
    }
    setState(() => _saving = true);
    final result = draft.routineId == null
        ? await _repository.createRoutine(widget.clientId, draft.toJson())
        : await _repository.updateRoutine(draft.routineId!, draft.toJson());
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Right():
        SnackbarsFunctions.showSuccessSnackbar(context, draft.routineId == null ? 'Rutina guardada. $_firstName ya la ve en la app.' : 'Rutina actualizada.');
        context.pop(true);
      case Left(:final failure):
        SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
    }
  }

  Future<CatalogExercise?> _createExercise(String name) async {
    final result = await _repository.createExercise(name, const []);
    switch (result) {
      case Right(:final value):
        _catalog = ExerciseCatalog(exercises: [..._catalog.exercises, value], muscles: _catalog.muscles);
        return value;
      case Left(:final failure):
        if (mounted) SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
        return null;
    }
  }

  void _addExercises(DraftGroup group) {
    final draft = _draft!;
    draft.setTarget(group.key);
    showExercisePicker(
      context,
      title: 'Agregar a ${group.name.trim().isEmpty ? 'este grupo' : group.name}',
      catalog: _catalog,
      clientFirstName: _firstName,
      multiple: true,
      fullScreen: true,
      onPick: (exercise) => draft.addExercise(DraftExercise.fromCatalog(exercise), into: group),
      onCreate: _createExercise,
    );
  }

  void _changeExercise(DraftExercise exercise) {
    showExercisePicker(
      context,
      title: 'Cambiar ${exercise.name}',
      catalog: _catalog,
      clientFirstName: _firstName,
      multiple: false,
      fullScreen: ResponsiveBuilder.isMobile(context),
      onPick: (picked) => _draft!.replaceExercise(exercise, picked),
      onCreate: _createExercise,
    );
  }

  Future<void> _pickStartDate() async {
    final draft = _draft!;
    final date = await showDatePicker(
      context: context,
      initialDate: draft.startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) draft.setStartDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final draft = _draft;
    final mobile = ResponsiveBuilder.isMobile(context);
    final title = widget.editRoutineId != null ? 'Editar rutina' : 'Nueva rutina';

    return PopScope(
      canPop: draft == null || !draft.dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmDiscard() && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
          leading: IconButton(tooltip: 'Volver a la ficha', icon: const Icon(Icons.arrow_back), onPressed: _close),
          titleSpacing: 0,
          title: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    if (draft != null)
                      Text('$_clientName · ${_summary(draft)}', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                )
              : Row(
                  children: [
                    Text('Clientes', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Text('  ›  ', style: textTheme.titleMedium?.copyWith(color: colorScheme.outline)),
                    InkWell(onTap: _close, child: Text(_clientName, style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant))),
                    Text('  ›  ', style: textTheme.titleMedium?.copyWith(color: colorScheme.outline)),
                    Text(title, style: textTheme.titleMedium),
                  ],
                ),
          bottom: draft != null && mobile ? MobileGroupTabs(draft: draft) : null,
          actions: [
            if (draft != null && !mobile) ...[
              Center(
                child: Text('${_summary(draft)}${draft.dirty ? ' · Sin guardar' : ''}', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(width: 12),
              TextButton(onPressed: _close, child: const Text('Descartar')),
              const SizedBox(width: 8),
              TourAnchor(
                id: 'routine.save',
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
                  label: const Text('Guardar rutina'),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ],
        ),
        bottomNavigationBar: draft != null && mobile
            ? SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh, border: Border(top: BorderSide(color: colorScheme.outlineVariant))),
                  child: Row(
                    children: [
                      Expanded(
                        child: TourAnchor(
                          id: 'routine.copy',
                          child: OutlinedButton.icon(
                            onPressed: _openCopySheet,
                            icon: const Icon(Icons.copy_all_outlined),
                            label: const Text('Copiar de otra'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TourAnchor(
                          id: 'routine.save',
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            child: Text(_saving ? 'Guardando…' : 'Guardar rutina'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        body: _body(mobile),
      ),
    );
  }

  String _summary(RoutineDraft draft) {
    final groups = draft.groups.length == 1 ? '1 grupo' : '${draft.groups.length} grupos';
    final exercises = draft.exercisesCount == 1 ? '1 ejercicio' : '${draft.exercisesCount} ejercicios';
    return '$groups · $exercises';
  }

  Widget _body(bool mobile) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
        ]),
      );
    }
    final draft = _draft;
    if (draft == null) {
      return TourAnchor(id: 'routine.start', child: StartChooser(
        clientId: widget.clientId,
        clientName: _clientName,
        clientRoutines: _clientRoutines,
        recentRoutines: _recentRoutines,
        onCopy: (routine) => setState(() => _setDraft(RoutineDraft.copyOf(routine))),
        onEmpty: (count) => setState(() => _setDraft(RoutineDraft.empty(count))),
      ));
    }

    if (mobile) {
      return TourAnchor(
        id: 'routine.groups',
        child: MobileRoutineEditor(
          draft: draft,
          header: _startDateBar(draft),
          onAddExercise: _addExercises,
          onChangeExercise: _changeExercise,
        ),
      );
    }

    final editor = ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 12, 48),
      children: [
        _startDateBar(draft),
        const SizedBox(height: 16),
        TourAnchor(id: 'routine.groups', child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: draft.groups.length,
          // onReorder da el índice destino sin corregir (cuenta el ítem que se
          // mueve): se corrige acá. onReorderItem no existe en Flutter 3.35.
          onReorder: (oldIndex, newIndex) => draft.moveGroup(oldIndex, newIndex > oldIndex ? newIndex - 1 : newIndex),
          itemBuilder: (context, index) {
            final group = draft.groups[index];
            return Padding(
              key: ValueKey(group.key),
              padding: const EdgeInsets.only(bottom: 16),
              child: GroupCard(
                draft: draft,
                group: group,
                index: index,
                showHelp: index == 0,
                addField: InlineExerciseSearch(
                  catalog: _catalog,
                  clientFirstName: _firstName,
                  onPick: (exercise) {
                    draft.setTarget(group.key);
                    draft.addExercise(DraftExercise.fromCatalog(exercise), into: group);
                  },
                  onCreate: _createExercise,
                ),
                onChangeExercise: _changeExercise,
                progress: _progress,
                clientFirstName: _firstName,
              ),
            );
          },
        )),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(onPressed: draft.addGroup, icon: const Icon(Icons.add), label: const Text('Agregar grupo')),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: editor),
        SizedBox(
          width: 440,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 24, 24, 24),
            child: TourAnchor(id: 'routine.copy', child: Card(
              margin: EdgeInsets.zero,
              child: CopyPanel(
                draft: draft,
                clientName: _clientName,
                clientRoutines: _clientRoutines,
                recentRoutines: _recentRoutines,
              ),
            )),
          ),
        ),
      ],
    );
  }

  Widget _startDateBar(RoutineDraft draft) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = _clientRoutines.where((r) => r.isActive).firstOrNull;
    final replaces = draft.routineId == null && active != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Arranca el', style: textTheme.titleSmall),
          InkWell(
            onTap: _pickStartDate,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: colorScheme.outline)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  '${draft.startDate.day.toString().padLeft(2, '0')}/${draft.startDate.month.toString().padLeft(2, '0')}/${draft.startDate.year}',
                  style: textTheme.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_outlined, size: 16, color: colorScheme.onSurfaceVariant),
              ]),
            ),
          ),
          Text(
            replaces
                ? 'Cuando guardes, la rutina actual de $_firstName (${routineMonthsLabel(active)}) pasa a anteriores. $_firstName ve la nueva en la app.'
                : (draft.routineId != null ? 'Los cambios le llegan a $_firstName al guardar. Lo que ya entrenó se conserva.' : '$_firstName la ve en la app cuando guardes.'),
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _openCopySheet() {
    final draft = _draft!;
    final doneLabel = ValueNotifier<String>('Listo');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            Expanded(
              child: CopyPanel(
                draft: draft,
                clientName: _clientName,
                clientRoutines: _clientRoutines,
                recentRoutines: _recentRoutines,
                showTargets: true,
                scrollController: scrollController,
                doneLabel: doneLabel,
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: ValueListenableBuilder<String>(valueListenable: doneLabel, builder: (context, label, child) => Text(label)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
