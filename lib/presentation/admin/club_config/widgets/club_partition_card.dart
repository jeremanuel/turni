import 'package:flutter/material.dart';

import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/club_partition.dart';
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Opacity(
        opacity: clubPartition.active ? 1 : 0.65,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Chip(
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
                    clubPartition.physicalPartitionName ?? 'Sector sin nombre',
                    style: textTheme.titleMedium,
                  ),
                  if (clubPartition.phone != null && clubPartition.phone!.isNotEmpty)
                    Text(
                      'Tel: ${clubPartition.phone}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  const Spacer(),
                  Text(clubPartition.active ? 'Activo' : 'Inactivo'),
                  Switch(
                    value: clubPartition.active,
                    onChanged: (_) => onToggleActive(),
                  ),
                  IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
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
                    'Todavía no hay canchas en este sector.',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: AdminDataTable(
                    columns: const [
                      'Descripción',
                      'Jugadores',
                      'Cubierta',
                      'Duración',
                      'Precio default',
                      'Activa',
                      '',
                    ],
                    rows: physicalPartitions
                        .map(
                          (partition) => [
                            Text(partition.description ?? '-'),
                            Text(
                              partition.maxPlayers != null
                                  ? '${partition.minPlayers}–${partition.maxPlayers}'
                                  : '${partition.minPlayers}',
                            ),
                            Text(partition.isCover == '1' ? 'Sí' : 'No'),
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
                              onChanged: (_) => onTogglePhysicalActive(partition),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => onEditPhysical(partition),
                            ),
                          ],
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onAddPhysical,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar cancha'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
