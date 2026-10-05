import 'package:flutter/material.dart';

import '../../../../domain/entities/club_map/club_map.dart';
import 'court_tile.dart';
import 'plan_canvas.dart';

/// Paso 1: qué deportes se ubican en el plano. Los que ya están en el plano
/// aparecen tildados y no se pueden volver a sumar. Si el club no tiene plano,
/// también se elige el tamaño del predio.
class ClubMapSportPicker extends StatefulWidget {
  final ClubMapView view;
  final VoidCallback onCancel;
  final void Function(Set<int> partitionIds, ClubMapSizePreset? size) onContinue;

  const ClubMapSportPicker({super.key, required this.view, required this.onCancel, required this.onContinue});

  @override
  State<ClubMapSportPicker> createState() => _ClubMapSportPickerState();
}

class _ClubMapSportPickerState extends State<ClubMapSportPicker> {
  late final Set<int> _inMap = widget.view.map == null ? <int>{} : widget.view.partitionIdsInMap(widget.view.map!.elements);
  late final Set<int> _picked = _initialPick();
  String _sizeId = ClubMapSizePreset.defaultPreset;

  List<ClubMapPartition> get _sports => widget.view.partitions.where((p) => p.courts.isNotEmpty).toList();

  /// Si falta un solo deporte, viene tildado.
  Set<int> _initialPick() {
    final missing = _sports.where((p) => !_inMap.contains(p.id)).toList();
    return missing.length == 1 ? {missing.first.id} : <int>{};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final askSize = widget.view.map == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(onPressed: widget.onCancel, icon: const Icon(Icons.arrow_back), label: const Text('Volver al mapa')),
            const SizedBox(height: 12),
            Text('PASO 1 DE 2', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('¿Qué canchas vas a ubicar en el plano?', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Todas van en el mismo plano del club. Cada deporte se suma una sola vez.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Wrap(spacing: 12, runSpacing: 12, children: [for (final p in _sports) _sportCard(context, p)]),
            if (askSize) ...[
              const SizedBox(height: 32),
              Text('¿Qué tamaño tiene el predio?', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Es aproximado y se puede cambiar después. Las canchas se dibujan con su medida real.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 12, children: [for (final preset in ClubMapSizePreset.all) _sizeCard(context, preset)]),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: widget.onCancel, child: const Text('Cancelar')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _picked.isEmpty ? null : () => widget.onContinue(_picked, askSize ? ClubMapSizePreset.all.firstWhere((p) => p.id == _sizeId) : null),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sportCard(BuildContext context, ClubMapPartition partition) {
    final theme = Theme.of(context);
    final already = _inMap.contains(partition.id);
    final checked = already || _picked.contains(partition.id);
    final covered = partition.courts.where((c) => c.isCover).length;
    final uncovered = partition.courts.length - covered;
    final count = partition.courts.length;

    String coverText() {
      if (covered == 0) return 'Todas descubiertas';
      if (uncovered == 0) return 'Todas techadas';
      return '$covered ${covered == 1 ? 'techada' : 'techadas'}, $uncovered ${uncovered == 1 ? 'descubierta' : 'descubiertas'}';
    }

    return SizedBox(
      width: 280,
      child: Material(
        color: already ? theme.colorScheme.surfaceContainerLow : (checked ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : theme.colorScheme.surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: checked && !already ? theme.colorScheme.primary : theme.colorScheme.outlineVariant, width: checked && !already ? 2 : 1),
        ),
        child: CheckboxListTile(
          value: checked,
          onChanged: already ? null : (value) => setState(() => value == true ? _picked.add(partition.id) : _picked.remove(partition.id)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: SportStyle.of(partition.clubTypeId).fill, borderRadius: BorderRadius.circular(3)),
              ),
              Text(partition.sport, style: theme.textTheme.titleMedium),
              if (already)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFDCEFE0), borderRadius: BorderRadius.circular(999)),
                  child: const Text('Ya está en el plano', style: TextStyle(fontSize: 11, color: Color(0xFF1B5E2B))),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$count ${count == 1 ? 'cancha' : 'canchas'}: ${partition.courts.map((c) => c.name).join(', ')}\n'
              '${coverText()} · ${partition.courtSize.label}',
            ),
          ),
        ),
      ),
    );
  }

  Widget _sizeCard(BuildContext context, ClubMapSizePreset preset) {
    final theme = Theme.of(context);
    final active = preset.id == _sizeId;
    final maxSide = ClubMapSizePreset.all.last.widthM;

    return SizedBox(
      width: 280,
      child: Material(
        color: active ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: active ? theme.colorScheme.primary : theme.colorScheme.outlineVariant, width: active ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _sizeId = preset.id),
          child: Semantics(
            selected: active,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 28,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 38 * preset.widthM / maxSide,
                            height: 38 * preset.heightM / maxSide,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              border: Border.all(color: theme.colorScheme.primary, width: 2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(preset.name, style: theme.textTheme.titleMedium),
                            Text(
                              '${preset.widthM} × ${preset.heightM} m · ${formatThousands(preset.areaM2)} m²',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(preset.fits, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(preset.example, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
