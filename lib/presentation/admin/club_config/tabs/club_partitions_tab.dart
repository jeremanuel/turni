import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/club_type.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/repositories/club_partition_admin_repository.dart';
import '../widgets/club_partition_card.dart';
import '../widgets/club_partition_form_dialog.dart';
import '../widgets/partition_physical_form_dialog.dart';

class ClubPartitionsTab extends StatefulWidget {
  const ClubPartitionsTab({super.key});

  @override
  State<ClubPartitionsTab> createState() => _ClubPartitionsTabState();
}

class _ClubPartitionsTabState extends State<ClubPartitionsTab> {
  final _repository = sl<ClubPartitionAdminRepository>();
  final _newSectorFormKey = GlobalKey<FormState>();
  final _newSectorPhoneController = TextEditingController();
  final _newSectorNameController = TextEditingController();
  int? _newSectorClubTypeId;
  bool _isCreatingSector = false;

  bool _isLoading = true;
  String? _errorMessage;
  List<ClubType> _clubTypes = [];
  List<ClubPartition> _clubPartitions = [];
  final Map<int, List<PhysicalPartition>> _physicalByClubPartition = {};
  final Set<int> _loadingPhysicalFor = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _newSectorPhoneController.dispose();
    _newSectorNameController.dispose();
    super.dispose();
  }

  /// El backend no manda el objeto `club_type` anidado en `/admin/club_partition`
  /// (solo el `club_type_id` plano), así que resolvemos el nombre del deporte
  /// contra el catálogo cargado en `_clubTypes` en vez de confiar en
  /// `clubPartition.clubType`, que siempre llega `null`.
  String _clubTypeName(int clubTypeId) {
    final match = _clubTypes.where((t) => t.clubTypeId == clubTypeId);
    return match.isEmpty ? 'Tipo #$clubTypeId' : match.first.name;
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final typesResult = await _repository.listClubTypes();
    final partitionsResult = await _repository.listClubPartitions();

    if (!mounted) return;

    String? error;
    List<ClubType> clubTypes = [];
    List<ClubPartition> clubPartitions = [];

    typesResult.when(
      left: (failure) => error = failure.message,
      right: (types) => clubTypes = types,
    );

    partitionsResult.when(
      left: (failure) => error ??= failure.message,
      right: (partitions) => clubPartitions = partitions,
    );

    if (error != null) {
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _clubTypes = clubTypes;
      _clubPartitions = clubPartitions;
      _newSectorClubTypeId = clubTypes.isNotEmpty ? clubTypes.first.clubTypeId : null;
    });

    for (final partition in clubPartitions) {
      await _loadPhysicalPartitions(partition.club_partition_id!, silent: true);
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadPhysicalPartitions(int clubPartitionId, {bool silent = false}) async {
    if (!silent) {
      setState(() => _loadingPhysicalFor.add(clubPartitionId));
    }

    final result = await _repository.listPartitionPhysical(clubPartitionId);

    if (!mounted) return;

    result.when(
      left: (failure) {
        if (!silent) {
          SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
          setState(() => _loadingPhysicalFor.remove(clubPartitionId));
        }
      },
      right: (partitions) {
        setState(() {
          _physicalByClubPartition[clubPartitionId] = partitions;
          _loadingPhysicalFor.remove(clubPartitionId);
        });
      },
    );
  }

  Future<void> _createSector() async {
    if (!(_newSectorFormKey.currentState?.validate() ?? false)) return;
    if (_newSectorClubTypeId == null) return;

    setState(() => _isCreatingSector = true);

    final result = await _repository.createClubPartition(
      clubTypeId: _newSectorClubTypeId!,
      phone: _newSectorPhoneController.text.trim().isEmpty ? null : _newSectorPhoneController.text.trim(),
      physicalPartitionName:
          _newSectorNameController.text.trim().isEmpty ? null : _newSectorNameController.text.trim(),
    );

    if (!mounted) return;

    result.when(
      left: (failure) {
        setState(() => _isCreatingSector = false);
        SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
      },
      right: (created) {
        setState(() {
          _isCreatingSector = false;
          _clubPartitions = [..._clubPartitions, created];
          _physicalByClubPartition[created.club_partition_id!] = [];
          _newSectorPhoneController.clear();
          _newSectorNameController.clear();
        });
      },
    );
  }

  Future<void> _openEditClubPartitionDialog(ClubPartition partition) async {
    final updated = await showDialog<ClubPartition>(
      context: context,
      builder: (_) => ClubPartitionFormDialog(
        clubTypes: _clubTypes,
        existing: partition,
      ),
    );

    if (updated == null || !mounted) return;

    setState(() {
      _clubPartitions = _clubPartitions
          .map((p) => p.club_partition_id == updated.club_partition_id ? updated : p)
          .toList();
    });
  }

  Future<void> _toggleClubPartitionActive(ClubPartition partition) async {
    final result = await _repository.setClubPartitionActive(
      partition.club_partition_id!,
      !partition.active,
    );

    if (!mounted) return;

    result.when(
      left: (failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (updated) => setState(() {
        _clubPartitions = _clubPartitions
            .map((p) => p.club_partition_id == updated.club_partition_id ? updated : p)
            .toList();
      }),
    );
  }

  void _onPhysicalCreated(ClubPartition clubPartition, PhysicalPartition created) {
    setState(() {
      final current = _physicalByClubPartition[clubPartition.club_partition_id!] ?? [];
      _physicalByClubPartition[clubPartition.club_partition_id!] = [...current, created];
    });
  }

  Future<void> _openCreatePartitionPhysicalDialog(ClubPartition partition) async {
    final id = partition.club_partition_id!;
    final existing = _physicalByClubPartition[id] ?? [];
    final used = existing.map((p) => p.physicalIdentifier).whereType<int>();
    final suggested = used.isEmpty ? 1 : used.reduce((a, b) => a > b ? a : b) + 1;

    final created = await showDialog<PhysicalPartition>(
      context: context,
      builder: (_) => PartitionPhysicalFormDialog(
        clubPartitionId: id,
        suggestedIdentifier: suggested,
      ),
    );

    if (created == null || !mounted) return;
    _onPhysicalCreated(partition, created);
  }

  Future<void> _openEditPartitionPhysicalDialog(PhysicalPartition partition) async {
    final updated = await showDialog<PhysicalPartition>(
      context: context,
      builder: (_) => PartitionPhysicalFormDialog(
        clubPartitionId: partition.clubPartitionId,
        existing: partition,
      ),
    );

    if (updated == null || !mounted) return;

    setState(() {
      final list = _physicalByClubPartition[partition.clubPartitionId] ?? [];
      _physicalByClubPartition[partition.clubPartitionId] = list
          .map((p) => p.partitionPhysicalId == updated.partitionPhysicalId ? updated : p)
          .toList();
    });
  }

  Future<void> _togglePartitionPhysicalActive(PhysicalPartition partition) async {
    final result = await _repository.setPartitionPhysicalActive(
      partition.partitionPhysicalId,
      !partition.active,
    );

    if (!mounted) return;

    result.when(
      left: (failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (updated) => setState(() {
        final list = _physicalByClubPartition[updated.clubPartitionId] ?? [];
        _physicalByClubPartition[updated.clubPartitionId] = list
            .map((p) => p.partitionPhysicalId == updated.partitionPhysicalId ? updated : p)
            .toList();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _clubTypes.isEmpty && _clubPartitions.isEmpty) {
      return Center(child: Text(_errorMessage!));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dar de baja nunca borra turnos ya tomados: solo oculta el sector/cancha para reservas nuevas.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          if (_clubPartitions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Todavía no hay deportes/sectores creados.'),
            )
          else
            ...(_clubPartitions.map((partition) {
              final id = partition.club_partition_id!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClubPartitionCard(
                  clubPartition: partition,
                  clubTypeName: _clubTypeName(partition.club_type_id),
                  physicalPartitions: _physicalByClubPartition[id] ?? [],
                  isLoadingPhysical: _loadingPhysicalFor.contains(id),
                  onEdit: () => _openEditClubPartitionDialog(partition),
                  onToggleActive: () => _toggleClubPartitionActive(partition),
                  onAddPhysical: () => _openCreatePartitionPhysicalDialog(partition),
                  onEditPhysical: _openEditPartitionPhysicalDialog,
                  onTogglePhysicalActive: _togglePartitionPhysicalActive,
                ),
              );
            })),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _newSectorFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Alta de nuevo deporte/sector', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Así se ve el formulario para crear un sector nuevo.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: _newSectorClubTypeId,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de actividad',
                              border: OutlineInputBorder(),
                            ),
                            items: _clubTypes
                                .map((t) => DropdownMenuItem(value: t.clubTypeId, child: Text(t.name)))
                                .toList(),
                            onChanged: (value) => setState(() => _newSectorClubTypeId = value),
                            validator: (value) => value == null ? 'Requerido' : null,
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            controller: _newSectorPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 260,
                          child: TextFormField(
                            controller: _newSectorNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la partición física',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton(
                          onPressed: (_isCreatingSector || _clubTypes.isEmpty) ? null : _createSector,
                          child: _isCreatingSector
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Crear sector'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
