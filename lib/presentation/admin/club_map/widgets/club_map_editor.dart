import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/club_map/club_map.dart';
import 'court_tile.dart';
import 'plan_canvas.dart';

/// Paso 2: ubicar las canchas en el plano. Las canchas se arrastran desde la
/// lista al plano (o se tocan para sumarlas) y dentro del plano se mueven,
/// se giran, se sacan o se les cambia la medida. También se suman espacios
/// que no son canchas (entrada, vestuarios, bar, la calle de referencia...) y
/// caminos entre canchas y espacios.
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
  /// La vista con las medidas propias que se van editando.
  late ClubMapView _view = widget.view;
  late List<ClubMapElement> _elements = [...?widget.view.map?.elements];
  late List<ClubMapSpace> _spaces = [...?widget.view.map?.spaces];
  late List<ClubMapConnection> _connections = [...?widget.view.map?.connections];

  /// "Conectar con…": el próximo toque en el plano une este elemento con el
  /// tocado (o saca el camino, si ya estaban unidos).
  ClubMapNodeRef? _connectingFrom;
  late Set<int> _partitionIds = {...widget.partitionIds};
  late int _widthM = widget.initialWidthM;
  late int _heightM = widget.initialHeightM;
  int? _selectedId;
  int? _selectedSpace;
  bool _saving = false;

  final GlobalKey _planKey = GlobalKey();
  double _scale = 1;

  List<ClubMapPartition> get _groups => widget.view.partitions.where((p) => _partitionIds.contains(p.id) && p.courts.isNotEmpty).toList();

  List<ClubMapPartition> get _addable => widget.view.partitions.where((p) => !_partitionIds.contains(p.id) && p.courts.isNotEmpty).toList();

  bool _isPlaced(int courtId) => _elements.any((e) => e.courtId == courtId);

  void _place(int courtId, {Offset? centerM}) {
    if (_isPlaced(courtId)) return;
    if (_view.findCourt(courtId) == null) return;

    final fp = courtFootprint(_view.courtSizeOf(courtId), false);
    final pos = centerM == null
        ? firstFreeSpot(_view, _elements, fp.w, fp.h, _widthM, _heightM, spaces: _spaces)
        : clampToPlot(centerM.dx - fp.w / 2, centerM.dy - fp.h / 2, fp.w, fp.h, _widthM, _heightM);

    setState(() {
      _elements = [..._elements, ClubMapElement(courtId: courtId, xM: pos.x, yM: pos.y)];
      _selectCourt(courtId);
    });
  }

  void _selectCourt(int? id) {
    _selectedId = id;
    _selectedSpace = null;
  }

  void _selectSpace(int? index) {
    _selectedSpace = index;
    _selectedId = null;
  }

  ClubMapNodeRef? get _selectedNode => _selectedId != null
      ? ClubMapNodeRef.court(_selectedId!)
      : (_selectedSpace != null ? ClubMapNodeRef.space(_selectedSpace!) : null);

  String _nodeName(ClubMapNodeRef ref) {
    if (ref.spaceIndex != null) return _view.spaceName(_spaces[ref.spaceIndex!]);
    final found = _view.findCourt(ref.courtId!);
    return found == null ? 'Cancha' : '${found.court.name} (${found.partition.sport})';
  }

  /// Un toque en una cancha o un espacio: en modo "Conectar con…" une (o
  /// desune) los dos elementos; si no, lo selecciona.
  void _tapNode(ClubMapNodeRef ref) {
    setState(() {
      final from = _connectingFrom;
      if (from != null && from != ref) {
        final exists = _connections.any((c) => c.joins(from, ref));
        _connections = exists
            ? _connections.where((c) => !c.joins(from, ref)).toList()
            : [..._connections, ClubMapConnection(from, ref)];
      }
      _connectingFrom = null;
      ref.courtId != null ? _selectCourt(ref.courtId) : _selectSpace(ref.spaceIndex);
    });
  }

  void _removeSelectedConnections() {
    final node = _selectedNode;
    if (node == null) return;
    setState(() => _connections = _connections.where((c) => !c.touches(node)).toList());
  }

  void _addSpace(ClubMapSpaceType type) {
    final pos = firstFreeSpot(_view, _elements, type.defaultWidthM.toDouble(), type.defaultHeightM.toDouble(), _widthM, _heightM, spaces: _spaces);
    setState(() {
      _spaces = [..._spaces, ClubMapSpace(type: type.type, xM: pos.x, yM: pos.y, widthM: type.defaultWidthM, heightM: type.defaultHeightM)];
      _selectSpace(_spaces.length - 1);
    });
  }

  void _moveSpace(int index, int x, int y) {
    setState(() {
      _spaces = [for (var i = 0; i < _spaces.length; i++) i == index ? _spaces[i].copyWith(xM: x, yM: y) : _spaces[i]];
    });
  }

  /// Gira 90° sobre su centro, sin salirse del predio.
  void _rotateSelectedSpace() {
    final index = _selectedSpace;
    if (index == null) return;
    final sp = _spaces[index];
    final cx = sp.xM + sp.widthM / 2, cy = sp.yM + sp.heightM / 2;
    final pos = clampToPlot(cx - sp.heightM / 2, cy - sp.widthM / 2, sp.heightM.toDouble(), sp.widthM.toDouble(), _widthM, _heightM);
    setState(() {
      _spaces = [
        for (var i = 0; i < _spaces.length; i++) i == index ? sp.copyWith(xM: pos.x, yM: pos.y, widthM: sp.heightM, heightM: sp.widthM) : _spaces[i],
      ];
    });
  }

  void _removeSelectedSpace() {
    setState(() {
      _connections = connectionsWithoutSpace(_connections, _selectedSpace!);
      _spaces = [
        for (var i = 0; i < _spaces.length; i++)
          if (i != _selectedSpace) _spaces[i],
      ];
      _selectedSpace = null;
    });
  }

  Future<void> _editSelectedSpace() async {
    final index = _selectedSpace;
    if (index == null) return;
    final edited = await showDialog<ClubMapSpace>(
      context: context,
      builder: (_) => _SpaceDialog(space: _spaces[index], typeName: _view.spaceTypeName(_spaces[index].type)),
    );
    if (edited == null || !mounted) return;
    setState(() => _spaces = [for (var i = 0; i < _spaces.length; i++) i == index ? edited : _spaces[i]]);
  }

  Future<void> _editSelectedCourtSize() async {
    final id = _selectedId;
    if (id == null) return;
    final found = _view.findCourt(id)!;
    final result = await showDialog<_CourtSizeResult>(
      context: context,
      builder: (_) => _CourtSizeDialog(courtName: found.court.name, sportSize: found.partition.courtSize, ownSize: found.court.ownSize),
    );
    if (result == null || !mounted) return;
    setState(() => _view = _view.withCourtSize(id, result.size));
  }

  /// Medidas propias que cambiaron respecto de lo guardado.
  Map<int, CourtSize?> _changedCourtSizes() {
    final changed = <int, CourtSize?>{};
    for (final e in _elements) {
      final before = widget.view.findCourt(e.courtId)?.court.ownSize;
      final after = _view.findCourt(e.courtId)?.court.ownSize;
      if (before != after) changed[e.courtId] = after;
    }
    return changed;
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
              final size = _view.courtSizeOf(id);
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
      final removed = ClubMapNodeRef.court(_selectedId!);
      _connections = _connections.where((c) => !c.touches(removed)).toList();
      _elements = _elements.where((e) => e.courtId != _selectedId).toList();
      _selectedId = null;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await widget.onSave(
      ClubMapLayout(widthM: _widthM, heightM: _heightM, elements: _elements, spaces: _spaces, connections: _connections, courtSizes: _changedCourtSizes()),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final issues = findIssues(_view, _elements, _widthM, _heightM, spaces: _spaces);
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
        for (final court in partition.courts) ...[const SizedBox(height: 8), _PaletteCourt(partition: partition, court: _view.findCourt(court.id)!.court, placed: _isPlaced(court.id), onTap: () => _place(court.id))],
      ],
      for (final partition in _addable) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () => setState(() => _partitionIds = {..._partitionIds, partition.id}), icon: const Icon(Icons.add), label: Text('Sumar ${partition.sport} al plano')),
      ],
      const SizedBox(height: 12),
      Text('Arrastrá una cancha al plano o tocala para sumarla. Ya en el plano, arrastrala para moverla.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      if (_view.spaceTypes.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Otros espacios', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Lo que no es cancha: la entrada, los vestuarios, el bar... y la calle, como referencia para ubicarse.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final type in _view.spaceTypes) _AddSpaceButton(type: type, onPressed: () => _addSpace(type))],
        ),
      ],
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
                  child: _PaletteCourt(partition: partition, court: _view.findCourt(court.id)!.court, placed: _isPlaced(court.id), onTap: () => _place(court.id)),
                ),
              ),
          for (final partition in _addable)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: OutlinedButton.icon(onPressed: () => setState(() => _partitionIds = {..._partitionIds, partition.id}), icon: const Icon(Icons.add), label: Text('Sumar ${partition.sport}')),
              ),
            ),
          for (final type in _view.spaceTypes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: _AddSpaceButton(type: type, onPressed: () => _addSpace(type))),
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
    final selected = _selectedId == null ? null : _view.findCourt(_selectedId!);
    final selectedSpace = _selectedSpace == null ? null : _spaces[_selectedSpace!];
    final removeStyle = TextStyle(color: theme.colorScheme.error);

    final node = _selectedNode;
    final nodeConnections = node == null ? 0 : _connections.where((c) => c.touches(node)).length;
    final connectButtons = <Widget>[
      if (node != null)
        OutlinedButton.icon(onPressed: () => setState(() => _connectingFrom = node), icon: const Icon(Icons.timeline), label: const Text('Conectar con…')),
      if (nodeConnections > 0)
        TextButton(onPressed: _removeSelectedConnections, child: Text(nodeConnections == 1 ? 'Sacar el camino' : 'Sacar $nodeConnections caminos')),
    ];

    final Widget toolbar;
    if (_connectingFrom != null) {
      toolbar = Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.timeline, color: theme.colorScheme.primary),
          Text('Tocá con qué conectar ${_nodeName(_connectingFrom!)}. Si ya están unidos, se saca el camino.', style: theme.textTheme.titleSmall),
          TextButton(onPressed: () => setState(() => _connectingFrom = null), child: const Text('Cancelar')),
        ],
      );
    } else if (selected != null && _isPlaced(_selectedId!)) {
      final ownSize = selected.court.ownSize;
      toolbar = Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${selected.partition.sport} · ${selected.court.name}', style: theme.textTheme.titleSmall),
          OutlinedButton.icon(
            onPressed: _editSelectedCourtSize,
            icon: const Icon(Icons.straighten),
            label: Text('Medidas: ${(ownSize ?? selected.partition.courtSize).label}${ownSize != null ? ' (propia)' : ''}'),
          ),
          OutlinedButton.icon(onPressed: _rotateSelected, icon: const Icon(Icons.rotate_right), label: const Text('Girar 90°')),
          ...connectButtons,
          OutlinedButton.icon(
            onPressed: _removeSelected,
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            label: Text('Sacar del plano', style: removeStyle),
          ),
        ],
      );
    } else if (selectedSpace != null) {
      toolbar = Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${_view.spaceName(selectedSpace)} · ${selectedSpace.widthM} × ${selectedSpace.heightM} m', style: theme.textTheme.titleSmall),
          OutlinedButton.icon(onPressed: _editSelectedSpace, icon: const Icon(Icons.edit_outlined), label: const Text('Nombre y tamaño')),
          OutlinedButton.icon(onPressed: _rotateSelectedSpace, icon: const Icon(Icons.rotate_right), label: const Text('Girar 90°')),
          ...connectButtons,
          OutlinedButton.icon(
            onPressed: _removeSelectedSpace,
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            label: Text('Sacar del plano', style: removeStyle),
          ),
        ],
      );
    } else {
      toolbar = Align(
        alignment: Alignment.centerLeft,
        child: Text('Tocá una cancha o un espacio del plano para editarlo o conectarlo con un camino.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
          child: toolbar,
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
        if (issues.hasOutside) ...[const SizedBox(height: 10), const _IssueBanner('Con este tamaño, algunas canchas o espacios quedan afuera del predio. Movelos o elegí un predio más grande.')],
        if (issues.hasOverlap) ...[const SizedBox(height: 10), const _IssueBanner('Hay canchas o espacios encimados. Separalos para poder guardar.')],
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
                                  view: _view,
                                  widthM: _widthM,
                                  heightM: _heightM,
                                  elements: _elements,
                                  spaces: _spaces,
                                  connections: _connections,
                                  scale: _scale,
                                  selectedCourtId: _selectedId,
                                  selectedSpaceIndex: _selectedSpace,
                                  issues: issues,
                                  onCourtTap: (id) => _tapNode(ClubMapNodeRef.court(id)),
                                  onCourtMoved: _move,
                                  onSpaceTap: (index) => _tapNode(ClubMapNodeRef.space(index)),
                                  onSpaceMoved: _moveSpace,
                                  onBackgroundTap: () => setState(() {
                                    _connectingFrom = null;
                                    _selectCourt(null);
                                  }),
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
                '${court.isCover ? 'Techada' : 'Descubierta'}${court.maxPlayers != null ? ' · ${court.maxPlayers} jugadores' : ''}${court.ownSize != null ? ' · ${court.ownSize!.label}' : ''}',
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

class _AddSpaceButton extends StatelessWidget {
  final ClubMapSpaceType type;
  final VoidCallback onPressed;

  const _AddSpaceButton({required this.type, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(SpaceTile.iconOf(type.type), size: 18),
      label: Text(type.name),
    );
  }
}

/// Lo que devuelve el diálogo de medidas: `size` null = la del deporte.
class _CourtSizeResult {
  final CourtSize? size;

  const _CourtSizeResult(this.size);
}

double? _parseMeters(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

String? _validateSide(String? text) {
  final value = _parseMeters(text ?? '');
  if (value == null) return 'Ingresá un número';
  if (value < CourtSize.minSideM || value > CourtSize.maxSideM) {
    return 'Entre ${formatMeters(CourtSize.minSideM)} y ${formatMeters(CourtSize.maxSideM)} m';
  }
  if ((value * 100).round() != value * 100) return 'Hasta 2 decimales';
  return null;
}

/// Medida propia de una cancha (largo x ancho), o volver a la del deporte.
class _CourtSizeDialog extends StatefulWidget {
  final String courtName;
  final CourtSize sportSize;
  final CourtSize? ownSize;

  const _CourtSizeDialog({required this.courtName, required this.sportSize, required this.ownSize});

  @override
  State<_CourtSizeDialog> createState() => _CourtSizeDialogState();
}

class _CourtSizeDialogState extends State<_CourtSizeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _length = TextEditingController(text: formatMeters((widget.ownSize ?? widget.sportSize).lengthM));
  late final _width = TextEditingController(text: formatMeters((widget.ownSize ?? widget.sportSize).widthM));

  @override
  void dispose() {
    _length.dispose();
    _width.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final size = CourtSize(lengthM: _parseMeters(_length.text)!, widthM: _parseMeters(_width.text)!);
    // Si coincide con la del deporte, no hace falta guardarla como propia.
    Navigator.of(context).pop(_CourtSizeResult(size == widget.sportSize ? null : size));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decimals = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];

    return AlertDialog(
      title: Text('Medidas de ${widget.courtName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La medida del deporte es ${widget.sportSize.label}. Cambiala si esta cancha mide distinto.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _length,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Largo', suffixText: 'm'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: decimals,
                    validator: _validateSide,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _width,
                    decoration: const InputDecoration(labelText: 'Ancho', suffixText: 'm'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: decimals,
                    validator: _validateSide,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (widget.ownSize != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(const _CourtSizeResult(null)),
            child: const Text('Usar la del deporte'),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Aplicar')),
      ],
    );
  }
}

/// Nombre y tamaño (en metros enteros) de un espacio del plano.
class _SpaceDialog extends StatefulWidget {
  final ClubMapSpace space;
  final String typeName;

  const _SpaceDialog({required this.space, required this.typeName});

  @override
  State<_SpaceDialog> createState() => _SpaceDialogState();
}

class _SpaceDialogState extends State<_SpaceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.space.label ?? '');
  late final _width = TextEditingController(text: '${widget.space.widthM}');
  late final _height = TextEditingController(text: '${widget.space.heightM}');

  @override
  void dispose() {
    _label.dispose();
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  String? _validateMeters(String? text) {
    final value = int.tryParse(text?.trim() ?? '');
    if (value == null || value < 1 || value > 500) return 'Entre 1 y 500 m';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final label = _label.text.trim();
    Navigator.of(context).pop(widget.space.copyWith(
      label: () => label.isEmpty ? null : label,
      widthM: int.parse(_width.text.trim()),
      heightM: int.parse(_height.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly];

    return AlertDialog(
      title: Text(widget.typeName),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _label,
              autofocus: true,
              maxLength: ClubMapSpace.maxLabelLength,
              decoration: InputDecoration(labelText: 'Nombre (opcional)', hintText: widget.typeName),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _width,
                    decoration: const InputDecoration(labelText: 'Ancho', suffixText: 'm'),
                    keyboardType: TextInputType.number,
                    inputFormatters: digits,
                    validator: _validateMeters,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _height,
                    decoration: const InputDecoration(labelText: 'Largo', suffixText: 'm'),
                    keyboardType: TextInputType.number,
                    inputFormatters: digits,
                    validator: _validateMeters,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Aplicar')),
      ],
    );
  }
}
