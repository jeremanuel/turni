import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/date_picker/date_dropdown_field.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/presentation/components/onboarding/tour_anchor.dart';
import '../../../../core/presentation/components/permission_lock.dart';
import '../../../../core/services/data_changes.dart';
import '../../../../core/services/fiscal_status.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/permissions.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../domain/entities/fiscal/fiscal.dart';
import '../../../../domain/repositories/fiscal_repository.dart';
import '../../cash/cash_common.dart';
import '../../cash/fiscal/fiscal_common.dart';
import '../widgets/admin_data_table.dart';

const _regimes = [
  ('MONOTRIBUTO', 'Monotributo', 'Emitís Factura C a todos tus clientes.'),
  ('RESPONSABLE_INSCRIPTO', 'Responsable Inscripto', 'Factura B o A según el cliente, con IVA.'),
  ('EXENTO', 'Exento', 'Emitís Factura C a todos tus clientes.'),
];

const _modes = [
  ('AUTOMATIC', 'Automática al cobrar', 'Cada cobro saca su comprobante. Sin datos del cliente sale a Consumidor final, salvo desde \$ 10.000.000, que pide DNI o CUIT.'),
  ('MANUAL', 'Manual', 'Elegís qué cobros facturar desde Caja › Comprobantes. Recomendado para empezar.'),
];

/// Configuración › Facturación: datos fiscales del club, conexión con ARCA y
/// cómo se emiten los comprobantes (docs/feature/FACTURACION_ARCA.md del back).
class FiscalSettingsTab extends StatefulWidget {
  const FiscalSettingsTab({super.key});

  @override
  State<FiscalSettingsTab> createState() => _FiscalSettingsTabState();
}

class _FiscalSettingsTabState extends State<FiscalSettingsTab> with ReloadOnDataChange {
  final _repository = sl<FiscalRepository>();
  final _formKey = GlobalKey<FormState>();
  final _cuit = TextEditingController();
  final _legalName = TextEditingController();
  final _address = TextEditingController();
  final _iibb = TextEditingController();
  final _pointOfSale = TextEditingController();

  FiscalSettings? _settings;
  String _regime = 'MONOTRIBUTO';
  String _mode = 'MANUAL';
  int _ivaRate = 5;
  bool _enabled = false;
  DateTime? _activityStart;
  List<int>? _points;
  bool _dirty = false;
  bool _saving = false;
  bool _connecting = false;
  String? _error;

  static const _edit = [Permissions.CONFIGURACION_FACTURACION];

  bool get _canRead => Permissions.canAny(const [Permissions.CONFIGURACION_FACTURACION, Permissions.FACTURACION_VER]);

  @override
  Set<DataTopic> get refreshTopics => const {DataTopic.cash, DataTopic.clubConfig};

  @override
  void onDataChanged(DataChange change) {
    if (!_dirty) _load();
  }

  @override
  void initState() {
    super.initState();
    if (_canRead) _load();
  }

  @override
  void dispose() {
    for (final controller in [_cuit, _legalName, _address, _iibb, _pointOfSale]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _repository.getSettings();
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Right(:final value):
          _settings = value;
          _fill(value.profile);
          _error = null;
        case Left(:final failure):
          _error = failure.message;
      }
    });
  }

  void _fill(FiscalProfile? profile) {
    _dirty = false;
    if (profile == null) return;
    _regime = profile.regime;
    _cuit.text = _formatCuit(profile.cuit);
    _legalName.text = profile.legalName;
    _address.text = profile.commercialAddress;
    _iibb.text = profile.iibbNumber ?? '';
    _activityStart = profile.activityStart;
    _pointOfSale.text = profile.pointOfSale?.toString() ?? '';
    _mode = profile.emissionMode;
    _ivaRate = profile.defaultIvaRateId;
    _enabled = profile.enabled;
  }

  String _formatCuit(String cuit) => cuit.length == 11 ? '${cuit.substring(0, 2)}-${cuit.substring(2, 10)}-${cuit.substring(10)}' : cuit;

  void _change(VoidCallback update) => setState(() {
        update();
        _dirty = true;
      });

  String _day(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<bool> _save({bool quiet = false}) async {
    if (!_formKey.currentState!.validate()) return false;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await _repository.saveSettings({
      'regime': _regime,
      'cuit': _cuit.text,
      'legal_name': _legalName.text,
      'commercial_address': _address.text,
      'iibb_number': _iibb.text.trim().isEmpty ? null : _iibb.text.trim(),
      'activity_start': _day(_activityStart ?? DateTime.now()),
      'point_of_sale': _pointOfSale.text.trim().isEmpty ? null : int.tryParse(_pointOfSale.text.trim()),
      'emission_mode': _mode,
      'default_iva_rate_id': _ivaRate,
      'enabled': _enabled,
    });
    if (!mounted) return false;
    setState(() => _saving = false);
    switch (result) {
      case Right(:final value):
        FiscalStatus.apply(value.enabled);
        if (!quiet) SnackbarsFunctions.showSuccessSnackbar(context, 'Guardado');
        await _load();
        return true;
      case Left(:final failure):
        setState(() => _error = failure.message);
        return false;
    }
  }

  Future<void> _delegated() async {
    if (_dirty && !await _save(quiet: true)) return;
    setState(() => _connecting = true);
    final result = await _repository.markDelegated();
    if (!mounted) return;
    setState(() => _connecting = false);
    switch (result) {
      case Right():
        _load();
      case Left(:final failure):
        SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
    }
  }

  Future<void> _verify() async {
    if (_dirty && !await _save(quiet: true)) return;
    setState(() => _connecting = true);
    final result = await _repository.verifyConnection();
    if (!mounted) return;
    setState(() => _connecting = false);
    switch (result) {
      case Right(:final value):
        final (profile, points) = value;
        setState(() => _points = points);
        if (profile.isConnected) SnackbarsFunctions.showSuccessSnackbar(context, 'Conexión verificada');
        _load();
      case Left(:final failure):
        SnackbarsFunctions.showErrorsSnackbar(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final padding = EdgeInsets.all(ResponsiveBuilder.isMobile(context) ? 16 : 24);
    if (!_canRead) return Padding(padding: padding, child: const CashMessage('Tu rol no puede ver la facturación.'));
    final settings = _settings;
    if (settings == null) {
      if (_error != null) return Center(child: CashMessage(_error!, onRetry: _load));
      return const LinearProgressIndicator();
    }
    final profile = settings.profile;

    return SingleChildScrollView(
      padding: padding,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const ReadOnlyNotice(permissions: _edit),
              if (settings.isSimulated) ...[
                FiscalNotice(
                  key: const ValueKey('fiscal.config.simulated'),
                  tone: StatusTone.primary(scheme),
                  title: 'Modo de prueba',
                  text: 'Este establecimiento factura contra un simulador de ARCA: la conexión se verifica sola y los comprobantes no tienen validez fiscal.',
                ),
                const SizedBox(height: 16),
              ],
              PermissionLock(
                permissions: _edit,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  TourAnchor(id: 'fiscal.config.regime', child: _regimeCard(context)),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, constraints) {
                    final data = _dataCard(context);
                    final connection = TourAnchor(id: 'fiscal.config.connection', child: _connectionCard(context, settings, profile));
                    if (constraints.maxWidth < 760) return Column(children: [data, const SizedBox(height: 16), connection]);
                    return IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(child: data),
                        const SizedBox(width: 16),
                        Expanded(child: connection),
                      ]),
                    );
                  }),
                  const SizedBox(height: 16),
                  TourAnchor(id: 'fiscal.config.emission', child: _emissionCard(context, settings, profile)),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, key: const ValueKey('fiscal.config.error'), style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(key: const ValueKey('fiscal.config.save'), onPressed: _saving ? null : _save, child: const Text('Guardar')),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              _matrixCard(context),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required String title, Widget? trailing, required List<Widget> children}) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(title, style: textTheme.titleMedium)),
            if (trailing != null) trailing,
          ]),
          const SizedBox(height: 12),
          ...children,
        ]),
      ),
    );
  }

  Widget _choiceCards(BuildContext context, List<(String, String, String)> options, String selected, ValueChanged<String> onSelected, String keyPrefix) {
    final scheme = Theme.of(context).colorScheme;
    Widget card((String, String, String) option) {
      final (code, title, description) = option;
      final isSelected = code == selected;
      return Material(
        color: isSelected ? scheme.secondaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isSelected ? scheme.primary : scheme.outlineVariant),
        ),
        child: InkWell(
          key: ValueKey('$keyPrefix.$code'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelected(code),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? scheme.onSecondaryContainer : scheme.onSurface)),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(fontSize: 13, height: 18 / 13, color: isSelected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant)),
            ]),
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 240.0 * options.length) {
        return Column(children: [
          for (final (index, option) in options.indexed) ...[if (index > 0) const SizedBox(height: 8), SizedBox(width: double.infinity, child: card(option))],
        ]);
      }
      return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (index, option) in options.indexed) ...[if (index > 0) const SizedBox(width: 8), Expanded(child: card(option))],
        ]),
      );
    });
  }

  Widget _regimeCard(BuildContext context) => _card(context, title: 'Condición frente a ARCA', children: [
        _choiceCards(context, _regimes, _regime, (code) => _change(() => _regime = code), 'fiscal.config.regime'),
      ]);

  Widget _field(BuildContext context, String label, TextEditingController controller,
      {String? Function(String?)? validator, String? hint, TextInputType? keyboard, List<TextInputFormatter>? formatters, Key? key}) {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      const SizedBox(height: 6),
      TextFormField(
        key: key,
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatters,
        validator: validator,
        onChanged: (_) => _dirty = true,
        decoration: InputDecoration(border: const OutlineInputBorder(), hintText: hint),
      ),
    ]);
  }

  String? _required(String? value) => (value ?? '').trim().isEmpty ? 'Completá este dato.' : null;

  Widget _dataCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    Widget pair(Widget a, Widget b) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]);
    return _card(context, title: 'Datos fiscales', children: [
      pair(
        _field(context, 'CUIT', _cuit,
            key: const ValueKey('fiscal.config.cuit'),
            hint: '30-00000000-0',
            keyboard: TextInputType.number,
            formatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\-]'))],
            validator: (value) => (value ?? '').replaceAll(RegExp(r'\D'), '').length == 11 ? null : 'El CUIT tiene 11 números.'),
        _field(context, 'Razón social', _legalName, key: const ValueKey('fiscal.config.legalName'), validator: _required),
      ),
      const SizedBox(height: 12),
      _field(context, 'Domicilio comercial', _address, key: const ValueKey('fiscal.config.address'), validator: _required),
      const SizedBox(height: 12),
      pair(
        _field(context, 'Ingresos Brutos', _iibb),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Inicio de actividades', style: labelStyle),
          const SizedBox(height: 6),
          DateDropdownField(
            value: _activityStart ?? DateTime.now(),
            lastDate: DateTime.now(),
            firstDate: DateTime(1950),
            format: (date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
            onChanged: (date) => _change(() => _activityStart = date),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      _field(context, 'Punto de venta para Turni', _pointOfSale,
          key: const ValueKey('fiscal.config.pointOfSale'),
          hint: 'Ej. 5',
          keyboard: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)]),
      const SizedBox(height: 6),
      Text(
        _points == null || _points!.isEmpty
            ? 'Uno de web services, que uses solo con Turni.'
            : 'Habilitados en ARCA: ${_points!.map((point) => point.toString().padLeft(4, '0')).join(', ')}.',
        style: labelStyle,
      ),
    ]);
  }

  Widget _connectionCard(BuildContext context, FiscalSettings settings, FiscalProfile? profile) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 13, height: 20 / 13, color: scheme.onSurfaceVariant);
    final status = profile?.connectionStatus ?? 'NOT_CONNECTED';
    final (label, tone) = switch (status) {
      'ACTIVE' => ('Conectada', StatusTone.success(scheme)),
      'PENDING_TURNI' || 'VERIFYING' => ('Verificando', StatusTone.primary(scheme)),
      'BLOCKED' => ('Desconectada', StatusTone.danger(scheme)),
      _ => ('Sin conectar', StatusTone.neutral(scheme)),
    };
    final busy = _connecting || _saving;
    final children = <Widget>[];

    if (!settings.providerReady) {
      children.add(FiscalNotice(
        tone: StatusTone.warning(scheme),
        text: 'La conexión con ARCA todavía no está disponible. Podés dejar cargados los datos: te avisamos cuando se pueda conectar.',
      ));
      children.add(const SizedBox(height: 12));
    }

    switch (status) {
      case 'ACTIVE':
        children.addAll([
          Text('Turni emite por el CUIT del club. Podés quitar el permiso cuando quieras desde ARCA.', style: muted),
          if (profile?.connectionCheckedAt case final checked?) ...[
            const SizedBox(height: 8),
            Text('Último chequeo: ${cashDay(checked)} a las ${cashTime(checked)}.', style: muted),
          ],
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: OutlinedButton(onPressed: busy ? null : _verify, child: const Text('Verificar conexión'))),
        ]);
      case 'PENDING_TURNI' || 'VERIFYING':
        children.addAll([
          Text('Recibimos tu autorización. Mientras tanto, tus cobros se siguen registrando.', style: muted),
          if (profile?.connectionError case final error?) ...[
            const SizedBox(height: 10),
            FiscalNotice(tone: StatusTone.warning(scheme), text: error),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(key: const ValueKey('fiscal.config.verify'), onPressed: busy || !settings.providerReady ? null : _verify, child: const Text('Verificar ahora')),
          ),
        ]);
      case 'BLOCKED':
        children.addAll([
          Text('ARCA dejó de aceptar a Turni para este CUIT. Puede que se haya quitado el permiso.', style: muted),
          const SizedBox(height: 10),
          FiscalNotice(tone: StatusTone.warning(scheme), text: 'No se perdió ningún cobro: los comprobantes salen cuando vuelva la conexión.'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            FilledButton(onPressed: busy ? null : _delegated, child: const Text('Volver a conectar')),
            TextButton(onPressed: busy || !settings.providerReady ? null : _verify, child: const Text('Verificar')),
          ]),
        ]);
      default:
        children.addAll(_guide(context, settings, profile, busy));
    }

    return _card(
      context,
      title: 'Conexión con ARCA',
      trailing: CashTag(key: const ValueKey('fiscal.config.connectionStatus'), label: label, tone: tone),
      children: children,
    );
  }

  List<Widget> _guide(BuildContext context, FiscalSettings settings, FiscalProfile? profile, bool busy) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 13, height: 19 / 13, color: scheme.onSurfaceVariant);
    final cuit = settings.representativeCuit;
    Widget step(int number, String title, Widget body) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 13, backgroundColor: scheme.primary, child: Text('$number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onPrimary))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                body,
              ]),
            ),
          ]),
        );
    return [
      Text('Lo hacés una sola vez, con la clave fiscal de quien administra el CUIT del club. Turni nunca ve tu clave.', style: muted),
      const SizedBox(height: 12),
      step(
        1,
        'Autorizá a Turni',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('En ARCA, abrí Administrador de Relaciones y elegí el CUIT del club, no el tuyo. Tocá Nueva Relación y buscá Facturación Electrónica (web services).', style: muted),
          const SizedBox(height: 6),
          if (cuit != null)
            Row(children: [
              Expanded(child: Text('En Representante, cargá $cuit', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: cuit));
                  if (context.mounted) SnackbarsFunctions.showSuccessSnackbar(context, 'CUIT copiado');
                },
                child: const Text('Copiar'),
              ),
            ])
          else
            Text('En Representante va el CUIT de Turni: te lo pasamos al activar la facturación.', style: muted),
        ]),
      ),
      step(2, 'Creá un punto de venta para Turni',
          Text('En Administración de Puntos de Venta, sumá uno de web services y cargá su número acá al lado. Usalo solo con Turni: si emitís con otro sistema en ese punto, se rompe la numeración.', style: muted)),
      step(3, 'Avisanos', Text('Turni acepta tu autorización y verifica la conexión. Puede tardar hasta 12 horas.', style: muted)),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          key: const ValueKey('fiscal.config.delegated'),
          onPressed: busy || profile == null ? null : _delegated,
          child: const Text('Ya lo hice'),
        ),
      ),
      if (profile == null) ...[
        const SizedBox(height: 6),
        Text('Primero guardá los datos fiscales.', style: muted, textAlign: TextAlign.right),
      ],
    ];
  }

  Widget _emissionCard(BuildContext context, FiscalSettings settings, FiscalProfile? profile) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final connected = profile?.isConnected ?? false;
    final rates = settings.options.ivaRates;
    return _card(context, title: 'Emisión', children: [
      _choiceCards(context, _modes, _mode, (code) => _change(() => _mode = code), 'fiscal.config.mode'),
      if (_regime == 'RESPONSABLE_INSCRIPTO' && rates.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('IVA de turnos y servicios', style: labelStyle),
        const SizedBox(height: 6),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int>(
            initialValue: rates.any((rate) => rate.id == _ivaRate) ? _ivaRate : rates.first.id,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [for (final rate in rates) DropdownMenuItem(value: rate.id, child: Text(rate.label))],
            onChanged: (value) => _change(() => _ivaRate = value ?? _ivaRate),
          ),
        ),
        const SizedBox(height: 6),
        Text('Los precios incluyen el IVA. Cada producto puede tener su propia alícuota en Productos.', style: labelStyle),
      ],
      const SizedBox(height: 12),
      SwitchListTile(
        key: const ValueKey('fiscal.config.enabled'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Facturar los cobros'),
        subtitle: Text(
          connected
              ? 'Solo se facturan los cobros desde que la prendés: lo anterior no.'
              : 'Se prende cuando la conexión con ARCA esté verificada.',
          style: labelStyle,
        ),
        value: _enabled,
        onChanged: connected || _enabled ? (value) => _change(() => _enabled = value) : null,
      ),
    ]);
  }

  Widget _matrixCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    const columns = ['Consumidor final', 'Monotributo', 'Resp. Inscripto', 'Exento', 'No categorizado', 'No alcanzado'];
    const rows = [
      ('Monotributo', ['C', 'C', 'C', 'C', 'C', 'C']),
      ('Responsable Inscripto', ['B', 'A', 'A', 'B', 'B', 'B']),
      ('Exento', ['C', 'C', 'C', 'C', 'C', 'C']),
    ];
    return AdminTableCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 12, runSpacing: 8, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('Qué comprobante sale', style: Theme.of(context).textTheme.titleMedium),
          CashTag(label: 'A validar con un contador', tone: StatusTone.neutral(scheme)),
        ]),
        const SizedBox(height: 12),
        AdminDataTable(
          columns: const ['Club \\ Cliente', ...columns],
          defaultColumnWidth: const FlexColumnWidth(),
          columnWidths: const {0: FlexColumnWidth(1.4)},
          rows: [
            for (final (regime, values) in rows)
              [
                Text(regime, style: TextStyle(fontWeight: _regimeLabel == regime ? FontWeight.w600 : null)),
                for (final value in values) Center(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
              ],
          ],
        ),
        const SizedBox(height: 12),
        Text('La Factura A a un monotributista lleva una leyenda de crédito fiscal. El cliente se carga como Responsable Inscripto o monotributista con su CUIT; si no, sale a Consumidor final.', style: muted),
      ]),
    );
  }

  String get _regimeLabel => _regimes.firstWhere((regime) => regime.$1 == _regime).$2;
}
