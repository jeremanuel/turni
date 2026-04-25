import 'package:flutter/material.dart';
import '../../../../../../domain/entities/extra.dart';
import '../../../../../../domain/entities/payment/payment.dart';
import '../../../../../../domain/entities/payment/payment_method.dart';
import '../../../../../../domain/entities/product.dart';

typedef OnExtraAdded = void Function(Extra extra);

class AddExtraContainer extends StatefulWidget {
  const AddExtraContainer(
      {super.key, required this.onExtraAdded, required this.products});

  final OnExtraAdded onExtraAdded;
  final List<Product> products;

  @override
  State<AddExtraContainer> createState() => _AddExtraContainerState();
}

class _AddExtraContainerState extends State<AddExtraContainer> {
  final TextEditingController searchController = TextEditingController();
  bool paidExtra = false;
  int quantity = 1;
  Product? selectedConsumption;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool isValidExtra() {
    return selectedConsumption != null && quantity >= 1;
  }

  void createExtra() {
    if (!isValidExtra()) return;

    final selected = selectedConsumption!;
    final totalAmount = selected.price * quantity;
    final extraName =
        quantity > 1 ? "${selected.name} x$quantity" : selected.name;

    final extra = Extra(
      productId: selected.productId,
      name: extraName,
      amount: totalAmount,
      payment: paidExtra
          ? Payment.fromExtra(
              amount: totalAmount,
              method: PaymentMethod(paymentMethodId: 1, name: "Efectivo"))
          : null,
    );

    widget.onExtraAdded(extra);
  }

  List<Product> get _filteredConsumptions {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.products;

    return widget.products
        .where((item) => item.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selected = selectedConsumption;
    final total = selected == null ? 0.0 : selected.price * quantity;

    return Container(
      padding: const EdgeInsets.all(16),
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text("Nuevo consumo", style: textTheme.titleLarge),
          Text(
            "Elegi un consumo del catalogo del club",
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: "Buscar consumo",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(
            height: 220,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _filteredConsumptions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "No hay consumos que coincidan",
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _filteredConsumptions.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: colorScheme.outlineVariant),
                      itemBuilder: (context, index) {
                        final item = _filteredConsumptions[index];
                        final isSelected = selectedConsumption == item;

                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor: colorScheme.primaryContainer
                              .withValues(alpha: 0.35),
                          onTap: () {
                            setState(() {
                              selectedConsumption = item;
                            });
                          },
                          title: Text(item.name),
                          trailing: Text(
                            "\$${item.price.toStringAsFixed(0)}",
                            style: textTheme.titleSmall
                                ?.copyWith(color: colorScheme.primary),
                          ),
                        );
                      },
                    ),
            ),
          ),
          Row(
            children: [
              Text("Cantidad", style: textTheme.titleMedium),
              const Spacer(),
              IconButton(
                onPressed: quantity > 1
                    ? () {
                        setState(() {
                          quantity -= 1;
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Container(
                width: 44,
                alignment: Alignment.center,
                child: Text(
                  "$quantity",
                  style: textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    quantity += 1;
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total consumo", style: textTheme.titleSmall),
                Text(
                  "\$${total.toStringAsFixed(0)}",
                  style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: paidExtra,
            onChanged: (v) => setState(() => paidExtra = v!),
            subtitle: Text("Indica si el pago ha sido realizado",
                style: textTheme.labelMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
            title: Text("Pagado",
                style: textTheme.titleMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancelar")),
              TextButton(
                  onPressed: isValidExtra() ? createExtra : null,
                  child: const Text("Agregar")),
            ],
          ),
        ],
      ),
    );
  }
}
