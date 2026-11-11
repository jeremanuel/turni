import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/presentation/components/inputs/option_chip.dart';
import '../../../../domain/entities/fiscal/fiscal.dart';
import '../cash_common.dart';
import 'fiscal_common.dart';

enum _Mode { consumerFinal, dni, cuit }

/// A nombre de quién sale un comprobante: consumidor final, con DNI o con
/// CUIT. Lo usan "Corregir" en Comprobantes, el panel Cobrar y la ficha del
/// cliente. [onSubmit] guarda y devuelve el error a mostrar (null si salió
/// bien); el diálogo devuelve true si se guardó.
Future<bool> showFiscalReceiverDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  FiscalReceiver? initial,
  bool allowConsumerFinal = true,
  bool offerSaveToClient = false,
  String? rejection,
  String? warning,
  String confirmLabel = 'Guardar',
  List<FiscalOption> conditions = fiscalIvaConditions,
  required Future<String?> Function(FiscalReceiverInput receiver, bool saveToClient) onSubmit,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _FiscalReceiverDialog(
      title: title,
      subtitle: subtitle,
      initial: initial,
      allowConsumerFinal: allowConsumerFinal,
      offerSaveToClient: offerSaveToClient,
      rejection: rejection,
      warning: warning,
      confirmLabel: confirmLabel,
      conditions: conditions.isEmpty ? fiscalIvaConditions : conditions,
      onSubmit: onSubmit,
    ),
  );
  return saved ?? false;
}

class _FiscalReceiverDialog extends StatefulWidget {
  const _FiscalReceiverDialog({
    required this.title,
    required this.subtitle,
    required this.initial,
    required this.allowConsumerFinal,
    required this.offerSaveToClient,
    required this.rejection,
    required this.warning,
    required this.confirmLabel,
    required this.conditions,
    required this.onSubmit,
  });

  final String title;
  final String? subtitle;
  final FiscalReceiver? initial;
  final bool allowConsumerFinal;
  final bool offerSaveToClient;
  final String? rejection;
  final String? warning;
  final String confirmLabel;
  final List<FiscalOption> conditions;
  final Future<String?> Function(FiscalReceiverInput receiver, bool saveToClient) onSubmit;

  @override
  State<_FiscalReceiverDialog> createState() => _FiscalReceiverDialogState();
}

class _FiscalReceiverDialogState extends State<_FiscalReceiverDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _number = TextEditingController(text: _initialNumber);
  late final _name = TextEditingController(text: widget.initial?.legalName ?? '');
  late final _email = TextEditingController(text: widget.initial?.email ?? '');

  late _Mode _mode = _initialMode;
  late int _condition = _initialCondition;
  bool _saveToClient = true;
  bool _saving = false;
  String? _error;

  _Mode get _initialMode {
    final initial = widget.initial;
    if (initial == null || initial.isConsumerFinal) return widget.allowConsumerFinal ? _Mode.consumerFinal : _Mode.dni;
    return initial.docType == FiscalCodes.docDni ? _Mode.dni : _Mode.cuit;
  }

  String get _initialNumber {
    final initial = widget.initial;
    if (initial == null || initial.isConsumerFinal) return '';
    return initial.docNumber;
  }

  int get _initialCondition {
    final initial = widget.initial;
    if (initial == null || initial.isConsumerFinal || initial.docType == FiscalCodes.docDni) return FiscalCodes.ivaMonotributo;
    return initial.ivaConditionId;
  }

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  FiscalReceiverInput get _input => switch (_mode) {
        _Mode.consumerFinal => const FiscalReceiverInput.consumerFinal(),
        _Mode.dni => FiscalReceiverInput(docType: FiscalCodes.docDni, docNumber: _digits, legalName: _name.text, email: _email.text),
        _Mode.cuit => FiscalReceiverInput(docType: FiscalCodes.docCuit, docNumber: _digits, ivaConditionId: _condition, legalName: _name.text, email: _email.text),
      };

  String get _digits => _number.text.replaceAll(RegExp(r'\D'), '');

  /// Qué clase sale con lo elegido, como orientación (el servidor decide).
  String get _hint => switch (_mode) {
        _Mode.consumerFinal => 'No hace falta ningún dato hasta \$ 10.000.000. Si el cliente necesita deducir el gasto, elegí Con CUIT.',
        _Mode.dni => 'Sale a Consumidor final, identificado con su DNI.',
        _Mode.cuit => 'Si el club es Responsable Inscripto, a un Responsable Inscripto o monotributista le sale Factura A.',
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSubmit(_input, widget.offerSaveToClient && _saveToClient);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  String? _validateNumber(String? _) {
    final digits = _digits;
    if (_mode == _Mode.dni) return RegExp(r'^\d{7,8}$').hasMatch(digits) ? null : 'Revisá el DNI: 7 u 8 números.';
    return digits.length == 11 ? null : 'Revisá el CUIT: 11 números.';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    const gap = SizedBox(height: 14);
    final modes = [
      if (widget.allowConsumerFinal) (_Mode.consumerFinal, 'Consumidor final'),
      (_Mode.dni, 'Con DNI'),
      (_Mode.cuit, 'Con CUIT'),
    ];

    Widget label(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: labelStyle));

    return AlertDialog(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.title),
        if (widget.subtitle != null) Text(widget.subtitle!, style: labelStyle),
      ]),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              if (widget.rejection != null) ...[
                FiscalNotice(tone: StatusTone.danger(scheme), title: 'ARCA lo rechazó', text: widget.rejection!),
                gap,
              ],
              if (widget.warning != null) ...[
                FiscalNotice(tone: StatusTone.warning(scheme), text: widget.warning!),
                gap,
              ],
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (final (index, (mode, text)) in modes.indexed) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Expanded(
                      child: OptionChip(
                        key: ValueKey('fiscal.receiver.mode.${mode.name}'),
                        label: text,
                        selected: _mode == mode,
                        onTap: () => setState(() => _mode = mode),
                      ),
                    ),
                  ],
                ]),
              ),
              gap,
              if (_mode != _Mode.consumerFinal) ...[
                label(_mode == _Mode.dni ? 'DNI' : 'CUIT'),
                TextFormField(
                  key: const ValueKey('fiscal.receiver.number'),
                  controller: _number,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\-. ]'))],
                  decoration: InputDecoration(border: const OutlineInputBorder(), hintText: _mode == _Mode.dni ? 'Sin puntos' : '30-00000000-0'),
                  validator: _validateNumber,
                ),
                gap,
                if (_mode == _Mode.cuit) ...[
                  label('Condición frente al IVA'),
                  DropdownButtonFormField<int>(
                    key: const ValueKey('fiscal.receiver.condition'),
                    initialValue: widget.conditions.any((option) => option.id == _condition) ? _condition : widget.conditions.first.id,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: [for (final option in widget.conditions) DropdownMenuItem(value: option.id, child: Text(option.label, overflow: TextOverflow.ellipsis))],
                    onChanged: (value) => setState(() => _condition = value ?? _condition),
                  ),
                  gap,
                ],
                label(_mode == _Mode.cuit ? 'Razón social' : 'Nombre y apellido'),
                TextFormField(
                  key: const ValueKey('fiscal.receiver.name'),
                  controller: _name,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  validator: (value) => _mode == _Mode.cuit && (value ?? '').trim().isEmpty ? 'Falta la razón social.' : null,
                ),
                gap,
                label('Email (opcional)'),
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(border: OutlineInputBorder())),
                gap,
              ],
              Text(_hint, style: labelStyle),
              if (widget.offerSaveToClient && _mode != _Mode.consumerFinal) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _saveToClient,
                  onChanged: (value) => setState(() => _saveToClient = value ?? false),
                  title: const Text('Guardar en la ficha de este cliente'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(key: const ValueKey('fiscal.receiver.save'), onPressed: _saving ? null : _save, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
