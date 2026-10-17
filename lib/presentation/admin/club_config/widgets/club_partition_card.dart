import 'package:flutter/material.dart';

import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/partition_vocabulary.dart';
import '../../../../domain/entities/physical_partition.dart';
import 'admin_data_table.dart';

class ClubPartitionCard extends StatelessWidget {
  const ClubPartitionCard({
    super.key,
    required this.clubPartition,
    required this.clubTypeName,
    required this.physicalPartitions,
    required this.isLoadingPhysical,
    required this.onEdit,
    required this.onToggleActive,
    required this.onAddPhysical,
    required this.onEditPhysical,
    required this.onTogglePhysicalActive,
    this.readOnly = false,
    this.highlighted = false,
    this.highlightedPartitionPhysicalId,
  });

  final ClubPartition clubPartition;
  final String clubTypeName;
  final List<PhysicalPartition> physicalPartitions;
  final bool isLoadingPhysical;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onAddPhysical;
  final void Function(PhysicalPartition) onEditPhysical;
  final void Function(PhysicalPartition) onTogglePhysicalActive;

  /// Sin permiso para editar canchas: se ve todo, sin switches ni botones de edición.
  final bool readOnly;

  /// Resalta la card (y la fila de [highlightedPartitionPhysicalId]) cuando se
  /// llegó acá desde un acceso directo de otra pantalla.
  final bool highlighted;
  final int? highlightedPartitionPhysicalId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final vocabulary = PartitionVocabulary.of(clubPartition);
    final features = vocabulary.features;
    final ownName = clubPartition.name?.trim();
    // Sin nombre propio se llama como su tipo: el chip del tipo sobraría.
    final title = ownName == null || ownName.isEmpty ? clubTypeName : ownName;

    return Card(
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.primary, width: 2),
            )
          : null,
      child: Opacity(
        opacity: clubPartition.active ? 1 : 0.65,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row + Expanded(Wrap) en vez de un único Wrap con un Spacer
              // adentro: Spacer solo funciona en un Flex (tiraba "Incorrect
              // use of ParentDataWidget" y rompía el layout de la card).
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                  if (title != clubTypeName) Chip(
                    label: Text(clubTypeName),
                    backgroundColor: colorScheme.secondaryContainer,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    title,
                    style: textTheme.titleMedium,
                  ),
                  if (clubPartition.phone != null && clubPartition.phone!.isNotEmpty)
                    Text(
                      'Tel: ${clubPartition.phone}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                      ],
                    ),
                  ),
                  Text(clubPartition.active ? 'Activo' : 'Inactivo'),
                  Switch(
                    value: clubPartition.active,
                    onChanged: readOnly ? null : (_) => onToggleActive(),
                  ),
                  if (!readOnly) IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
                ],
              ),
              const Divider(),
              if (isLoadingPhysical)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (physicalPartitions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Todavía no hay ${vocabulary.space.lowerPlural} en este servicio.',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                )
              else
                AdminTableScroll(
                  child: AdminDataTable(
                    columns: [
                      'Nombre',
                      if (features.capacity) vocabulary.participant.plural,
                      if (features.cover) vocabulary.space.g('Cubierta', 'Cubierto'),
                      'Duración',
                      'Precio default',
                      vocabulary.space.g('Activa', 'Activo'),
                      '',
                    ],
                    rows: physicalPartitions
                        .map(
                          (partition) => [
                            partition.partitionPhysicalId == highlightedPartitionPhysicalId
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_right, size: 20, color: colorScheme.primary),
                                      Text(
                                        partition.spaceLabel(fallback: clubPartition),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(partition.spaceLabel(fallback: clubPartition)),
                            if (features.capacity) Text(
                              partition.maxPlayers != null
                                  ? '${partition.minPlayers}–${partition.maxPlayers}'
                                  : '${partition.minPlayers}',
                            ),
                            if (features.cover) Text(partition.isCover == '1' ? 'Sí' : 'No'),
                            Text(
                              partition.defaultSessionDuration != null
                                  ? '${partition.defaultSessionDuration} min'
                                  : '-',
                            ),
                            Text(
                              partition.defaultSessionPrice != null
                                  ? '\$${ThousandsFormat.formatPrice(partition.defaultSessionPrice!)}'
                                  : '-',
                            ),
                            Switch(
                              value: partition.active,
                              onChanged: readOnly ? null : (_) => onTogglePhysicalActive(partition),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: readOnly ? null : () => onEditPhysical(partition),
                            ),
                          ],
                        )
                        .toList(),
                  ),
                ),
              if (!readOnly) const SizedBox(height: 12),
              if (!readOnly) Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onAddPhysical,
                  icon: const Icon(Icons.add),
                  label: Text('Agregar ${vocabulary.space.lower}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
