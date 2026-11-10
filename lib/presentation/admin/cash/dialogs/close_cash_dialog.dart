import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/cash/cash.dart';
import '../../../../domain/repositories/cash_repository.dart';
import '../../club_config/widgets/price_field.dart';
import '../cash_common.dart';

const _bills = [20000, 10000, 2000, 1000, 500];

/// Cierre de una caja: contar, ver el resultado y confirmar. En arqueo ciego
/// el esperado recién aparece con el cierre ya hecho. Devuelve true si cerró.
Future<bool> showCloseCashDialog(BuildContext context, {required String shiftId, required String pointName, required double tolerance}) async {
  final closed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CloseCashDialog(shiftId: shiftId, pointName: pointName, tolerance: tolerance),
  );
  return closed ?? false;
}

enum _Step { count, result, done }

class _CloseCashDialog extends StatefulWidget {
  const _CloseCashDialog({required this.shiftId, required this.pointName, required this.tolerance});

  final String shiftId;
  final String pointName;
  final double tolerance;

  @override
  State<_CloseCashDialog> createState() => _CloseCashDialogState();
}

class _CloseCashDialogState extends State<_CloseCashDialog> {
  final _repository = sl<CashRepository>();
  final _quantities = {for (final bill in _bills) bill: TextEditingController()};
  final _coins = TextEditingController();
  final _total = TextEditingController();
  final _left = TextEditingController();
  final _note = TextEditingController();

  _Step _step = _Step.count;
  bool _onlyTotal = false;
  bool _saving = false;
  bool _noteForced = false;
  String? _error;

  /// null mientras carga o si quien cierra no puede ver el esperado.
  double? _expected;
  bool _canSeeExpected = false;
  CashShift? _closed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repository.getShift(widget.shiftId);
    if (!mounted) return;
    switch (result) {
      case Right(:final value):
        setState(() {
          _canSeeExpected = value.canSeeExpected;
          _expected = value.expectedAmount;
        });
      case Left(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  void dispose() {
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    _coins.dispose();
    _total.dispose();
    _left.dispose();
    _note.dispose();
    super.dispose();
  }

  double _subtotal(int bill) => bill * (int.tryParse(_quantities[bill]!.text) ?? 0).toDouble();

  double get _billsTotal => _bills.fold<double>(0, (sum, bill) => sum + _subtotal(bill)) + (ThousandsFormat.parsePrice(_coins.text) ?? 0);

  double get _counted => _onlyTotal ? (ThousandsFormat.parsePrice(_total.text) ?? 0) : _billsTotal;

  double get _leftAmount => ThousandsFormat.parsePrice(_left.text) ?? 0;

  double? get _difference => _expected == null ? null : _counted - _expected!;

  bool get _noteRequired => _noteForced || (_difference != null && _difference!.abs() > widget.tolerance);

  List<Map<String, dynamic>>? get _denominations {
    if (_onlyTotal) return null;
    return [
      for (final bill in _bills)
        if ((int.tryParse(_quantities[bill]!.text) ?? 0) > 0) {'value': bill, 'quantity': int.parse(_quantities[bill]!.text)},
      if ((ThousandsFormat.parsePrice(_coins.text) ?? 0) > 0) {'label': 'Monedas y otros', 'amount': ThousandsFormat.parsePrice(_coins.text)},
    ];
  }

  void _toResult() {
    if (_onlyTotal && ThousandsFormat.parsePrice(_total.text) == null) {
      setState(() => _error = 'Poné el total contado.');
      return;
    }
    setState(() {
      _error = null;
      _step = _Step.result;
    });
  }

  void _handleError(DomainError failure) {
    if (failure.errorCode == CashErrors.closeNoteRequired) {
      final data = failure.errorData;
      setState(() {
        _noteForced = true;
        if (data?['expected'] is num) _expected = (data!['expected'] as num).toDouble();
        _error = 'Entró un movimiento mientras contabas. Revisá el resultado y contá qué pasó.';
      });
      return;
    }
    setState(() => _error = failure.message);
  }

  Future<void> _confirm() async {
    final note = _note.text.trim();
    if (_noteRequired && note.isEmpty) {
      setState(() => _error = 'Contá qué pasó con la diferencia.');
      return;
    }
    if (_leftAmount > _counted) {
      setState(() => _error = 'Lo que queda no puede superar lo contado.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await _repository.closeShift(
      widget.shiftId,
      countedAmount: _counted,
      leftAmount: _leftAmount,
      denominations: _denominations,
      note: note.isEmpty ? null : note,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Right(:final value):
        if (_canSeeExpected) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _closed = value;
            _step = _Step.done;
          });
        }
      case Left(:final failure):
        _handleError(failure);
    }
  }

  TextStyle? get _labelStyle => Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

  Widget _line(String label, String value, {Color? color, bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label),
        Text(value, style: TextStyle(color: color, fontWeight: strong ? FontWeight.w600 : FontWeight.w400)),
      ]),
    );
  }

  String _differenceLabel(double difference) => difference == 0 ? 'Cuadra' : (difference < 0 ? 'Faltante' : 'Sobrante');

  Widget _countStep() {
    final scheme = Theme.of(context).colorScheme;
    if (_onlyTotal) {
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Total contado', style: _labelStyle),
        const SizedBox(height: 6),
        PriceField(
          controller: _total,
          decoration: const InputDecoration(prefixText: '\$ ', border: OutlineInputBorder()),
        ),
        TextButton(onPressed: () => setState(() => _onlyTotal = false), child: const Text('Contar por billete')),
      ]);
    }

    Widget row(String label, Widget field, String subtotal) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: Text(label)),
            SizedBox(width: 96, child: field),
            SizedBox(width: 110, child: Text(subtotal, textAlign: TextAlign.right)),
          ]),
        );

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Expanded(child: Text('Billete', style: _labelStyle)),
          SizedBox(width: 96, child: Text('Cantidad', style: _labelStyle)),
          SizedBox(width: 110, child: Text('Subtotal', textAlign: TextAlign.right, style: _labelStyle)),
        ]),
      ),
      for (final bill in _bills)
        row(
          cashMoney(bill),
          TextField(
            key: ValueKey('cash.close.bill.$bill'),
            controller: _quantities[bill],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
          ),
          cashMoney(_subtotal(bill)),
        ),
      row(
        'Monedas y otros',
        PriceField(controller: _coins, isDense: true, decoration: const InputDecoration(prefixText: '\$ ', border: OutlineInputBorder())),
        cashMoney(ThousandsFormat.parsePrice(_coins.text) ?? 0),
      ),
      Divider(color: scheme.outlineVariant),
      _line('Total contado', cashMoney(_billsTotal), strong: true),
      TextButton(
        onPressed: () => setState(() => _onlyTotal = true),
        child: const Text('Ingresar solo el total'),
      ),
    ]);
  }

  Widget _resultStep() {
    final scheme = Theme.of(context).colorScheme;
    final difference = _difference;
    final withdrawn = _counted - _leftAmount;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_expected != null) _line('Esperado', cashMoney(_expected!)),
      _line('Contado', cashMoney(_counted)),
      if (difference != null)
        _line(_differenceLabel(difference), cashSigned(difference), color: cashAmountColor(scheme, difference), strong: true),
      if (_canSeeExpected) ...[
        const SizedBox(height: 10),
        Text(_noteRequired ? 'Qué pasó (obligatorio, supera la tolerancia de ${cashMoney(widget.tolerance)})' : 'Nota (opcional)', style: _labelStyle),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('cash.close.note'),
          controller: _note,
          maxLength: 500,
          maxLines: 2,
          decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ''),
        ),
      ],
      const SizedBox(height: 10),
      Text('Queda en la caja', style: _labelStyle),
      const SizedBox(height: 6),
      PriceField(
        controller: _left,
        decoration: const InputDecoration(prefixText: '\$ ', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 8),
      _line('Se retira', cashMoney(withdrawn < 0 ? 0 : withdrawn), strong: true),
    ]);
  }

  Widget _doneStep() {
    final scheme = Theme.of(context).colorScheme;
    final closed = _closed!;
    final difference = closed.difference ?? 0;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (closed.expectedAmount != null) _line('Esperado', cashMoney(closed.expectedAmount!)),
      if (closed.countedAmount != null) _line('Contado', cashMoney(closed.countedAmount!)),
      _line(_differenceLabel(difference), cashSigned(difference), color: cashAmountColor(scheme, difference), strong: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = switch (_step) {
      _Step.count => 'Cerrar ${widget.pointName}',
      _Step.result => 'Resultado del cierre',
      _Step.done => 'Caja cerrada',
    };

    return AlertDialog(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title),
        if (_step == _Step.count) Text('Contá el efectivo. El monto esperado aparece después.', style: _labelStyle),
      ]),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AnimatedBuilder(
              animation: Listenable.merge([_coins, _total, _left]),
              builder: (context, _) => switch (_step) {
                _Step.count => _countStep(),
                _Step.result => _resultStep(),
                _Step.done => _doneStep(),
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ]),
        ),
      ),
      actions: switch (_step) {
        _Step.count => [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: _toResult, child: const Text('Ver resultado')),
          ],
        _Step.result => [
            TextButton(onPressed: _saving ? null : () => setState(() => _step = _Step.count), child: const Text('Volver a contar')),
            FilledButton(onPressed: _saving ? null : _confirm, child: const Text('Confirmar cierre')),
          ],
        _Step.done => [FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Listo'))],
      },
    );
  }
}
