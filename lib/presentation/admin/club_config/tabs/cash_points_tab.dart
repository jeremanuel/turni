import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/presentation/components/onboarding/tour_anchor.dart';
import '../../../../core/presentation/components/permission_lock.dart';
import '../../../../core/services/cash_status.dart';
import '../../../../core/services/data_changes.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/cash/cash.dart';
import '../../../../domain/entities/club_map/club_map.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/repositories/cash_repository.dart';
import '../../../../domain/repositories/club_map_repository.dart';
import '../../../../domain/repositories/club_partition_admin_repository.dart';
import '../../cash/cash_common.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/cash_point_dialog.dart';
import '../widgets/price_field.dart';

/// Configuración › Cajas: si el establecimiento usa caja y sus puestos.
class CashPointsTab extends StatefulWidget {
  const CashPointsTab({super.key});

  @override
  State<CashPointsTab> createState() => _CashPointsTabState();
}

class _CashPointsTabState extends State<CashPointsTab> with ReloadOnDataChange {
  final _repository = sl<CashRepository>();
  final _tolerance = TextEditingController();

  CashOverview? _overview;
  List<ClubPartition> _partitions = const [];
  ClubMapView? _map;
  Future<void>? _spacesLoaded;
  bool _enabled = false;
  bool _requireOpen = true;
  bool _blindClose = false;
  bool _saving = false;
  bool _dirty = false;
  String? _error;

  static const _edit = [Permissions.CONFIGURACION_CAJAS];

  bool get _canRead => Permissions.canAny(const [Permissions.CAJA_VER, Permissions.CONFIGURACION_CAJAS]);

  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.cash};

  // Con cambios a medio guardar no se pisa el formulario.
  @override
  void onDataChanged(DataChange change) {
    if (!_dirty) _load();
  }

  @override
  void initState() {
    super.initState();
    if (!_canRead) return;
    _load();
    _spacesLoaded = _loadSpaces();
  }

  @override
  void dispose() {
    _tolerance.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _repository.getOverview();
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Right(:final value):
          _overview = value;
          _enabled = value.settings.enabled;
          _requireOpen = value.settings.requireOpenForCash;
          _blindClose = value.settings.blindClose;
          _tolerance.text = ThousandsFormat.formatPrice(value.settings.tolerance);
          _dirty = false;
          _error = null;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  Future<void> _loadSpaces() async {
    final repository = sl<ClubPartitionAdminRepository>();
    final listed = await repository.listClubPartitions(includeInactive: false);
    // La lista de servicios no trae sus espacios: se piden por servicio.
    final partitions = <ClubPartition>[];
    if (listed case Right(:final value)) {
      for (final partition in value) {
        final spaces = await repository.listPartitionPhysical(partition.club_partition_id!, includeInactive: false);
        partitions.add(switch (spaces) {
          Right(:final value) => partition.copyWith(physicalPartitions: value),
          Left() => partition,
        });
      }
    }
    final map = await sl<ClubMapRepository>().getClubMap();
    if (!mounted) return;
    setState(() {
      _partitions = partitions;
      if (map case Right(:final value)) _map = value;
    });
  }

  void _change(VoidCallback update) => setState(() {
        update();
        _dirty = true;
      });

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await _repository.saveSettings(CashSettings(
      enabled: _enabled,
      requireOpenForCash: _requireOpen,
      blindClose: _blindClose,
      tolerance: ThousandsFormat.parsePrice(_tolerance.text) ?? 0,
    ));
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Right(:final value):
        CashStatus.apply(value);
        SnackbarsFunctions.showSuccessSnackbar(context, 'Guardado');
        _load();
      case Left(:final failure):
        setState(() => _error = failure.message);
    }
  }

  Future<void> _editPoint(CashPoint? point) async {
    // El diálogo necesita los espacios y el plano ya cargados.
    await _spacesLoaded;
    if (!mounted) return;
    final saved = await showCashPointDialog(context, point: point, points: _overview?.points ?? const [], partitions: _partitions, map: _map);
    if (saved) _load();
  }

  Set<int> get _assigned => {
        for (final point in _overview?.points ?? const <CashPoint>[])
          if (point.active) ...point.spaces.map((space) => space.partitionPhysicalId),
      };

  int get _withoutPoint {
    final assigned = _assigned;
    var count = 0;
    for (final partition in _partitions) {
      for (final space in partition.physicalPartitions ?? const []) {
        if (space.active != false && !assigned.contains(space.partitionPhysicalId)) count++;
      }
    }
    return count;
  }

  String _today(CashPoint point, ColorScheme scheme) {
    final shift = point.openShift;
    if (!point.active) return 'Desactivado';
    if (shift == null) return 'Cerrada';
    final expected = shift.expectedAmount;
    return expected == null ? 'Abierta' : 'Abierta · ${cashMoney(expected)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final padding = EdgeInsets.all(ResponsiveBuilder.isMobile(context) ? 16 : 24);

    if (!_canRead) return Padding(padding: padding, child: const CashMessage('Tu rol no puede ver la configuración de caja.'));
    final overview = _overview;
    if (overview == null) {
      if (_error != null) return Center(child: CashMessage(_error!, onRetry: _load));
      return const LinearProgressIndicator();
    }

    final labelStyle = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final withoutPoint = _withoutPoint;

    Widget toggle(String title, String subtitle, bool value, ValueChanged<bool>? onChanged, {Key? key}) => SwitchListTile(
          key: key,
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          subtitle: Text(subtitle, style: labelStyle),
          value: value,
          onChanged: onChanged,
        );

    return SingleChildScrollView(
      padding: padding,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const ReadOnlyNotice(permissions: _edit),
            TourAnchor(
              id: 'cash.config.settings',
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: PermissionLock(
                    permissions: _edit,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Gestión de caja', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      toggle('Usar caja en este establecimiento', 'Suma el menú Caja y cada cobro en efectivo entra en un puesto.', _enabled,
                          (value) => _change(() => _enabled = value), key: const ValueKey('cash.config.enabled')),
                      if (_enabled) ...[
                        toggle('Pedir caja abierta para cobrar en efectivo', 'Sin una caja abierta, el efectivo no se puede registrar.', _requireOpen,
                            (value) => _change(() => _requireOpen = value)),
                        toggle('Arqueo ciego', 'Quien cierra cuenta el efectivo sin ver cuánto debería haber.', _blindClose,
                            (value) => _change(() => _blindClose = value)),
                        const SizedBox(height: 8),
                        Text('Tolerancia de diferencia', style: labelStyle),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 220,
                          child: PriceField(
                            controller: _tolerance,
                            decoration: const InputDecoration(prefixText: '\$ ', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Si la diferencia del cierre la supera, hay que explicar qué pasó y se avisa a quien supervisa.', style: labelStyle),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: TextStyle(color: scheme.error)),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(key: const ValueKey('cash.config.save'), onPressed: _saving ? null : _save, child: const Text('Guardar')),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TourAnchor(
              id: 'cash.config.points',
              child: AdminTableCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Puestos', style: textTheme.titleMedium),
                    PermissionLock(
                      permissions: _edit,
                      hide: true,
                      child: FilledButton(key: const ValueKey('cash.config.newPoint'), onPressed: () => _editPoint(null), child: const Text('Nuevo puesto')),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (withoutPoint > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: StatusTone.warning(scheme).background, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        withoutPoint == 1 ? 'Hay 1 espacio sin puesto: cobra en el puesto principal.' : 'Hay $withoutPoint espacios sin puesto: cobran en el puesto principal.',
                        style: TextStyle(color: StatusTone.warning(scheme).foreground),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (overview.points.isEmpty)
                    const CashMessage('Todavía no hay puestos.')
                  else
                    AdminDataTable(
                      columns: const ['Puesto', 'Espacios que gestiona', 'Hoy', ''],
                      defaultColumnWidth: const FlexColumnWidth(),
                      columnWidths: const {1: FlexColumnWidth(2), 3: FixedColumnWidth(96)},
                      rows: [
                        for (final point in overview.points)
                          [
                            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                              Text(point.name),
                              if (point.isPrimary) CashTag(label: 'Principal', tone: StatusTone.primary(scheme)),
                            ]),
                            Text(cashSpacesLabel(point.spaces)),
                            Text(_today(point, scheme)),
                            PermissionLock(
                              permissions: _edit,
                              hide: true,
                              child: TextButton(key: ValueKey('cash.config.edit.${point.name}'), onPressed: () => _editPoint(point), child: const Text('Editar')),
                            ),
                          ],
                      ],
                    ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
