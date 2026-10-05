import 'package:flutter/material.dart';

import '../../../../domain/entities/club_map/club_map.dart';
import 'court_tile.dart';
import 'plan_canvas.dart';

/// Paso 2: ubicar las canchas en el plano. Las canchas se arrastran desde la
/// lista al plano (o se tocan para sumarlas) y dentro del plano se mueven,
/// se giran o se sacan.
class ClubMapEditor extends StatefulWidget {
  final ClubMapView view;
  final Set<int> partitionIds;
  final int initialWidthM;
  final int initialHeightM;
  final bool isNewMap;
  final VoidCallback onCancel;

  /// Devuelve el mensaje de error si no se pudo guardar.
  final Future<String?> Function(ClubMapLayout layout) onSave;

  const ClubMapEditor({
    super.key,
    required this.view,
    required this.partitionIds,
    required this.initialWidthM,
    required this.initialHeightM,
    required this.isNewMap,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<ClubMapEditor> createState() => _ClubMapEditorState();
}

class _ClubMapEditorState extends State<ClubMapEditor> {
  late List<ClubMapElement> _elements = [...?widget.view.map?.elements];
  late Set<int> _partitionIds = {...widget.partitionIds};
  late int _widthM = widget.initialWidthM;
  late int _heightM = widget.initialHeightM;
  int? _selectedId;
  bool _saving = false;

  final GlobalKey _planKey = GlobalKey();
  double _scale = 1;

  List<ClubMapPartition> get _groups => widget.view.partitions.where((p) => _partitionIds.contains(p.id) && p.courts.isNotEmpty).toList();

  List<ClubMapPartition> get _addable => widget.view.partitions.where((p) => !_partitionIds.contains(p.id) && p.courts.isNotEmpty).toList();

  bool _isPlaced(int courtId) => _elements.any((e) => e.courtId == courtId);

  void _place(int courtId, {Offset? centerM}) {
    if (_isPlaced(courtId)) return;
    final found = widget.view.findCourt(courtId);
    if (found == null) return;

    final size = found.partition.courtSize;
    final fp = courtFootprint(size, false);
    final pos = centerM == null ? firstFreeSpot(widget.view, _elements, size, _widthM, _heightM) : clampToPlot(centerM.dx - fp.w / 2, centerM.dy - fp.h / 2, fp.w, fp.h, _widthM, _heightM);

    setState(() {
      _elements = [..._elements, ClubMapElement(courtId: courtId, xM: pos.x, yM: pos.y)];
      _selectedId = courtId;
    });
  }

  void _move(int courtId, int x, int y) {
    setState(() {
      _elements = [for (final e in _elements) e.courtId == courtId ? e.copyWith(xM: x, yM: y) : e];
    });
  }

  /// Gira 90° sobre su centro, sin salirse del predio.
  void _rotateSelected() {
    final id = _selectedId;
    if (id == null) return;
    setState(() {
      _elements = [
        for (final e in _elements)
          if (e.courtId != id)
            e
          else
            () {
              final size = widget.view.findCourt(id)!.partition.courtSize;
              final before = courtFootprint(size, e.rotated);
              final after = courtFootprint(size, !e.rotated);
              final cx = e.xM + before.w / 2, cy = e.yM + before.h / 2;
              final pos = clampToPlot(cx - after.w / 2, cy - after.h / 2, after.w, after.h, _widthM, _heightM);
              return e.copyWith(xM: pos.x, yM: pos.y, rotated: !e.rotated);
            }(),
      ];
    });
  }

  void _removeSelected() {
    setState(() {
      _elements = _elements.where((e) => e.courtId != _selectedId).toList();
      _selectedId = null;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await widget.onSave(ClubMapLayout(widthM: _widthM, heightM: _heightM, elements: _elements));
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final issues = findIssues(widget.view, _elements, _widthM, _heightM);
    final canSave = !_saving && _elements.isNotEmpty && issues.isEmpty;

    final header = SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 16,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.isNewMap ? 'PASO 2 DE 2' : 'EDITANDO EL PLANO', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('Plano del club', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Arrastrá cada cancha a su lugar. La cuadrícula está a escala: cada cuadro chico es 1 m.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: _saving ? null : widget.onCancel, child: const Text('Cancelar')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: canSave ? _save : null,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
                label: const Text('Guardar plano'),
              ),
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 20),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 800;
                final palette = _buildPalette(context, horizontal: narrow);
                final plan = _buildPlanArea(context, issues);

                if (narrow) {
                  return Column(
                    children: [
                      SizedBox(height: 132, child: palette),
                      const SizedBox(height: 12),
                      Expanded(child: plan),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 280, child: palette),
                    const SizedBox(width: 24),
                    Expanded(child: plan),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPalette(BuildContext context, {required bool horizontal}) {
    final theme = Theme.of(context);
    final total = _groups.fold<int>(0, (sum, p) => sum + p.courts.length);
    final placed = _elements.where((e) => _groups.any((p) => p.courts.any((c) => c.id == e.courtId))).length;

    final children = <Widget>[
      Row(
        children: [
          Expanded(child: Text('Canchas', style: theme.textTheme.titleMedium)),
          Text('$placed de $total en el plano', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
      for (final partition in _groups) ...[
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: SportStyle.of(partition.clubTypeId).fill, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text('${partition.sport} · ${partition.courtSize.label}', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        for (final court in partition.courts) ...[const SizedBox(height: 8), _PaletteCourt(partition: partition, court: court, placed: _isPlaced(court.id), onTap: () => _place(court.id))],
      ],
      for (final partition in _addable) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () => setState(() => _partitionIds = {..._partitionIds, partition.id}), icon: const Icon(Icons.add), label: Text('Sumar ${partition.sport} al plano')),
      ],
      const SizedBox(height: 12),
      Text('Arrastrá una cancha al plano o tocala para sumarla. Ya en el plano, arrastrala para moverla.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ];

    if (horizontal) {
      // En pantallas angostas: los grupos en una fila que se desliza.
      return ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final partition in _groups)
            for (final court in partition.courts)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 220,
                  child: _PaletteCourt(partition: partition, court: court, placed: _isPlaced(court.id), onTap: () => _place(court.id)),
                ),
              ),
          for (final partition in _addable)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: OutlinedButton.icon(onPressed: () => setState(() => _partitionIds = {..._partitionIds, partition.id}), icon: const Icon(Icons.add), label: Text('Sumar ${partition.sport}')),
              ),
            ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _buildPlanArea(BuildContext context, ClubMapIssues issues) {
    final theme = Theme.of(context);
    final selected = _selectedId == null ? null : widget.view.findCourt(_selectedId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
          child: selected == null || !_isPlaced(_selectedId!)
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tocá una cancha del plano para girarla o sacarla.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('${selected.partition.sport} · ${selected.court.name}', style: theme.textTheme.titleSmall),
                    OutlinedButton.icon(onPressed: _rotateSelected, icon: const Icon(Icons.rotate_right), label: const Text('Girar 90°')),
                    OutlinedButton.icon(
                      onPressed: _removeSelected,
                      icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                      label: Text('Sacar del plano', style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        _SizeSelector(
          widthM: _widthM,
          heightM: _heightM,
          onChanged: (preset) => setState(() {
            _widthM = preset.widthM;
            _heightM = preset.heightM;
          }),
        ),
        if (issues.outside.isNotEmpty) ...[const SizedBox(height: 10), const _IssueBanner('Con este tamaño, algunas canchas quedan afuera del predio. Movelas o elegí un predio más grande.')],
        if (issues.overlapping.isNotEmpty) ...[const SizedBox(height: 10), const _IssueBanner('Hay canchas encimadas. Separalas para poder guardar.')],
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _scale = planScale(_widthM, _heightM, constraints.maxWidth - 34, constraints.maxHeight - 64);
              if (_scale <= 0) return const SizedBox.shrink();

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DragTarget<int>(
                        onWillAcceptWithDetails: (details) => !_isPlaced(details.data),
                        onAcceptWithDetails: (details) {
                          final box = _planKey.currentContext?.findRenderObject() as RenderBox?;
                          if (box == null) return _place(details.data);
                          final local = box.globalToLocal(details.offset + _PaletteCourt.feedbackCenter);
                          _place(details.data, centerM: local / _scale);
                        },
                        builder: (context, candidates, rejected) {
                          return Container(
                            key: _planKey,
                            foregroundDecoration: candidates.isNotEmpty ? BoxDecoration(border: Border.all(color: theme.colorScheme.primary, width: 2)) : null,
                            child: Stack(
                              children: [
                                PlanCanvas(
                                  view: widget.view,
                                  widthM: _widthM,
                                  heightM: _heightM,
                                  elements: _elements,
                                  scale: _scale,
                                  selectedCourtId: _selectedId,
                                  issues: issues,
                                  onCourtTap: (id) => setState(() => _selectedId = id),
                                  onCourtMoved: _move,
                                  onBackgroundTap: () => setState(() => _selectedId = null),
                                ),
                                if (_elements.isEmpty)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(8)),
                                          // El predio es siempre claro: el texto no sigue el tema.
                                          child: const Text('Arrastrá acá la primera cancha', style: TextStyle(color: Color(0xFF49454F))),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    PlanScaleLegend(scale: _scale, widthM: _widthM, heightM: _heightM),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Cancha en la lista lateral: se arrastra al plano o se toca para sumarla.
class _PaletteCourt extends StatelessWidget {
  final ClubMapPartition partition;
  final ClubMapCourt court;
  final bool placed;
  final VoidCallback onTap;

  static const feedbackSize = Size(180, 48);
  static Offset get feedbackCenter => Offset(feedbackSize.width / 2, feedbackSize.height / 2);

  const _PaletteCourt({required this.partition, required this.court, required this.placed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = SportStyle.of(partition.clubTypeId);
    final placedColor = theme.brightness == Brightness.dark ? const Color(0xFF8FD19E) : const Color(0xFF1B5E2B);
    final wide = partition.courtSize.lengthM >= partition.courtSize.widthM;

    final swatch = Container(
      width: wide ? 34 : 18,
      height: wide ? 20 : 34,
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: court.isCover ? const Color(0xFF2B2440) : Colors.white, width: 2),
      ),
      child: court.isCover ? const CustomPaint(painter: RoofStripesPainter()) : null,
    );

    final content = Row(
      children: [
        swatch,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(court.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                '${court.isCover ? 'Techada' : 'Descubierta'}${court.maxPlayers != null ? ' · ${court.maxPlayers} jugadores' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (placed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 16, color: placedColor),
              const SizedBox(width: 4),
              Text(
                'En el plano',
                style: TextStyle(fontSize: 12, color: placedColor, fontWeight: FontWeight.w500),
              ),
            ],
          )
        else
          Icon(Icons.drag_indicator, color: theme.colorScheme.outline),
      ],
    );

    final card = Material(
      color: placed ? theme.colorScheme.surfaceContainerLow : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: placed ? null : onTap,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: content),
      ),
    );

    if (placed) return Semantics(label: '${court.name}, ya está en el plano', child: card);

    return Semantics(
      button: true,
      label: 'Sumar ${court.name} al plano',
      child: Draggable<int>(
        data: court.id,
        feedback: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: feedbackSize.width,
            height: feedbackSize.height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                swatch,
                const SizedBox(width: 10),
                Expanded(
                  child: Text(court.name, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: card),
        child: MouseRegion(cursor: SystemMouseCursors.grab, child: card),
      ),
    );
  }
}

class _SizeSelector extends StatelessWidget {
  final int widthM;
  final int heightM;
  final ValueChanged<ClubMapSizePreset> onChanged;

  const _SizeSelector({required this.widthM, required this.heightM, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final current = ClubMapSizePreset.match(widthM, heightM);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Tamaño del predio:', style: Theme.of(context).textTheme.bodyMedium),
        SegmentedButton<String>(
          showSelectedIcon: false,
          emptySelectionAllowed: current == null,
          segments: [for (final preset in ClubMapSizePreset.all) ButtonSegment(value: preset.id, label: Text('${preset.name} · ${preset.widthM}×${preset.heightM} m'))],
          selected: {if (current != null) current.id},
          onSelectionChanged: (ids) {
            if (ids.isEmpty) return;
            onChanged(ClubMapSizePreset.all.firstWhere((p) => p.id == ids.first));
          },
        ),
        if (current == null) Text('(actual: $widthM × $heightM m)', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _IssueBanner extends StatelessWidget {
  final String text;

  const _IssueBanner(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: colors.errorContainer, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: TextStyle(color: colors.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }
}
