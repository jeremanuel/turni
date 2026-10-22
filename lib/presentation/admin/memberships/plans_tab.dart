import 'package:flutter/material.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../core/presentation/components/permission_lock.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../core/utils/thousands_format.dart';
import '../../../domain/entities/membership/membership.dart';
import '../../../domain/repositories/membership_repository.dart';
import '../club_config/widgets/admin_data_table.dart';
import '../club_config/widgets/price_field.dart';
import 'widgets/membership_widgets.dart';

/// Configuración › Abonos: cómo se vende cada servicio con abonos con cuotas
/// (gimnasio, funcional). Solo aparece si el admin ve alguno (ver
/// `AdminFeatures.memberships`).
class MembershipPlansTab extends StatefulWidget {
  const MembershipPlansTab({super.key});

  @override
  State<MembershipPlansTab> createState() => _MembershipPlansTabState();
}

class _MembershipPlansTabState extends State<MembershipPlansTab> {
  final _repository = sl<MembershipRepository>();
  List<MembershipPlansPartition>? _partitions;
  String? _error;

  bool get _canEdit => Permissions.can(Permissions.CONFIGURACION_ABONOS);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repository.plans();
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Right(:final value):
          _partitions = value;
          _error = null;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  Future<void> _edit({MembershipPlan? plan, MembershipPartition? partition}) async {
    final partitions = _partitions?.map((p) => p.partition).toList() ?? const <MembershipPartition>[];
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => MembershipPlanDialog(partitions: partitions, plan: plan, initialPartition: partition),
    );
    if (saved == true) _load();
  }

  Future<void> _archive(MembershipPlan plan) async {
    final result = await _repository.archivePlan(plan.id, archived: !plan.archived);
    if (!mounted) return;
    result.when(
      left: (failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (_) => _load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final partitions = _partitions;
    final padding = ResponsiveBuilder.isMobile(context) ? 16.0 : 24.0;

    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!),
        const SizedBox(height: 8),
        TextButton(onPressed: _load, child: const Text('Reintentar')),
      ]));
    }
    if (partitions == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: EdgeInsets.all(padding),
      children: [
        const ReadOnlyNotice(permissions: [Permissions.CONFIGURACION_ABONOS]),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          alignment: WrapAlignment.spaceBetween,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Abonos', style: textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Cómo se vende cada servicio de gimnasio. Cada pago de un cliente queda atado a su abono y de ahí sale si está al día.',
                  style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ]),
            ),
            if (_canEdit) FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Nuevo abono')),
          ],
        ),
        const SizedBox(height: 16),
        for (final partition in partitions) ...[
          _PartitionCard(
            partition: partition,
            canEdit: _canEdit,
            onEdit: (plan) => _edit(plan: plan),
            onCreate: () => _edit(partition: partition.partition),
            onArchive: _archive,
          ),
          const SizedBox(height: 16),
        ],
        const _RemindersCard(),
      ],
    );
  }
}

class _PartitionCard extends StatelessWidget {
  const _PartitionCard({required this.partition, required this.canEdit, required this.onEdit, required this.onCreate, required this.onArchive});

  final MembershipPlansPartition partition;
  final bool canEdit;
  final ValueChanged<MembershipPlan> onEdit;
  final VoidCallback onCreate;
  final ValueChanged<MembershipPlan> onArchive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final plans = partition.plans;
    final summary = partition.clients == 0
        ? 'Todavía nadie tiene un abono de este servicio'
        : '${partition.clients} ${partition.clients == 1 ? 'cliente' : 'clientes'} con abono${partition.late > 0 ? ' · ${partition.late} con cuotas vencidas' : ' · al día'}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(label: Text(partition.partition.typeName), backgroundColor: scheme.secondaryContainer, side: BorderSide.none),
                Text(partition.partition.name, style: textTheme.titleMedium),
                Text(summary, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 14),
            if (plans.isEmpty)
              Row(children: [
                Expanded(child: Text('Este servicio todavía no tiene abonos.', style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))),
                if (canEdit) OutlinedButton(onPressed: onCreate, child: const Text('Crear el primero')),
              ])
            else
              AdminDataTable(
                columns: const ['Abono', 'Frecuencia', 'Precio', 'Vence', 'Clientes', 'Estado de cuotas', ''],
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(1.1),
                  2: FlexColumnWidth(),
                  3: FlexColumnWidth(1.1),
                  4: FlexColumnWidth(0.7),
                  5: FlexColumnWidth(1.8),
                  6: FixedColumnWidth(96),
                },
                rows: [
                  for (final plan in plans)
                    [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(plan.name, style: TextStyle(fontWeight: FontWeight.w500, color: plan.archived ? scheme.outline : null)),
                        Text(plan.archived ? 'Ya no se vende' : 'Mensual', style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ]),
                      Text(plan.frequencyLabel),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(money(plan.price), style: const TextStyle(fontWeight: FontWeight.w500)),
                        if (plan.previousPrice != null)
                          Text('antes ${money(plan.previousPrice!)}', style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))
                        else if (plan.priceSince != null)
                          Text('desde el ${dayLabel(plan.priceSince!)}', style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ]),
                      Text(plan.dueLabel),
                      Text('${plan.clients}'),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        for (final status in const [MembershipStatus.ok, MembershipStatus.soon, MembershipStatus.late, MembershipStatus.pendingFirst, MembershipStatus.paused])
                          if ((plan.counts[status] ?? 0) > 0)
                            MembershipStatusChip(status: status, label: _countLabel(status, plan.counts[status]!)),
                        if (plan.clients == 0) Text('—', style: TextStyle(color: scheme.outline)),
                      ]),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (canEdit) ...[
                          IconButton(tooltip: 'Editar ${plan.name}', icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => onEdit(plan)),
                          PopupMenuButton<String>(
                            tooltip: 'Más opciones de ${plan.name}',
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (_) => onArchive(plan),
                            itemBuilder: (_) => [PopupMenuItem(value: 'archive', child: Text(plan.archived ? 'Volver a vender' : 'Dejar de vender'))],
                          ),
                        ],
                      ]),
                    ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  static String _countLabel(MembershipStatus status, int n) => switch (status) {
        MembershipStatus.ok => '$n al día',
        MembershipStatus.soon => n == 1 ? '1 vence pronto' : '$n vencen pronto',
        MembershipStatus.late => n == 1 ? '1 vencido' : '$n vencidos',
        MembershipStatus.pendingFirst => n == 1 ? '1 sin primer pago' : '$n sin primer pago',
        MembershipStatus.paused => n == 1 ? '1 en pausa' : '$n en pausa',
        MembershipStatus.ended => '$n',
      };
}

/// Recordatorios automáticos del club (notificación en la app).
class _RemindersCard extends StatefulWidget {
  const _RemindersCard();

  @override
  State<_RemindersCard> createState() => _RemindersCardState();
}

class _RemindersCardState extends State<_RemindersCard> {
  final _repository = sl<MembershipRepository>();
  MembershipSettings? _settings;

  @override
  void initState() {
    super.initState();
    _repository.settings().then((result) {
      if (!mounted) return;
      result.when(left: (_) {}, right: (value) => setState(() => _settings = value));
    });
  }

  Future<void> _save(MembershipSettings settings) async {
    final previous = _settings;
    setState(() => _settings = settings);
    final result = await _repository.saveSettings(settings);
    if (!mounted) return;
    result.when(
      left: (failure) {
        setState(() => _settings = previous);
        SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
      },
      right: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    if (settings == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: PermissionLock(
          permissions: const [Permissions.CONFIGURACION_ABONOS],
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Recordatorios automáticos', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Valen para todos los clientes con abono que tienen la app. Se mandan como notificación, una sola vez por cuota; nunca a un abono en pausa.',
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('3 días antes de que venza'),
              value: settings.beforeDue,
              onChanged: (v) => _save(settings.copyWith(beforeDue: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('El día que vence'),
              value: settings.dueDay,
              onChanged: (v) => _save(settings.copyWith(dueDay: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cuando pasa a vencida (después de la gracia)'),
              value: settings.overdue,
              onChanged: (v) => _save(settings.copyWith(overdue: v)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Alta y edición de un abono.
class MembershipPlanDialog extends StatefulWidget {
  const MembershipPlanDialog({super.key, required this.partitions, this.plan, this.initialPartition});

  final List<MembershipPartition> partitions;
  final MembershipPlan? plan;
  final MembershipPartition? initialPartition;

  @override
  State<MembershipPlanDialog> createState() => _MembershipPlanDialogState();
}

class _MembershipPlanDialogState extends State<MembershipPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.plan?.name ?? '');
  late final _price = TextEditingController(text: widget.plan == null ? '' : ThousandsFormat.formatPrice(widget.plan!.price));
  late final _billingDay = TextEditingController(text: '${widget.plan?.billingDay ?? 10}');
  late final _graceDays = TextEditingController(text: '${widget.plan?.graceDays ?? 5}');
  late int? _partitionId = widget.plan?.partitionId ?? widget.initialPartition?.id ?? widget.partitions.firstOrNull?.id;
  late int? _days = widget.plan == null ? 3 : widget.plan!.daysPerWeek;
  late BillingMode _mode = widget.plan?.billingMode ?? BillingMode.fixedDay;
  bool _nameTouched = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameTouched = widget.plan != null;
    if (widget.plan == null) _name.text = _defaultName();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _billingDay.dispose();
    _graceDays.dispose();
    super.dispose();
  }

  String _defaultName() => _days == null ? 'Pase libre' : '$_days ${_days == 1 ? 'vez' : 'veces'} por semana';

  void _setDays(int? days) {
    setState(() {
      _days = days;
      if (!_nameTouched) _name.text = _defaultName();
    });
  }

  String _example() {
    final price = ThousandsFormat.parsePrice(_price.text.trim());
    final priceText = price == null ? 'la cuota' : money(price);
    final day = int.tryParse(_billingDay.text) ?? 10;
    final grace = int.tryParse(_graceDays.text) ?? 5;
    final name = _name.text.trim().isEmpty ? 'este abono' : '"${_name.text.trim()}"';
    if (_mode == BillingMode.fixedDay) {
      return 'Si alguien arranca $name el 15 de octubre, paga $priceText y queda al día hasta el $day de noviembre. Desde ahí vence el $day de cada mes, con $grace días de gracia.';
    }
    return 'Si alguien arranca $name el 15 de octubre, paga $priceText y queda al día hasta el 15 de noviembre. Vence el 15 de cada mes, con $grace días de gracia.';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _partitionId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await sl<MembershipRepository>().savePlan({
      'club_partition_id': _partitionId,
      'name': _name.text.trim(),
      'days_per_week': _days,
      'billing_mode': billingModeToJson(_mode),
      'billing_day': int.tryParse(_billingDay.text) ?? 10,
      'grace_days': int.tryParse(_graceDays.text) ?? 5,
      'price': ThousandsFormat.parsePrice(_price.text.trim()),
    }, planId: widget.plan?.id);
    if (!mounted) return;
    result.when(
      left: (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      right: (_) => Navigator.of(context).pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final editing = widget.plan != null;

    InputDecoration field(String label, {String? helper}) =>
        InputDecoration(labelText: label, helperText: helper, helperMaxLines: 2, border: const OutlineInputBorder());

    return AlertDialog(
      title: Text(editing ? 'Editar abono' : 'Nuevo abono'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _partitionId,
                      decoration: field('Servicio'),
                      items: [for (final p in widget.partitions) DropdownMenuItem(value: p.id, child: Text(p.name))],
                      onChanged: editing ? null : (value) => setState(() => _partitionId = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _name,
                      decoration: field('Nombre'),
                      onChanged: (_) => _nameTouched = true,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Ponele un nombre' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Text('¿Cuántos días por semana puede venir?', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final option in const [1, 2, 3, 4, 5, 6, null])
                    ChoiceChip(
                      label: Text(option == null ? 'Libre' : '$option'),
                      selected: _days == option,
                      showCheckmark: false,
                      onSelected: (_) => _setDays(option),
                    ),
                ]),
                const SizedBox(height: 4),
                Text('Es lo que le vendés.', style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 20),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: PriceField(
                      controller: _price,
                      decoration: field('Precio por mes', helper: editing ? 'Un precio nuevo vale para las cuotas que arrancan desde hoy.' : null),
                      validator: (v) {
                        final parsed = ThousandsFormat.parsePrice((v ?? '').trim());
                        return parsed == null || parsed <= 0 ? 'Poné el precio' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _graceDays,
                      keyboardType: TextInputType.number,
                      decoration: field('Días de gracia', helper: 'Después del vencimiento, pasa a "Vencido".'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n == null || n < 0 || n > 30 ? 'De 0 a 30' : null;
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Text('¿Cuándo vence la cuota?', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                RadioGroup<BillingMode>(
                  groupValue: _mode,
                  onChanged: (value) => setState(() => _mode = value ?? _mode),
                  child: Column(children: [
                    RadioListTile<BillingMode>(
                      value: BillingMode.fixedDay,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('El mismo día para todos'),
                      subtitle: const Text('Todos pagan juntos. El primer mes se cobra completo.'),
                    ),
                    if (_mode == BillingMode.fixedDay)
                      Padding(
                        padding: const EdgeInsets.only(left: 48, bottom: 8),
                        child: SizedBox(
                          width: 180,
                          child: TextFormField(
                            controller: _billingDay,
                            keyboardType: TextInputType.number,
                            decoration: field('Día del mes'),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              return n == null || n < 1 || n > 28 ? 'Del 1 al 28' : null;
                            },
                          ),
                        ),
                      ),
                    RadioListTile<BillingMode>(
                      value: BillingMode.anniversary,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('A un mes de cuando empezó cada cliente'),
                      subtitle: const Text('Si arrancó el 15, vence el 15 de cada mes.'),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline, size: 18, color: scheme.onPrimaryContainer),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_example(), style: textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer))),
                  ]),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: scheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(editing ? 'Guardar' : 'Crear abono'),
        ),
      ],
    );
  }
}
