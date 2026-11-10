import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/cash/cash.dart';
import '../../../../domain/entities/club_map/club_map.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/partition_vocabulary.dart';
import '../../../../domain/repositories/cash_repository.dart';
import '../../club_map/widgets/plan_canvas.dart';

/// Alta o edición de un puesto y sus espacios. Devuelve true si guardó.
Future<bool> showCashPointDialog(
  BuildContext context, {
  required CashPoint? point,
  required List<CashPoint> points,
  required List<ClubPartition> partitions,
  required ClubMapView? map,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _CashPointDialog(point: point, points: points, partitions: partitions, map: map),
  );
  return saved ?? false;
}

class _CashPointDialog extends StatefulWidget {
  const _CashPointDialog({required this.point, required this.points, required this.partitions, required this.map});

  final CashPoint? point;
  final List<CashPoint> points;
  final List<ClubPartition> partitions;
  final ClubMapView? map;

  @override
  State<_CashPointDialog> createState() => _CashPointDialogState();
}

class _CashPointDialogState extends State<_CashPointDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.point?.name ?? '');
  late final Set<int> _selected = {...?widget.point?.spaces.map((space) => space.partitionPhysicalId)};
  late bool _isPrimary = widget.point?.isPrimary ?? widget.points.where((point) => point.active).isEmpty;
  late bool _showMap = widget.map?.map != null;
  bool _saving = false;
  String? _error;

  /// Espacio → nombre del otro puesto que lo gestiona hoy.
  late final Map<int, String> _owners = {
    for (final point in widget.points)
      if (point.id != widget.point?.id && point.active)
        for (final space in point.spaces) space.partitionPhysicalId: point.name,
  };

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save({bool? active}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await sl<CashRepository>().savePoint(
      id: widget.point?.id,
      name: _name.text.trim(),
      partitionPhysicalIds: _selected.toList(),
      isPrimary: _isPrimary,
      active: active,
    );
    if (!mounted) return;
    switch (result) {
      case Right():
        Navigator.of(context).pop(true);
      case Left(:final failure):
        setState(() {
          _saving = false;
          _error = failure.message;
        });
    }
  }

  void _toggle(int id) => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));

  Widget _spaces(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final partition in widget.partitions)
        if ((partition.physicalPartitions ?? const []).isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(partition.displayName, style: textTheme.titleSmall),
          for (final space in partition.physicalPartitions!.where((space) => space.active != false))
            CheckboxListTile(
              key: ValueKey('cash.point.space.${space.partitionPhysicalId}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(space.spaceLabel(fallback: partition)),
              subtitle: _owners[space.partitionPhysicalId] == null ? null : Text('Hoy en ${_owners[space.partitionPhysicalId]}', style: muted),
              value: _selected.contains(space.partitionPhysicalId),
              onChanged: (_) => _toggle(space.partitionPhysicalId),
            ),
        ],
    ]);
  }

  Widget _plan(BuildContext context, ClubMapLayout layout, double maxWidth) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final inThis = scheme.primary;
    final inOther = scheme.tertiaryContainer;
    final free = scheme.surfaceContainerHighest;
    final colors = <int, Color>{
      for (final element in layout.elements)
        element.courtId: _selected.contains(element.courtId) ? inThis : (_owners.containsKey(element.courtId) ? inOther : free),
    };

    Widget legend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(label, style: textTheme.bodySmall),
        ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      PlanCanvas(
        view: widget.map!,
        widthM: layout.widthM,
        heightM: layout.heightM,
        elements: layout.elements,
        spaces: layout.spaces,
        connections: layout.connections,
        scale: planScale(layout.widthM, layout.heightM, maxWidth, 420),
        courtColors: colors,
        onCourtTap: _toggle,
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 14, runSpacing: 4, children: [legend(inThis, 'En este puesto'), legend(inOther, 'En otro puesto'), legend(free, 'Sin puesto')]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final point = widget.point;
    final layout = widget.map?.map;
    final canShowMap = layout != null;
    final mapShown = canShowMap && _showMap;
    final vocabulary = PartitionVocabulary.common(widget.partitions);
    final screen = MediaQuery.sizeOf(context).width;
    final wide = screen >= 900;

    final form = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Nombre', style: muted),
      const SizedBox(height: 6),
      TextFormField(
        key: const ValueKey('cash.point.name'),
        controller: _name,
        maxLength: 80,
        decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ''),
        validator: (value) => (value ?? '').trim().isEmpty ? 'Poné un nombre.' : null,
      ),
      const SizedBox(height: 14),
      Text('Espacios que gestiona', style: textTheme.titleSmall),
      if (widget.partitions.isEmpty) Text('Todavía no hay ${vocabulary.space.plural}.', style: muted),
      if (canShowMap)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Mostrar en mapa interactivo'),
          value: _showMap,
          onChanged: (value) => setState(() => _showMap = value),
        ),
      _spaces(context),
      const SizedBox(height: 8),
      CheckboxListTile(
        key: const ValueKey('cash.point.primary'),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text('Puesto principal'),
        subtitle: Text('Recibe abonos, torneos, productos sueltos y espacios sin puesto.', style: muted),
        value: _isPrimary,
        // El principal se cambia eligiendo otro: tiene que haber siempre uno.
        onChanged: point?.isPrimary == true ? null : (value) => setState(() => _isPrimary = value ?? false),
      ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(_error!, style: TextStyle(color: scheme.error)),
      ],
    ]);

    return AlertDialog(
      title: Text(point == null ? 'Nuevo puesto' : 'Editar puesto'),
      content: SizedBox(
        width: mapShown && wide ? 880 : 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: mapShown && wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 400, child: form),
                    const SizedBox(width: 24),
                    Expanded(child: _plan(context, layout, 430)),
                  ])
                : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    form,
                    if (mapShown) ...[
                      const SizedBox(height: 14),
                      _plan(context, layout, (screen - 96).clamp(200.0, 420.0)),
                    ],
                  ]),
          ),
        ),
      ),
      actions: [
        if (point != null && !point.isPrimary)
          TextButton(onPressed: _saving ? null : () => _save(active: !point.active), child: Text(point.active ? 'Desactivar' : 'Activar')),
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(key: const ValueKey('cash.point.save'), onPressed: _saving ? null : () => _save(), child: const Text('Guardar')),
      ],
    );
  }
}
