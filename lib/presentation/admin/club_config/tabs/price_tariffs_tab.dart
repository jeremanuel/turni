import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/club_type.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/entities/price_rule.dart';
import '../../../../domain/entities/price_tariff.dart';
import '../../../../domain/repositories/club_partition_admin_repository.dart';
import '../../../../domain/repositories/price_tariff_repository.dart';
import '../widgets/price_field.dart';
import '../widgets/price_rule_form_dialog.dart';
import '../widgets/price_tariff_name_dialog.dart';
import '../widgets/time_field.dart';

const _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// Círculo de día (L-D) igual al mockup: sin relleno + borde cuando no está
/// seleccionado (no el gris lleno de un `CircleAvatar` default).
Widget _dayPill(
  BuildContext context, {
  required String label,
  required bool selected,
  double size = 28,
  VoidCallback? onTap,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final circle = Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? colorScheme.primary : Colors.transparent,
      border: Border.all(
        color: selected ? colorScheme.primary : colorScheme.outline,
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      ),
    ),
  );

  if (onTap == null) return circle;
  return InkWell(borderRadius: BorderRadius.circular(size / 2), onTap: onTap, child: circle);
}

class PriceTariffsTab extends StatefulWidget {
  const PriceTariffsTab({
    super.key,
    this.focusClubPartitionId,
    this.focusPriceTariffId,
    this.focusPriceRuleId,
  });

  /// Sector/tarifa/franja a dejar seleccionados al abrir (acceso directo
  /// desde otra pantalla, ver `ClubConfigFocus`). La franja se resalta.
  final int? focusClubPartitionId;
  final int? focusPriceTariffId;
  final int? focusPriceRuleId;

  @override
  State<PriceTariffsTab> createState() => _PriceTariffsTabState();
}

class _PriceTariffsTabState extends State<PriceTariffsTab> {
  final _clubPartitionRepo = sl<ClubPartitionAdminRepository>();
  final _priceTariffRepo = sl<PriceTariffRepository>();

  final _ruleFormKey = GlobalKey<FormState>();
  final _ruleStartController = TextEditingController(text: '00:00');
  final _ruleEndController = TextEditingController(text: '23:59');
  final _rulePriceController = TextEditingController();
  Set<int> _ruleSelectedDays = {1, 2, 3, 4, 5, 6, 7};
  bool _isCreatingRule = false;

  bool _isLoading = true;
  String? _errorMessage;
  List<ClubType> _clubTypes = [];
  List<ClubPartition> _clubPartitions = [];
  int? _selectedClubPartitionId;
  List<PhysicalPartition> _physicalPartitions = [];
  List<PriceTariff> _tariffs = [];
  int? _selectedTariffId;
  bool _isLoadingTariffs = false;
  bool _focusConsumed = false;

  @override
  void initState() {
    super.initState();
    _loadClubPartitions();
  }

  @override
  void dispose() {
    _ruleStartController.dispose();
    _ruleEndController.dispose();
    _rulePriceController.dispose();
    super.dispose();
  }

  /// El backend no manda el objeto `club_type` anidado en `/admin/club_partition`
  /// (solo el `club_type_id` plano), así que resolvemos el nombre del deporte
  /// contra el catálogo cargado en `_clubTypes`.
  String _clubTypeName(int clubTypeId) {
    final match = _clubTypes.where((t) => t.clubTypeId == clubTypeId);
    return match.isEmpty ? 'Tipo #$clubTypeId' : match.first.name;
  }

  Future<void> _loadClubPartitions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final typesResult = await _clubPartitionRepo.listClubTypes();
    final result = await _clubPartitionRepo.listClubPartitions(includeInactive: false);

    if (!mounted) return;

    String? error;
    List<ClubType> clubTypes = [];

    typesResult.when(
      left: (DomainError failure) => error = failure.message,
      right: (List<ClubType> value) => clubTypes = value,
    );

    result.when(
      left: (DomainError failure) {
        setState(() {
          _errorMessage = error ?? failure.message;
          _isLoading = false;
        });
      },
      right: (List<ClubPartition> partitions) {
        setState(() {
          _clubTypes = clubTypes;
          _clubPartitions = partitions;
          _isLoading = false;
          final focused = partitions.where(
            (p) => p.club_partition_id == widget.focusClubPartitionId,
          );
          _selectedClubPartitionId = focused.isNotEmpty
              ? focused.first.club_partition_id
              : (partitions.isNotEmpty ? partitions.first.club_partition_id : null);
        });

        if (_selectedClubPartitionId != null) {
          _loadForClubPartition(_selectedClubPartitionId!);
        }
      },
    );
  }

  Future<void> _loadForClubPartition(int clubPartitionId) async {
    setState(() => _isLoadingTariffs = true);

    final physicalResult = await _clubPartitionRepo.listPartitionPhysical(clubPartitionId, includeInactive: false);
    final tariffsResult = await _priceTariffRepo.listByClubPartition(clubPartitionId);

    if (!mounted) return;

    String? error;
    List<PhysicalPartition> physical = [];
    List<PriceTariff> tariffs = [];

    physicalResult.when(
      left: (DomainError failure) => error = failure.message,
      right: (List<PhysicalPartition> value) => physical = value,
    );
    tariffsResult.when(
      left: (DomainError failure) => error ??= failure.message,
      right: (List<PriceTariff> value) => tariffs = value,
    );

    // La tarifa enfocada se respeta solo la primera vez que se carga su
    // sector: si el admin después cambia de sector y vuelve, es navegación suya.
    final focusTariffId = widget.focusPriceTariffId;
    final focused = !_focusConsumed && focusTariffId != null
        ? tariffs.where((t) => t.priceTariffId == focusTariffId)
        : const <PriceTariff>[];
    if (focused.isNotEmpty) _focusConsumed = true;

    setState(() {
      _physicalPartitions = physical;
      _tariffs = tariffs;
      _selectedTariffId = focused.isNotEmpty
          ? focused.first.priceTariffId
          : (tariffs.isNotEmpty ? tariffs.first.priceTariffId : null);
      _isLoadingTariffs = false;
      if (error != null) _errorMessage = error;
    });
  }

  PriceTariff? get _selectedTariff {
    if (_selectedTariffId == null) return null;
    final match = _tariffs.where((t) => t.priceTariffId == _selectedTariffId);
    return match.isEmpty ? null : match.first;
  }

  String _partitionLabel(int partitionPhysicalId) {
    final match = _physicalPartitions.where((p) => p.partitionPhysicalId == partitionPhysicalId);
    if (match.isEmpty) return 'Cancha sin datos';
    final p = match.first;
    if (p.description != null && p.description!.isNotEmpty) return p.description!;
    if (p.physicalIdentifier != null) return 'Cancha ${p.physicalIdentifier}';
    // Nunca mostrar el id interno de la fila (partitionPhysicalId): no es el
    // "identificador" que ve el admin, es la PK de la base.
    return 'Cancha sin identificador';
  }

  double? _defaultPriceFor(int partitionPhysicalId) {
    final match = _physicalPartitions.where((p) => p.partitionPhysicalId == partitionPhysicalId);
    return match.isEmpty ? null : match.first.defaultSessionPrice;
  }

  List<PhysicalPartition> get _availableToAdd {
    final assigned = _tariffs.expand((t) => t.memberPartitionPhysicalIds).toSet();
    return _physicalPartitions.where((p) => !assigned.contains(p.partitionPhysicalId)).toList();
  }

  void _replaceTariff(PriceTariff updated) {
    setState(() {
      _tariffs = _tariffs.map((t) => t.priceTariffId == updated.priceTariffId ? updated : t).toList();
    });
  }

  Future<void> _createTariff() async {
    final clubPartitionId = _selectedClubPartitionId;
    if (clubPartitionId == null) return;

    final created = await showDialog<PriceTariff>(
      context: context,
      builder: (_) => PriceTariffNameDialog(clubPartitionId: clubPartitionId),
    );

    if (created == null || !mounted) return;
    setState(() {
      _tariffs = [..._tariffs, created];
      _selectedTariffId = created.priceTariffId;
    });
  }

  Future<void> _renameTariff(PriceTariff tariff) async {
    final updated = await showDialog<PriceTariff>(
      context: context,
      builder: (_) => PriceTariffNameDialog(clubPartitionId: tariff.clubPartitionId, existing: tariff),
    );

    if (updated == null || !mounted) return;
    _replaceTariff(updated);
  }

  Future<void> _toggleTariffActive(PriceTariff tariff) async {
    final result = await _priceTariffRepo.setActive(tariff.priceTariffId, !tariff.active);
    if (!mounted) return;

    result.when(
      left: (DomainError failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: _replaceTariff,
    );
  }

  Future<void> _deleteTariff(PriceTariff tariff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar tarifa'),
        content: Text('¿Eliminar "${tariff.name}"? Esto borra también sus canchas asignadas y franjas.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _priceTariffRepo.delete(tariff.priceTariffId);
    if (!mounted) return;

    result.when(
      left: (DomainError failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (_) => setState(() {
        _tariffs = _tariffs.where((t) => t.priceTariffId != tariff.priceTariffId).toList();
        if (_selectedTariffId == tariff.priceTariffId) {
          _selectedTariffId = _tariffs.isNotEmpty ? _tariffs.first.priceTariffId : null;
        }
      }),
    );
  }

  Future<void> _addMember(PriceTariff tariff, int partitionPhysicalId) async {
    final result = await _priceTariffRepo.addMember(tariff.priceTariffId, partitionPhysicalId);
    if (!mounted) return;

    result.when(
      left: (DomainError failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: _replaceTariff,
    );
  }

  Future<void> _removeMember(PriceTariff tariff, int partitionPhysicalId) async {
    final result = await _priceTariffRepo.removeMember(tariff.priceTariffId, partitionPhysicalId);
    if (!mounted) return;

    result.when(
      left: (DomainError failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: _replaceTariff,
    );
  }

  String? _timeValidator(String? value) {
    final ok = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').hasMatch((value ?? '').trim());
    return ok ? null : 'HH:mm';
  }

  Future<void> _createRule(PriceTariff tariff) async {
    if (!(_ruleFormKey.currentState?.validate() ?? false)) return;
    if (_ruleSelectedDays.isEmpty) {
      SnackbarsFunctions.showErrorsSnackbar(context, 'Seleccioná al menos un día.');
      return;
    }

    setState(() => _isCreatingRule = true);

    final price = ThousandsFormat.parsePrice(_rulePriceController.text.trim()) ?? 0;
    final days = _ruleSelectedDays.toList()..sort();

    final result = await _priceTariffRepo.createRule(
      tariff.priceTariffId,
      daysOfWeek: days,
      startTime: _ruleStartController.text.trim(),
      endTime: _ruleEndController.text.trim(),
      price: price,
    );

    if (!mounted) return;

    result.when(
      left: (DomainError failure) {
        setState(() => _isCreatingRule = false);
        SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
      },
      right: (PriceRule created) {
        setState(() {
          _isCreatingRule = false;
          _rulePriceController.clear();
          _tariffs = _tariffs.map((t) {
            if (t.priceTariffId != tariff.priceTariffId) return t;
            return PriceTariff(
              priceTariffId: t.priceTariffId,
              clubPartitionId: t.clubPartitionId,
              name: t.name,
              active: t.active,
              memberPartitionPhysicalIds: t.memberPartitionPhysicalIds,
              rules: [...t.rules, created],
            );
          }).toList();
        });
      },
    );
  }

  Future<void> _editRule(PriceTariff tariff, PriceRule rule) async {
    final updated = await showDialog<PriceRule>(
      context: context,
      builder: (_) => PriceRuleFormDialog(priceTariffId: tariff.priceTariffId, existing: rule),
    );

    if (updated == null || !mounted) return;
    setState(() {
      _tariffs = _tariffs.map((t) {
        if (t.priceTariffId != tariff.priceTariffId) return t;
        return PriceTariff(
          priceTariffId: t.priceTariffId,
          clubPartitionId: t.clubPartitionId,
          name: t.name,
          active: t.active,
          memberPartitionPhysicalIds: t.memberPartitionPhysicalIds,
          rules: t.rules.map((r) => r.priceRuleId == updated.priceRuleId ? updated : r).toList(),
        );
      }).toList();
    });
  }

  Future<void> _toggleRuleActive(PriceTariff tariff, PriceRule rule) async {
    final result = await _priceTariffRepo.setRuleActive(rule.priceRuleId, !rule.active);
    if (!mounted) return;

    result.when(
      left: (DomainError failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (PriceRule updated) => setState(() {
        _tariffs = _tariffs.map((t) {
          if (t.priceTariffId != tariff.priceTariffId) return t;
          return PriceTariff(
            priceTariffId: t.priceTariffId,
            clubPartitionId: t.clubPartitionId,
            name: t.name,
            active: t.active,
            memberPartitionPhysicalIds: t.memberPartitionPhysicalIds,
            rules: t.rules.map((r) => r.priceRuleId == updated.priceRuleId ? updated : r).toList(),
          );
        }).toList();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _clubPartitions.isEmpty) {
      return Center(child: Text(_errorMessage!));
    }

    if (_clubPartitions.isEmpty) {
      return const Center(child: Text('No hay deportes/sectores activos todavía.'));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agrupá canchas en una tarifa con nombre y definí precios distintos según el horario y el día de la semana.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _clubPartitions.map((partition) {
              final selected = partition.club_partition_id == _selectedClubPartitionId;
              return ChoiceChip(
                label: Text(_clubTypeName(partition.club_type_id)),
                selected: selected,
                onSelected: (_) {
                  setState(() => _selectedClubPartitionId = partition.club_partition_id);
                  _loadForClubPartition(partition.club_partition_id!);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingTariffs
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 300,
                        height: double.infinity,
                        child: _buildTariffList(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _selectedTariff == null
                            ? Center(
                                child: Text(
                                  'Seleccioná o creá una tarifa.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )
                            : SingleChildScrollView(child: _buildTariffDetail(_selectedTariff!)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTariffList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Tarifas', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: _createTariff,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva tarifa'),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _tariffs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Todavía no hay tarifas para este sector.'),
                )
              : ListView.separated(
                  itemCount: _tariffs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tariff = _tariffs[index];
                    final selected = tariff.priceTariffId == _selectedTariffId;
                    final colorScheme = Theme.of(context).colorScheme;

                    return Card(
                      color: selected ? colorScheme.primaryContainer : null,
                      elevation: selected ? 0 : null,
                      shape: selected
                          ? RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: colorScheme.primary),
                            )
                          : null,
                      child: InkWell(
                        onTap: () => setState(() => _selectedTariffId = tariff.priceTariffId),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tariff.name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: selected ? colorScheme.onPrimaryContainer : null,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: tariff.memberPartitionPhysicalIds
                                    .map((id) => Chip(
                                          label: Text(_partitionLabel(id), style: const TextStyle(fontSize: 11)),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          backgroundColor:
                                              selected ? colorScheme.secondaryContainer : null,
                                          side: selected ? BorderSide.none : null,
                                          labelStyle: selected
                                              ? TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme.onSecondaryContainer,
                                                )
                                              : const TextStyle(fontSize: 11),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${tariff.rules.length} franja${tariff.rules.length == 1 ? '' : 's'} · ${tariff.active ? 'activa' : 'inactiva'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTariffDetail(PriceTariff tariff) {
    final colorScheme = Theme.of(context).colorScheme;
    final availableToAdd = _availableToAdd;
    final defaultPrices = tariff.memberPartitionPhysicalIds
        .map((id) => _defaultPriceFor(id))
        .whereType<double>()
        .toSet();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(tariff.name, style: Theme.of(context).textTheme.titleMedium)),
                Text(tariff.active ? 'Activa' : 'Inactiva'),
                Switch(value: tariff.active, onChanged: (_) => _toggleTariffActive(tariff)),
                IconButton(onPressed: () => _renameTariff(tariff), icon: const Icon(Icons.edit)),
                IconButton(onPressed: () => _deleteTariff(tariff), icon: const Icon(Icons.delete_outline)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Canchas incluidas', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...tariff.memberPartitionPhysicalIds.map((id) => InputChip(
                      label: Text(_partitionLabel(id)),
                      onDeleted: () => _removeMember(tariff, id),
                      backgroundColor: colorScheme.secondaryContainer,
                      side: BorderSide.none,
                      deleteIconColor: colorScheme.onSecondaryContainer,
                      labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
                    )),
                if (availableToAdd.isNotEmpty)
                  PopupMenuButton<int>(
                    // `PopupMenuButton` se posiciona solo pegado a este botón;
                    // el `showMenu` manual anterior usaba una posición fija
                    // en pantalla (300,300), por eso el menú aparecía
                    // "en cualquier lado" sin relación con el botón.
                    tooltip: 'Agregar cancha',
                    onSelected: (selected) => _addMember(tariff, selected),
                    itemBuilder: (context) => availableToAdd
                        .map((p) => PopupMenuItem<int>(
                              value: p.partitionPhysicalId,
                              child: Text(_partitionLabel(p.partitionPhysicalId)),
                            ))
                        .toList(),
                    child: const Chip(
                      avatar: Icon(Icons.add, size: 18),
                      label: Text('Agregar cancha'),
                    ),
                  ),
              ],
            ),
            const Divider(height: 32),
            Text('Franjas horarias', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            if (tariff.rules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sin franjas: se usa el precio fijo de cada cancha todo el día.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              ...tariff.rules.map((rule) => _buildRuleRow(tariff, rule)),
            const SizedBox(height: 8),
            _buildInlineRuleForm(tariff),
            if (defaultPrices.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Fuera de estas franjas se cobra el precio fijo de cada cancha: '
                        '${defaultPrices.map((p) => '\$${ThousandsFormat.formatPrice(p)}').join(', ')}.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(PriceTariff tariff, PriceRule rule) {
    final colorScheme = Theme.of(context).colorScheme;
    // Franja a la que apunta un acceso directo (ej. "este turno usa esta
    // franja" desde la carga de turnos): se resalta para encontrarla rápido.
    final highlighted = rule.priceRuleId == widget.focusPriceRuleId;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: highlighted ? 8 : 0),
      decoration: highlighted
          ? BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.primary),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...List.generate(7, (index) {
                  final day = index + 1;
                  final selected = rule.daysOfWeek.contains(day);
                  return _dayPill(context, label: _dayLabels[index], selected: selected, size: 24);
                }),
                const SizedBox(width: 8),
                Text('${rule.startTime} – ${rule.endTime}'),
                const SizedBox(width: 12),
                Text('\$${ThousandsFormat.formatPrice(rule.price)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Switch(value: rule.active, onChanged: (_) => _toggleRuleActive(tariff, rule)),
          IconButton(onPressed: () => _editRule(tariff, rule), icon: const Icon(Icons.edit, size: 18)),
        ],
      ),
    );
  }

  Widget _buildInlineRuleForm(PriceTariff tariff) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Form(
        key: _ruleFormKey,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(7, (index) {
                final day = index + 1;
                final selected = _ruleSelectedDays.contains(day);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _dayPill(
                    context,
                    label: _dayLabels[index],
                    selected: selected,
                    size: 30,
                    onTap: () => setState(() {
                      if (selected) {
                        _ruleSelectedDays = {..._ruleSelectedDays}..remove(day);
                      } else {
                        _ruleSelectedDays = {..._ruleSelectedDays, day};
                      }
                    }),
                  ),
                );
              }),
            ),
            SizedBox(
              width: 100,
              child: TimeField(
                controller: _ruleStartController,
                decoration: const InputDecoration(labelText: 'Hora inicio', border: OutlineInputBorder()),
                isDense: true,
                validator: _timeValidator,
              ),
            ),
            SizedBox(
              width: 100,
              child: TimeField(
                controller: _ruleEndController,
                decoration: const InputDecoration(labelText: 'Hora fin', border: OutlineInputBorder()),
                isDense: true,
                validator: _timeValidator,
              ),
            ),
            SizedBox(
              width: 110,
              child: PriceField(
                controller: _rulePriceController,
                decoration: const InputDecoration(labelText: 'Precio', border: OutlineInputBorder()),
                isDense: true,
                validator: (v) {
                  final parsed = ThousandsFormat.parsePrice((v ?? '').trim());
                  return (parsed == null || parsed < 0) ? 'Inválido' : null;
                },
              ),
            ),
            SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: _isCreatingRule ? null : () => _createRule(tariff),
                child: _isCreatingRule
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Agregar franja'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
