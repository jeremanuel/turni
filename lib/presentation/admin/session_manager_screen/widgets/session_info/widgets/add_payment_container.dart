import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../domain/entities/extra.dart';
import '../../../../../../domain/entities/payment/payment.dart';
import '../../../../../../domain/entities/payment/payment_method.dart';

/// Tipos de pago disponibles
enum PaymentType { session, other }

/// Opciones de radio para el pago de turno
enum PaymentRadio { allTurn, remaining, half, onePerson, other }

typedef OnPaymentToSessionAdded = void Function(Payment payment);
typedef OnPaymentToExtrasAdded = void Function(List<Extra> extrasPagados);

/// Widget para agregar un pago o consumo extra
class AddPaymentContainer extends StatefulWidget {
  const AddPaymentContainer({
    super.key,
    required this.remainingPrice,
    required this.totalPrice,
    required this.onPaymentAdded,
    required this.consumos,
    required this.onConsumosPagados,
  });

  final double remainingPrice;
  final double totalPrice;
  final OnPaymentToSessionAdded onPaymentAdded;
  final List<Extra> consumos;
  final OnPaymentToExtrasAdded onConsumosPagados;

  @override
  State<AddPaymentContainer> createState() => _AddPaymentContainerState();
}

class _AddPaymentContainerState extends State<AddPaymentContainer> {
  PaymentType paymentType = PaymentType.session;
  PaymentRadio? selectedRadioValue;

  final FocusNode otroFocusNode = FocusNode();
  final TextEditingController otroController = TextEditingController();
  final TextEditingController consumoSearchController = TextEditingController();
  late final Map<PaymentRadio, Map> paymentValues;

  final List<Extra> selectedConsumos = [];
  final ExpansibleController controller = ExpansibleController();

  List<_TurnPaymentPreset> get _turnPaymentPresets {
    final presets = <_TurnPaymentPreset>[
      _TurnPaymentPreset(
        radio: PaymentRadio.allTurn,
        label: widget.remainingPrice == widget.totalPrice
            ? "Todo"
            : "Restante",
        amount: paymentValues[PaymentRadio.allTurn]?['amount'] ?? 0,
      ),
      _TurnPaymentPreset(
        radio: PaymentRadio.half,
        label: "Mitad",
        amount: paymentValues[PaymentRadio.half]?['amount'] ?? 0,
      ),
      _TurnPaymentPreset(
        radio: PaymentRadio.onePerson,
        label: "1 persona",
        amount: paymentValues[PaymentRadio.onePerson]?['amount'] ?? 0,
      ),
    ];

    return presets
        .where((preset) =>
            preset.radio != PaymentRadio.half ||
            widget.remainingPrice >
                (paymentValues[PaymentRadio.half]?['amount'] ?? 0))
        .where((preset) =>
            preset.radio != PaymentRadio.onePerson ||
            widget.remainingPrice >
                (paymentValues[PaymentRadio.onePerson]?['amount'] ?? 0))
        .toList();
  }

  @override
  void initState() {
    paymentValues = {
      PaymentRadio.allTurn: {
        "amount": widget.remainingPrice,
        "name": "Todo el turno"
      },
      PaymentRadio.remaining: {
        "amount": widget.remainingPrice,
        "name": "Restante"
      },
      PaymentRadio.half: {"amount": widget.totalPrice / 2, "name": "Mitad"},
      PaymentRadio.onePerson: {
        "amount": widget.totalPrice / 4,
        "name": "1 persona"
      },
    };

    // Si no hay saldo pendiente en turno pero hay consumos pendientes,
    // selecciona automáticamente la vista de consumos
    final pendingConsumos = widget.consumos.where((extra) => !extra.payed).toList();
    if (widget.remainingPrice == 0 && pendingConsumos.isNotEmpty) {
      paymentType = PaymentType.other;
    }

    super.initState();
  }

  @override
  void dispose() {
    otroFocusNode.dispose();
    otroController.dispose();
    consumoSearchController.dispose();
    controller.dispose();
    super.dispose();
  }

  List<Extra> get _pendingConsumos =>
      widget.consumos.where((extra) => !extra.payed).toList();

  List<Extra> get _filteredConsumos {
    final query = consumoSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return _pendingConsumos;

    return _pendingConsumos
        .where((extra) => extra.name.toLowerCase().contains(query))
        .toList();
  }

  bool isValidPayment() {
    if (selectedRadioValue == PaymentRadio.other) {
      final otherAmount = double.tryParse(otroController.text);
      if (otherAmount == null || otherAmount <= 0) return false;
    }

    if (selectedRadioValue == null && selectedConsumos.isEmpty) return false;

    return true;
  }

  void createPayment() {
    if (!isValidPayment()) return;

    if (selectedConsumos.isNotEmpty) widget.onConsumosPagados(selectedConsumos);

    if (selectedRadioValue != null) {
      final amountFromRadio = paymentValues[selectedRadioValue]?["amount"];
      final otherAmount = double.tryParse(otroController.text);

      final payment = Payment(
        clientId: -1,
        paymentMethod: PaymentMethod(paymentMethodId: 1, name: "Efectivo"),
        paymentDate: DateTime.now(),
        createdByAdmin: 1,
        amount: (amountFromRadio is num ? amountFromRadio.toDouble() : null) ??
            otherAmount ??
            0,
        isExtra: false,
      );

      widget.onPaymentAdded(payment);
    }
  }

  void _selectSessionPayment(PaymentRadio value) {
    setState(() {
      selectedRadioValue = value;
    });

    if (value == PaymentRadio.other) {
      Future.microtask(
          () => FocusScope.of(context).requestFocus(otroFocusNode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      width: 500,

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListView(
              shrinkWrap: true,
              children: [
                Text("Nuevo pago", style: textTheme.titleLarge),
                const SizedBox(height: 16),
                buildPaymentTypeSelector(colorScheme, textTheme),
                const SizedBox(height: 16),
                if (paymentType == PaymentType.session)
                  buildTurnTypeBody(colorScheme, textTheme),
                if (paymentType == PaymentType.other)
                  buildConsumosBody(colorScheme, textTheme),
              ],
            ),
          const SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              
              TextButton(
                  onPressed: isValidPayment() ? createPayment : null,
                  child: const Text("Pagar")),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildResumen(ColorScheme colorScheme) {
    if (selectedConsumos.isEmpty && selectedRadioValue == null) {
      controller.collapse();
      return const SizedBox();
    }

    return Expansible(
      controller: controller,
      headerBuilder: (context, animation) => InkWell(
        onTap: () {
          if (controller.isExpanded) {
            controller.collapse();
            return;
          }
          controller.expand();
        },
        child: Ink(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              borderRadius: !controller.isExpanded
                  ? BorderRadius.circular(8)
                  : BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8)),
              color: colorScheme.tertiaryContainer,
              border: !controller.isExpanded
                  ? Border.all(color: colorScheme.tertiary)
                  : Border(
                      top: BorderSide(color: colorScheme.tertiary),
                      right: BorderSide(color: colorScheme.tertiary),
                      left: BorderSide(color: colorScheme.tertiary))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                  text: TextSpan(children: [
                TextSpan(
                    text: "Resumen ",
                    style: TextStyle(color: colorScheme.onTertiaryContainer)),
                TextSpan(
                    text: "\$${_formatAmount(calculateAmount())}",
                    style: TextStyle(color: colorScheme.onTertiaryContainer)),
              ])),
              Badge(
                  label: Text(
                      "${selectedConsumos.length + (selectedRadioValue != null ? 1 : 0)}"),
                  child: Icon(Icons.expand_more,
                      color: colorScheme.onPrimaryContainer)),
            ],
          ),
        ),
      ),
      bodyBuilder: (context, animation) => Container(
        width: 300,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8)),
            color: colorScheme.tertiaryContainer,
            border: Border(
                bottom: BorderSide(color: colorScheme.tertiary),
                right: BorderSide(color: colorScheme.tertiary),
                left: BorderSide(color: colorScheme.tertiary))),
        child: Wrap(
          spacing: 4,
          children: [
            ...selectedConsumos.map((e) => InputChip(
                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                label: Text("\$ ${_formatAmount(e.amount)} ${e.name}"),
                onDeleted: () {
                  setState(() {
                    selectedConsumos.remove(e);
                  });
                })),
            if (selectedRadioValue != null &&
                selectedRadioValue != PaymentRadio.other)
              InputChip(
                label: Text(
                    "\$ ${_formatAmount((paymentValues[selectedRadioValue]?["amount"] ?? 0) as num)} ${paymentValues[selectedRadioValue]?["name"]}"),
                onDeleted: () {
                  setState(() {
                    selectedRadioValue = null;
                  });
                },
              ),
            if (selectedRadioValue == PaymentRadio.other)
              InputChip(
                label: Text(
                    "\$ ${_formatAmount(double.tryParse(otroController.text) ?? 0)} Otro monto"),
                onDeleted: () {
                  setState(() {
                    selectedRadioValue = null;
                    otroController.clear();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  double calculateAmount() {
    double total = 0;
    if (selectedRadioValue != null &&
        selectedRadioValue != PaymentRadio.other) {
      total += paymentValues[selectedRadioValue]?['amount'] ?? 0;
    }
    if (selectedRadioValue == PaymentRadio.other) {
      total += double.tryParse(otroController.text) ?? 0;
    }
    total += selectedConsumos.fold<double>(
        0, (sum, extra) => sum + (extra.amount as num).toDouble());
    return total;
  }

  Widget buildPaymentTypeSelector(
      ColorScheme colorScheme, TextTheme textTheme) {
    final double consumosRestantes = _pendingConsumos.fold<double>(
        0, (sum, extra) => sum + (extra.amount as num).toDouble());
    final bool consumosDisponibles = consumosRestantes > 0;
    return Row(
      spacing: 3,
      children: [
        Expanded(
          child: Opacity(
            opacity: widget.remainingPrice == 0 ? 0.5 : 1,
            child: Ink(
              decoration: BoxDecoration(
                color: paymentType == PaymentType.session
                    ? colorScheme.tertiaryContainer
                    : null,
                border: Border.all(
                    color: paymentType == PaymentType.session
                        ? colorScheme.tertiaryFixed
                        : colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: widget.remainingPrice == 0
                    ? null
                    : () {
                        paymentType = PaymentType.session;
                        setState(() {});
                      },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Radio(
                        fillColor: WidgetStateProperty.all(
                            paymentType == PaymentType.session
                                ? colorScheme.tertiary
                                : colorScheme.primary),
                        value: paymentType,
                        groupValue: PaymentType.session,
                        onChanged: widget.remainingPrice == 0
                            ? null
                            : (value) {
                                paymentType = PaymentType.session;
                                setState(() {});
                              },
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: "Turno \n", style: textTheme.titleMedium),
                            TextSpan(
                                text:
                                    "\$${_formatAmount(widget.remainingPrice)} \n",
                                style: textTheme.titleMedium?.copyWith(
                                    color: paymentType == PaymentType.session
                                        ? colorScheme.onTertiaryContainer
                                        : colorScheme.primary)),
                            TextSpan(
                                text: "Restante",
                                style: textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Opacity(
            opacity: !consumosDisponibles ? 0.5 : 1,
            child: Ink(
              height: 86,
              decoration: BoxDecoration(
                color: paymentType == PaymentType.other
                    ? colorScheme.tertiaryContainer
                    : null,
                border: Border.all(
                    color: paymentType == PaymentType.other
                        ? colorScheme.tertiaryFixed
                        : colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: !consumosDisponibles
                    ? null
                    : () {
                        paymentType = PaymentType.other;
                        setState(() {});
                      },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Radio(
                        fillColor: WidgetStateProperty.all(
                            paymentType == PaymentType.other
                                ? colorScheme.tertiary
                                : colorScheme.primary),
                        value: paymentType,
                        groupValue: PaymentType.other,
                        onChanged: !consumosDisponibles
                            ? null
                            : (value) {
                                paymentType = PaymentType.other;
                                setState(() {});
                              },
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: "Consumos \n",
                                style: textTheme.titleMedium),
                            TextSpan(
                                text:
                                    "\$${_formatAmount(consumosRestantes)} \n",
                                style: textTheme.titleMedium?.copyWith(
                                    color: paymentType == PaymentType.other
                                        ? colorScheme.onTertiaryContainer
                                        : colorScheme.primary)),
                            TextSpan(
                                text: "Restante",
                                style: textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTurnTypeBody(ColorScheme colorScheme, TextTheme textTheme) {
    final bool isCustomAmountSelected =
        selectedRadioValue == PaymentRadio.other;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            "Elegí un monto rápido o cargá uno manualmente.",
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              ..._turnPaymentPresets.map(
                (preset) => _buildAmountChoiceTile(
                  context,
                  label: preset.label,
                  amount: preset.amount,
                  selected: selectedRadioValue == preset.radio,
                  onSelected: () => _selectSessionPayment(preset.radio),
                ),
              ),
              _buildAmountChoiceTile(
                context,
                label: "Otro monto",
                amount: double.tryParse(otroController.text) ?? 0,
                selected: isCustomAmountSelected,
                icon: Icons.edit,
                onSelected: () => _selectSessionPayment(PaymentRadio.other),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isCustomAmountSelected
                ? TextField(
                    key: const ValueKey('custom-amount-field'),
                    focusNode: otroFocusNode,
                    controller: otroController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^[0-9]+(\.[0-9]*)?')),
                    ],
                    decoration: InputDecoration(
                      prefixText: "\$ ",
                      hintText: "Monto personalizado",
                      helperText: "Se usará este valor para el pago del turno",
                      border: const OutlineInputBorder(),
                    ),
                  )
                : Container(
                    key: const ValueKey('custom-amount-placeholder'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Text(
                      "Seleccioná 'Otro monto' para escribir un importe manual.",
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total a cobrar",
                    style: textTheme.titleSmall
                        ?.copyWith(color: colorScheme.onTertiaryContainer)),
                Text(
                  "\$${_formatAmount(selectedRadioValue == PaymentRadio.other ? (double.tryParse(otroController.text) ?? 0) : (paymentValues[selectedRadioValue]?['amount'] ?? 0))}",
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountChoiceTile(
    BuildContext context, {
    required String label,
    required num amount,
    required bool selected,
    required VoidCallback onSelected,
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final chipTextColor = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Material(
      color: selected ? colorScheme.tertiaryContainer : colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outlineVariant,
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: selected ? 1 : 0,
                  child: Icon(
                    Icons.check,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: chipTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "\$${_formatAmount(amount)}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: selected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Icon(
                    icon,
                    size: 18,
                    color: chipTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    
  }

  Widget buildConsumosBody(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        TextField(
          controller: consumoSearchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: "Buscar consumo",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _filteredConsumos.isEmpty
                ? Center(
                    child: Text(
                      "No hay consumos pendientes",
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredConsumos.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: colorScheme.outlineVariant),
                    itemBuilder: (context, index) {
                      final extra = _filteredConsumos[index];
                      return CheckboxListTile(
                        dense: true,
                        value: selectedConsumos.contains(extra),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            if (!selectedConsumos.contains(extra))
                              selectedConsumos.add(extra);
                          } else {
                            selectedConsumos.remove(extra);
                          }
                        }),
                        title: Text(extra.name, style: textTheme.titleMedium),
                        subtitle: Text("\$${_formatAmount(extra.amount)}",
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.primary)),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(num value) {
    final rounded = value.round().toString();
    return rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }
}

class _TurnPaymentPreset {
  const _TurnPaymentPreset({
    required this.radio,
    required this.label,
    required this.amount,
  });

  final PaymentRadio radio;
  final String label;
  final num amount;
}
