import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/gym/gym.dart';

/// Zonas del cuerpo de los filtros, en este orden (las que tenga el catálogo).
const _regionOrder = ['Piernas', 'Pecho', 'Espalda', 'Hombro', 'Brazos', 'Core'];

String _normalize(String text) => text
    .toLowerCase()
    .replaceAll(RegExp('[áà]'), 'a')
    .replaceAll(RegExp('[éè]'), 'e')
    .replaceAll(RegExp('[íì]'), 'i')
    .replaceAll(RegExp('[óò]'), 'o')
    .replaceAll(RegExp('[úùü]'), 'u');

/// Búsqueda sobre el catálogo: texto + zona del cuerpo, con los ejercicios que
/// ya hizo el cliente primero.
class _Search {
  _Search(this.exercises, this.query, this.region);

  final List<CatalogExercise> exercises;
  final String query;
  final String? region;

  List<String> get regions {
    final available = exercises.expand((e) => e.regions).toSet();
    return _regionOrder.where(available.contains).toList();
  }

  List<CatalogExercise> get results {
    final q = _normalize(query.trim());
    final filtered = exercises.where((e) {
      if (region != null && !e.regions.contains(region)) return false;
      if (q.isEmpty) return true;
      return _normalize(e.name).contains(q) || e.muscles.any((m) => _normalize(m.name).contains(q));
    }).toList();
    return [...filtered.where((e) => e.lastForClient != null), ...filtered.where((e) => e.lastForClient == null)];
  }

  bool get canCreate {
    final q = query.trim();
    return q.length >= 3 && !exercises.any((e) => _normalize(e.name) == _normalize(q));
  }
}

/// Filtros por zona + resultados en secciones ("Ya los hizo …", "Catálogo
/// del club") + crear. Lo usan el desplegable de desktop y el diálogo.
class _Results extends StatelessWidget {
  const _Results({
    required this.search,
    required this.clientFirstName,
    required this.highlighted,
    required this.creating,
    required this.onRegion,
    required this.onPick,
    required this.onCreate,
    this.shrinkWrap = false,
  });

  final _Search search;
  final String clientFirstName;
  final int highlighted;
  final bool creating;
  final ValueChanged<String?> onRegion;
  final ValueChanged<CatalogExercise> onPick;
  final VoidCallback onCreate;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final results = search.results;
    final withHistory = results.where((e) => e.lastForClient != null).length;

    Widget chip(String label, String? value) {
      final selected = search.region == value;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        visualDensity: VisualDensity.compact,
        labelStyle: textTheme.labelMedium,
        onSelected: (_) => onRegion(selected && value != null ? null : value),
      );
    }

    final list = <Widget>[
      for (final (index, exercise) in results.indexed) ...[
        if (index == 0 && withHistory > 0) _SectionLabel('Ya los hizo $clientFirstName'),
        if (index == withHistory) const _SectionLabel('Catálogo del club'),
        _ResultTile(
          exercise: exercise,
          clientFirstName: clientFirstName,
          highlighted: index == highlighted,
          onTap: () => onPick(exercise),
        ),
      ],
      if (results.isEmpty && !search.canCreate)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Nada coincide con "${search.query.trim()}".', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ),
      if (search.canCreate) ...[
        if (results.isNotEmpty) Divider(height: 1, color: colorScheme.outlineVariant),
        InkWell(
          onTap: creating ? null : onCreate,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                creating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.add, size: 18, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Crear "${search.query.trim()}" en el catálogo del club',
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ];

    return Column(
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [chip('Todos', null), for (final region in search.regions) chip(region, region)],
          ),
        ),
        Divider(height: 1, color: colorScheme.outlineVariant),
        if (shrinkWrap)
          Flexible(child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(vertical: 4), children: list))
        else
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 4), children: list)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, letterSpacing: 0.5),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.exercise, required this.clientFirstName, required this.highlighted, required this.onTap});

  final CatalogExercise exercise;
  final String clientFirstName;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final last = exercise.lastForClient;
    return Material(
      color: highlighted ? colorScheme.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(exercise.name, style: textTheme.titleSmall?.copyWith(color: highlighted ? colorScheme.onPrimaryContainer : null)),
                    if (exercise.muscles.isNotEmpty)
                      Text(
                        exercise.muscles.map((m) => m.name).join(' · '),
                        style: textTheme.bodySmall?.copyWith(color: highlighted ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                last != null ? 'Con $clientFirstName: ${seriesLabel(last)}' : (exercise.clubOwn ? 'Del club' : 'Nuevo para $clientFirstName'),
                style: textTheme.bodySmall?.copyWith(color: highlighted ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado común: texto, zona, resaltado y alta de un ejercicio nuevo.
mixin _PickerState<T extends StatefulWidget> on State<T> {
  final search = TextEditingController();
  final focus = FocusNode();
  String? region;
  int highlighted = 0;
  bool creating = false;
  late List<CatalogExercise> exercises;

  ExerciseCatalog get catalog;
  Future<CatalogExercise?> Function(String name) get createExercise;
  void picked(CatalogExercise exercise);

  _Search get current => _Search(exercises, search.text, region);

  @override
  void dispose() {
    search.dispose();
    focus.dispose();
    super.dispose();
  }

  void setRegion(String? value) => setState(() {
        region = value;
        highlighted = 0;
      });

  Future<void> create() async {
    final name = search.text.trim();
    setState(() => creating = true);
    final created = await createExercise(name);
    if (!mounted) return;
    setState(() => creating = false);
    if (created == null) return;
    exercises = [...exercises, created]..sort((a, b) => a.name.compareTo(b.name));
    picked(created);
  }

  void submit() {
    final results = current.results;
    if (results.isNotEmpty) {
      picked(results[highlighted.clamp(0, results.length - 1)]);
    } else if (current.canCreate) {
      create();
    }
  }

  KeyEventResult arrows(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final count = current.results.length;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown && count > 0) {
      setState(() => highlighted = (highlighted + 1) % count);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp && count > 0) {
      setState(() => highlighted = (highlighted - 1 + count) % count);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

/// Campo "Agregar ejercicio" de desktop: al escribir se despliega la lista
/// debajo, y lo que se elige se suma a la grilla sin cerrar el desplegable
/// (para agregar varios seguidos). Esc o un clic afuera lo cierran.
class InlineExerciseSearch extends StatefulWidget {
  const InlineExerciseSearch({
    super.key,
    required this.catalog,
    required this.clientFirstName,
    required this.onPick,
    required this.onCreate,
  });

  final ExerciseCatalog catalog;
  final String clientFirstName;
  final ValueChanged<CatalogExercise> onPick;
  final Future<CatalogExercise?> Function(String name) onCreate;

  @override
  State<InlineExerciseSearch> createState() => _InlineExerciseSearchState();
}

class _InlineExerciseSearchState extends State<InlineExerciseSearch> with _PickerState<InlineExerciseSearch> {
  final _overlay = OverlayPortalController();
  final _link = LayerLink();
  double _width = 400;

  @override
  ExerciseCatalog get catalog => widget.catalog;

  @override
  Future<CatalogExercise?> Function(String name) get createExercise => widget.onCreate;

  @override
  void initState() {
    super.initState();
    exercises = widget.catalog.exercises;
    focus.addListener(() {
      if (focus.hasFocus) {
        _overlay.show();
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant InlineExerciseSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.catalog != widget.catalog) exercises = widget.catalog.exercises;
  }

  @override
  void picked(CatalogExercise exercise) {
    widget.onPick(exercise);
    setState(() {
      search.clear();
      highlighted = 0;
    });
    focus.requestFocus();
  }

  void _close() {
    _overlay.hide();
    focus.unfocus();
    setState(() => search.clear());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final open = focus.hasFocus;

    return TapRegion(
      groupId: this,
      onTapOutside: (_) => _close(),
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: (context) => CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomLeft,
          offset: const Offset(0, 6),
          child: Align(
            alignment: Alignment.topLeft,
            child: TapRegion(
              groupId: this,
              child: SizedBox(
                width: _width,
                child: Material(
                  elevation: 8,
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: _Results(
                      search: current,
                      clientFirstName: widget.clientFirstName,
                      highlighted: highlighted,
                      creating: creating,
                      shrinkWrap: true,
                      onRegion: (value) {
                        setRegion(value);
                        focus.requestFocus();
                      },
                      onPick: picked,
                      onCreate: create,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          _width = constraints.maxWidth;
          return CompositedTransformTarget(
            link: _link,
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                  _close();
                  return KeyEventResult.handled;
                }
                return arrows(event);
              },
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: open ? colorScheme.primary : colorScheme.outlineVariant, width: open ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Icon(open ? Icons.search : Icons.add, size: 18, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: search,
                        focusNode: focus,
                        onChanged: (_) => setState(() => highlighted = 0),
                        onSubmitted: (_) {
                          submit();
                          focus.requestFocus();
                        },
                        style: textTheme.bodyMedium,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: open ? 'Escribí el nombre del ejercicio' : 'Agregar ejercicio: escribí el nombre…',
                        ),
                      ),
                    ),
                    Text(
                      open ? '↑↓ elegir · Enter agregar · Esc cerrar' : '',
                      style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    if (!open) _KeyHint(color: colorScheme.outlineVariant),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _KeyHint extends StatelessWidget {
  const _KeyHint({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: color)),
      child: Text('Enter', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

/// Buscador en diálogo: en el teléfono (pantalla completa) y para cambiar el
/// ejercicio de una fila. [multiple]: queda abierto para agregar varios.
Future<void> showExercisePicker(
  BuildContext context, {
  required String title,
  required ExerciseCatalog catalog,
  required String clientFirstName,
  required bool multiple,
  required bool fullScreen,
  required void Function(CatalogExercise exercise) onPick,
  required Future<CatalogExercise?> Function(String name) onCreate,
}) {
  final picker = _DialogPicker(
    title: title,
    catalog: catalog,
    clientFirstName: clientFirstName,
    multiple: multiple,
    onPick: onPick,
    onCreate: onCreate,
  );
  if (fullScreen) {
    return showDialog<void>(context: context, builder: (_) => Dialog.fullscreen(child: picker));
  }
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600, maxHeight: 640), child: picker),
    ),
  );
}

class _DialogPicker extends StatefulWidget {
  const _DialogPicker({
    required this.title,
    required this.catalog,
    required this.clientFirstName,
    required this.multiple,
    required this.onPick,
    required this.onCreate,
  });

  final String title;
  final ExerciseCatalog catalog;
  final String clientFirstName;
  final bool multiple;
  final void Function(CatalogExercise exercise) onPick;
  final Future<CatalogExercise?> Function(String name) onCreate;

  @override
  State<_DialogPicker> createState() => _DialogPickerState();
}

class _DialogPickerState extends State<_DialogPicker> with _PickerState<_DialogPicker> {
  final List<String> _added = [];

  @override
  ExerciseCatalog get catalog => widget.catalog;

  @override
  Future<CatalogExercise?> Function(String name) get createExercise => widget.onCreate;

  @override
  void initState() {
    super.initState();
    exercises = widget.catalog.exercises;
  }

  @override
  void picked(CatalogExercise exercise) {
    widget.onPick(exercise);
    if (!widget.multiple) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _added.add(exercise.name);
      search.clear();
      highlighted = 0;
    });
    focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: colorScheme.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(child: Text(widget.title, style: textTheme.titleMedium)),
                IconButton(tooltip: 'Cerrar', icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Focus(
              onKeyEvent: (node, event) => arrows(event),
              child: TextField(
                controller: search,
                focusNode: focus,
                autofocus: true,
                onChanged: (_) => setState(() => highlighted = 0),
                onSubmitted: (_) {
                  submit();
                  focus.requestFocus();
                },
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Escribí el nombre del ejercicio',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _Results(
              search: current,
              clientFirstName: widget.clientFirstName,
              highlighted: highlighted,
              creating: creating,
              onRegion: setRegion,
              onPick: picked,
              onCreate: create,
            ),
          ),
          if (widget.multiple) ...[
            Divider(height: 1, color: colorScheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _added.isEmpty ? 'Elegí uno o más ejercicios.' : 'Agregaste ${_added.length}: ${_added.join(', ')}',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Listo')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
