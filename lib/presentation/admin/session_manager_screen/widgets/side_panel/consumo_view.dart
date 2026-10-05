import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/config/service_locator.dart';
import '../../../../../core/utils/either.dart';
import '../../../../../domain/entities/extra.dart';
import '../../../../../domain/entities/payment/payment.dart';
import '../../../../../domain/entities/product.dart';
import '../../../../../domain/entities/session.dart';
import '../../../../../domain/repositories/product_repository.dart';
import '../../../../../domain/repositories/session_repository.dart';
import '../../../../../domain/usercases/session_user_cases.dart';
import '../../bloc/session_manager_bloc.dart';
import 'panel_common.dart';
import 'payment_view.dart';

/// "Agregar consumo": productos del club con cantidad, filtro por categoría
/// y la opción de cobrarlos en el momento.
class ConsumoView extends StatefulWidget {
  const ConsumoView({super.key, required this.session, required this.subtitle, required this.onBack});

  final Session session;
  final String subtitle;
  final VoidCallback onBack;

  @override
  State<ConsumoView> createState() => _ConsumoViewState();
}

class _ConsumoViewState extends State<ConsumoView> {
  final _useCases = SessionUserCases(sl<SessionRepository>());
  final _search = TextEditingController();

  List<Product>? _products;
  String? _category;
  final _qty = <int, int>{};
  bool _payNow = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    sl<ProductRepository>().getProducts().then((result) {
      if (!mounted) return;
      setState(() {
        _products = switch (result) {
          Right(:final value) => value,
          _ => const [],
        };
        if (result is! Right) _error = 'No se pudieron cargar los productos.';
      });
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> get _categories =>
      {for (final p in _products ?? const <Product>[]) if (p.categoryName != null) p.categoryName!}.toList()..sort();

  List<Product> get _visible {
    final query = _search.text.trim().toLowerCase();
    return (_products ?? const <Product>[])
        .where((p) => _category == null || p.categoryName == _category)
        .where((p) => query.isEmpty || p.name.toLowerCase().contains(query))
        .toList();
  }

  int get _count => _qty.values.fold(0, (a, b) => a + b);

  double get _total => (_products ?? const <Product>[]).fold(0, (t, p) => t + p.price * (_qty[p.productId] ?? 0));

  void _change(Product product, int delta) {
    setState(() {
      final next = ((_qty[product.productId] ?? 0) + delta).clamp(0, 99);
      if (next == 0) {
        _qty.remove(product.productId);
      } else {
        _qty[product.productId] = next;
      }
    });
  }

  Future<void> _add() async {
    final session = widget.session;
    final bloc = context.read<SessionManagerBloc>();
    setState(() {
      _saving = true;
      _error = null;
    });

    final method = _payNow ? (await PaymentMethods.load()).first : null;
    final added = <Extra>[];
    final chosen = (_products ?? const <Product>[]).where((p) => (_qty[p.productId] ?? 0) > 0).toList();

    for (final product in chosen) {
      final qty = _qty[product.productId]!;
      final amount = product.price * qty;
      final result = await _useCases.addExtraToSession(
        session.sessionId,
        Extra(
          productId: product.productId,
          name: qty > 1 ? '${product.name} x$qty' : product.name,
          amount: amount,
          payment: method == null ? null : Payment.fromExtra(amount: amount, method: method),
        ),
        paidExtra: _payNow,
      );
      if (result case Right(:final value)) added.add(value);
    }

    if (added.isNotEmpty) bloc.updateSessionInState(session.copyWith(extras: [...?session.extras, ...added]));
    if (added.length == chosen.length) {
      widget.onBack();
      return;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = 'Algunos consumos no se pudieron agregar. Probá de nuevo.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = _count;

    return PanelFrame(
      footer: Row(
        children: [
          PanelTextButton(label: 'Cancelar', onPressed: widget.onBack),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: PanelFilledButton(
              label: 'Agregar ${count == 1 ? '1 consumo' : '$count consumos'} · ${panelPrice(_total)}',
              loading: _saving,
              onPressed: count > 0 ? _add : null,
              ),
            ),
          ),
        ],
      ),
      children: [
        PanelSubHeader(title: 'Agregar consumo', subtitle: widget.subtitle, onBack: widget.onBack),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 14, color: scheme.onSurface),
          decoration: panelInputDecoration(
            context,
            hintText: 'Buscar producto',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(Icons.search, size: 18, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
        if (_categories.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PanelChoiceChip(
                label: 'Todos',
                height: 32,
                fontSize: 13,
                selected: _category == null,
                onTap: () => setState(() => _category = null),
              ),
              for (final c in _categories)
                PanelChoiceChip(
                  label: c,
                  height: 32,
                  fontSize: 13,
                  selected: _category == c,
                  onTap: () => setState(() => _category = c),
                ),
            ],
          ),
        if (_products == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _products!.isEmpty ? 'El club todavía no tiene productos cargados.' : 'No hay productos que coincidan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          )
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                for (final p in _visible)
                  _ProductRow(
                    product: p,
                    qty: _qty[p.productId] ?? 0,
                    onDec: () => _change(p, -1),
                    onInc: () => _change(p, 1),
                  ),
              ],
            ),
          ),
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => setState(() => _payNow = !_payNow),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: _payNow,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: (v) => setState(() => _payNow = v ?? false),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Cobrar ahora', style: TextStyle(fontSize: 14, color: scheme.onSurface)),
              ],
            ),
          ),
        ),
        if (_error != null) Text(_error!, style: TextStyle(fontSize: 12, color: scheme.error)),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.qty, required this.onDec, required this.onInc});

  final Product product;
  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget stepper(String symbol, String tooltip, VoidCallback onPressed) => SizedBox(
          width: 32,
          height: 32,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: scheme.onSurface,
              side: BorderSide(color: scheme.outlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Semantics(label: tooltip, child: Text(symbol, style: const TextStyle(fontSize: 16))),
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: qty > 0 ? scheme.surfaceContainerHighest : null,
        border: Border(bottom: BorderSide(color: scheme.surfaceContainerHighest)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: TextStyle(fontSize: 14, color: scheme.onSurface)),
                Text(panelPrice(product.price), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          stepper('−', 'Quitar ${product.name}', onDec),
          SizedBox(
            width: 32,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface),
            ),
          ),
          stepper('+', 'Sumar ${product.name}', onInc),
        ],
      ),
    );
  }
}
